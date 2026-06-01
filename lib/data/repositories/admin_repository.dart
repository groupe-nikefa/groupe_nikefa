import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/services/storage_service.dart';
import '../../data/models/category.dart' as models;
import '../../data/models/order.dart';
import '../../data/models/order_item.dart';
import '../../data/models/product.dart';

class AdminRepository {
  SupabaseClient get _client => supabaseClient;
  final _storage = StorageService();

  Future<Product> createProduct({
    required Map<String, dynamic> data,
    List<File>? imageFiles,
    List<String>? imageUrlList,
  }) async {
    List<String> imageUrls = [];
    if (imageFiles != null && imageFiles.isNotEmpty) {
      imageUrls = await _storage.uploadProductImages(imageFiles);
    }
    if (imageUrlList != null && imageUrlList.isNotEmpty) {
      imageUrls.addAll(imageUrlList);
    }
    if (imageUrls.isNotEmpty) {
      data['images'] = imageUrls;
    }

    final response =
        await _client.from('products').insert(data).select().single();

    return Product.fromJson(response);
  }

  Future<Product> updateProduct({
    required String id,
    required Map<String, dynamic> updates,
    List<File>? newImages,
    List<String>? removedImageUrls,
    List<String>? addedImageUrls,
  }) async {
    if (removedImageUrls != null && removedImageUrls.isNotEmpty) {
      await _storage.deleteImages(removedImageUrls);
    }

    List<String> newUrls = [];
    if (newImages != null && newImages.isNotEmpty) {
      newUrls = await _storage.uploadProductImages(newImages);
    }

    if (newUrls.isNotEmpty ||
        removedImageUrls != null ||
        (addedImageUrls != null && addedImageUrls.isNotEmpty)) {
      final current =
          await _client.from('products').select('images').eq('id', id).single();

      List<dynamic> existing = List.from(current['images'] ?? []);
      if (removedImageUrls != null) {
        existing.removeWhere((u) => removedImageUrls.contains(u));
      }
      existing.addAll(newUrls);
      if (addedImageUrls != null) {
        existing.addAll(addedImageUrls);
      }
      updates['images'] = existing;
    }

    final response = await _client
        .from('products')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return Product.fromJson(response);
  }

  Future<void> deleteProduct(String id) async {
    final product =
        await _client.from('products').select('images').eq('id', id).single();

    final images = List<String>.from(product['images'] ?? []);
    if (images.isNotEmpty) {
      await _storage.deleteImages(images);
    }

    await _client.from('products').delete().eq('id', id);
  }

  Future<models.Category> createCategory(models.Category category) async {
    final json = category.toJson();
    json.remove('id');
    final response =
        await _client.from('categories').insert(json).select().single();

    return models.Category.fromJson(response);
  }

  Future<models.Category> updateCategory({
    required String id,
    required Map<String, dynamic> updates,
  }) async {
    await _client.from('categories').update(updates).eq('id', id);
    final response =
        await _client.from('categories').select().eq('id', id).single();
    return models.Category.fromJson(response);
  }

  Future<void> deleteCategory(String id, {String? reassignToId}) async {
    if (reassignToId != null) {
      await _client
          .from('products')
          .update({'category_id': reassignToId}).eq('category_id', id);
    } else {
      final products =
          await _client.from('products').select('id').eq('category_id', id);

      if (products.isNotEmpty) {
        throw AdminException(
          'cannot_delete_category_with_products',
          'Category has ${products.length} associated products. Reassign them before deleting.',
        );
      }
    }

    await _client.from('categories').delete().eq('id', id);
  }

  Future<Order> updateOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
  }) async {
    final orderData = await _client
        .from('orders')
        .select('status')
        .eq('id', orderId)
        .single();

    final currentStatus = orderData['status'] as String;
    _validateStatusTransition(currentStatus, newStatus.dbValue);

    final response = await _client
        .from('orders')
        .update({'status': newStatus.dbValue})
        .eq('id', orderId)
        .select()
        .single();

    final items = await _fetchOrderItems(orderId);
    return Order.fromJson({...response, 'order_items': items});
  }

  Future<Map<String, dynamic>> getAdminStats() async {
    final productCount = await _client.from('products').select('id');

    final pendingOrders = await _client
        .from('orders')
        .select('total_amount')
        .eq('status', 'pending');

    final allOrders = await _client
        .from('orders')
        .select('total_amount')
        .neq('status', 'cancelled');

    final totalOrders = await _client.from('orders').select('id');

    final lowStock = await _client
        .from('products')
        .select('id')
        .lte('stock_quantity', 10)
        .gt('stock_quantity', 0);

    final customerCount = await _client.from('profiles').select('id');

    final totalRevenue = allOrders.fold<double>(
      0,
      (sum, row) => sum + ((row['total_amount'] as num?)?.toDouble() ?? 0),
    );

    return {
      'product_count': productCount.length,
      'pending_order_count': pendingOrders.length,
      'total_order_count': totalOrders.length,
      'total_revenue': totalRevenue,
      'low_stock_count': lowStock.length,
      'customer_count': customerCount.length,
    };
  }

  Stream<List<Order>> streamAllOrders() {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .asyncMap((rows) async {
          final orders = <Order>[];
          for (final json in rows) {
            try {
              final items = await _fetchOrderItems(json['id'] as String);
              orders.add(Order.fromJson({...json, 'order_items': items}));
            } catch (e) {
              debugPrint('[AdminRepository] Error fetching order items: $e');
              orders.add(Order.fromJson(json));
            }
          }
          return orders;
        });
  }

  Stream<List<Product>> streamAllProducts() {
    return _client
        .from('products')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map((json) => Product.fromJson(json)).toList());
  }

  Stream<List<models.Category>> streamAllCategories() {
    return _client
        .from('categories')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) =>
            rows.map((json) => models.Category.fromJson(json)).toList());
  }

  void _validateStatusTransition(String current, String next) {
    const transitions = {
      'pending': ['confirmed', 'cancelled'],
      'confirmed': ['shipped', 'cancelled'],
      'shipped': ['delivered'],
      'delivered': <String>[],
      'cancelled': <String>[],
    };

    final allowed = transitions[current] ?? [];
    if (!allowed.contains(next)) {
      throw AdminException('invalid_status_transition',
          'Cannot transition from $current to $next');
    }
  }

  Future<Order?> fetchOrderById(String orderId) async {
    try {
      final orderData =
          await _client.from('orders').select().eq('id', orderId).single();

      final items = await _fetchOrderItems(orderId);
      return Order.fromJson({...orderData, 'order_items': items});
    } catch (e) {
      debugPrint('[AdminRepository] Error fetching order: $e');
      return null;
    }
  }

  Future<List<OrderItem>> _fetchOrderItems(String orderId) async {
    try {
      final response = await _client
          .from('order_items')
          .select('*, products(*)')
          .eq('order_id', orderId);

      return response
          .whereType<Map<String, dynamic>>()
          .map((json) => OrderItem.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('[AdminRepository] Error fetching order items: $e');
      return [];
    }
  }
}

class AdminException implements Exception {
  final String code;
  final String message;
  const AdminException(this.code, [this.message = '']);

  @override
  String toString() => 'AdminException($code): $message';
}
