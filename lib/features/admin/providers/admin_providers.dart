import 'dart:io' show File;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../../../data/models/category.dart' as models;
import '../../../data/models/order.dart';
import '../../../data/models/product.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/admin_repository.dart';

final _client = supabaseClient;

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

class AdminStats {
  final int productCount;
  final int pendingOrderCount;
  final double totalRevenue;
  final int customerCount;
  final int totalOrderCount;
  final int lowStockCount;

  const AdminStats({
    this.productCount = 0,
    this.pendingOrderCount = 0,
    this.totalRevenue = 0,
    this.customerCount = 0,
    this.totalOrderCount = 0,
    this.lowStockCount = 0,
  });
}

final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  final stats = await repo.getAdminStats();
  return AdminStats(
    productCount: stats['product_count'] as int,
    pendingOrderCount: stats['pending_order_count'] as int,
    totalRevenue: (stats['total_revenue'] as num).toDouble(),
    customerCount: stats['customer_count'] as int,
    totalOrderCount: stats['total_order_count'] as int,
    lowStockCount: stats['low_stock_count'] as int,
  );
});

final adminProductsProvider = StreamProvider<List<Product>>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.streamAllProducts();
});

final adminCategoriesProvider = StreamProvider<List<models.Category>>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.streamAllCategories();
});

final adminOrdersProvider = StreamProvider<List<Order>>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.streamAllOrders();
});

final adminCustomersProvider = StreamProvider<List<UserProfile>>((ref) {
  return _client
      .from('profiles')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((rows) => rows.map((json) => UserProfile.fromJson(json)).toList());
});

class ProductFormState {
  final bool isSaving;
  final String? error;
  final bool isSuccess;

  const ProductFormState(
      {this.isSaving = false, this.error, this.isSuccess = false});

  ProductFormState copyWith({bool? isSaving, String? error, bool? isSuccess}) {
    return ProductFormState(
      isSaving: isSaving ?? this.isSaving,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class ProductFormNotifier extends Notifier<ProductFormState> {
  AdminRepository get _repo => ref.watch(adminRepositoryProvider);

  @override
  ProductFormState build() => const ProductFormState();

  Future<bool> createProduct(
      {required Map<String, dynamic> data,
      List<File>? imageFiles,
      List<String>? imageUrlList}) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _repo.createProduct(
          data: data, imageFiles: imageFiles, imageUrlList: imageUrlList);
      state = state.copyWith(isSaving: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<bool> updateProduct({
    required String id,
    required Map<String, dynamic> updates,
    List<File>? newImages,
    List<String>? removedImageUrls,
    List<String>? addedImageUrls,
  }) async {
    state = state.copyWith(isSaving: true, error: null);
    try {
      await _repo.updateProduct(
          id: id,
          updates: updates,
          newImages: newImages,
          removedImageUrls: removedImageUrls,
          addedImageUrls: addedImageUrls);
      state = state.copyWith(isSaving: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }
}

final productFormProvider =
    NotifierProvider<ProductFormNotifier, ProductFormState>(
  ProductFormNotifier.new,
);

class OrderStatusNotifier extends Notifier<AsyncValue<void>> {
  AdminRepository get _repo => ref.watch(adminRepositoryProvider);

  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> updateStatus(String orderId, OrderStatus newStatus) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateOrderStatus(orderId: orderId, newStatus: newStatus);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final orderStatusProvider =
    NotifierProvider<OrderStatusNotifier, AsyncValue<void>>(
  OrderStatusNotifier.new,
);

class CategoryFormNotifier extends Notifier<AsyncValue<void>> {
  AdminRepository get _repo => ref.watch(adminRepositoryProvider);

  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<bool> createCategory(models.Category category) async {
    state = const AsyncValue.loading();
    try {
      await _repo.createCategory(category);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateCategory(String id, Map<String, dynamic> updates) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateCategory(id: id, updates: updates);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteCategory(String id, {String? reassignToId}) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteCategory(id, reassignToId: reassignToId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final categoryFormProvider =
    NotifierProvider<CategoryFormNotifier, AsyncValue<void>>(
  CategoryFormNotifier.new,
);
