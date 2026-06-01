// Order providers — Riverpod providers for order state management.
//
// Connects the OrderRepository to the UI layer. Provides streams
// for order history, single order detail, and order status tracking.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../core/providers/auth_provider.dart';

// ──────────────────────────────────────────────────────────────
// Repository provider
// ──────────────────────────────────────────────────────────────

/// Provides a singleton [OrderRepository] instance.
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

// ──────────────────────────────────────────────────────────────
// Order history
// ──────────────────────────────────────────────────────────────

/// Streams the current user's orders with realtime updates.
final userOrdersProvider = StreamProvider<List<Order>>((ref) {
  final repository = ref.watch(orderRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return repository.getUserOrders(user.id);
});

// ──────────────────────────────────────────────────────────────
// Single order detail
// ──────────────────────────────────────────────────────────────

/// Streams a single order by ID with realtime status updates.
final orderByIdProvider = StreamProvider.family<Order, String>((ref, orderId) {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getOrderById(orderId);
});

// ──────────────────────────────────────────────────────────────
// Order status filter
// ──────────────────────────────────────────────────────────────

/// The currently selected order status filter (null means "all").
final orderStatusFilterProvider = StateProvider<OrderStatus?>((ref) => null);

/// Filtered orders based on the selected status.
final filteredOrdersProvider = Provider<List<Order>>((ref) {
  final orders = ref.watch(userOrdersProvider).valueOrNull ?? [];
  final filter = ref.watch(orderStatusFilterProvider);
  if (filter == null) return orders;
  return orders.where((o) => o.status == filter).toList();
});

// ──────────────────────────────────────────────────────────────
// Order creation notifier
// ──────────────────────────────────────────────────────────────

/// State for order creation flow.
class CreateOrderState {
  final bool isLoading;
  final String? error;
  final Order? createdOrder;

  const CreateOrderState(
      {this.isLoading = false, this.error, this.createdOrder});

  CreateOrderState copyWith(
      {bool? isLoading, String? error, Order? createdOrder}) {
    return CreateOrderState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      createdOrder: createdOrder ?? this.createdOrder,
    );
  }
}

/// Notifier for order creation and cancellation with loading/error state.
class CreateOrderNotifier extends Notifier<CreateOrderState> {
  OrderRepository get _orderRepo => ref.watch(orderRepositoryProvider);

  @override
  CreateOrderState build() => const CreateOrderState();

  /// Creates an order from the user's cart items.
  Future<bool> createOrder({
    required Map<String, String> shippingAddress,
    String notes = '',
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        state = state.copyWith(isLoading: false, error: 'not_authenticated');
        return false;
      }

      final order = await _orderRepo.createOrder(
        userId: user.id,
        shippingAddress: shippingAddress,
        notes: notes,
      );

      state = CreateOrderState(createdOrder: order);
      return true;
    } catch (e) {
      final message = e is OrderException ? e.message : 'something_went_wrong';
      state = state.copyWith(isLoading: false, error: message);
      return false;
    }
  }

  /// Cancels a pending order.
  Future<bool> cancelOrder(String orderId) async {
    state = state.copyWith(isLoading: true);
    try {
      await _orderRepo.cancelOrder(orderId);
      state = const CreateOrderState();
      return true;
    } catch (e) {
      final message = e is OrderException ? e.message : 'something_went_wrong';
      state = state.copyWith(isLoading: false, error: message);
      return false;
    }
  }

  void reset() {
    state = const CreateOrderState();
  }
}

/// Provider for the create order notifier.
/// Also handles order cancellation via [CreateOrderNotifier.cancelOrder].
final createOrderProvider =
    NotifierProvider<CreateOrderNotifier, CreateOrderState>(
  CreateOrderNotifier.new,
);
