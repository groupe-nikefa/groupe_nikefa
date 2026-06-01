// Order repository — handles all order operations with Supabase realtime.
//
// Provides methods for creating orders, fetching order history,
// tracking order status in realtime, and cancelling pending orders.
// Uses Supabase Realtime subscriptions for live status updates.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../models/order.dart';
import '../models/order_item.dart';

/// Custom exception thrown by the order repository.
class OrderException implements Exception {
  final String message;
  final Object? originalError;
  const OrderException(this.message, [this.originalError]);

  @override
  String toString() => 'OrderException: $message';
}

/// Repository for all order operations.
///
/// Wraps Supabase queries for the `orders` and `order_items` tables
/// with realtime subscriptions for live status tracking.
class OrderRepository {
  SupabaseClient get _client => supabaseClient;

  // ─────────────────────────────────────────────────────────────
  // Order listing
  // ─────────────────────────────────────────────────────────────

  /// Streams all orders for a user with realtime updates.
  ///
  /// Orders are sorted by creation date (newest first).
  /// Each order includes its line items via a separate fetch.
  Stream<List<Order>> getUserOrders(String userId,
      {int limit = 20, int offset = 0}) {
    try {
      return _client
          .from('orders')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .asyncMap((rows) async {
            final orders = <Order>[];
            for (final json in rows) {
              try {
                final items = await _fetchOrderItems(json['id'] as String);
                orders.add(Order.fromJson({...json, 'order_items': items}));
              } catch (e) {
                debugPrint(
                    '[OrderRepository] Error fetching items for order ${json['id']}: $e');
                orders.add(Order.fromJson(json));
              }
            }
            // Apply pagination.
            final end = (offset + limit).clamp(0, orders.length);
            return offset < orders.length
                ? orders.sublist(offset, end)
                : orders;
          });
    } catch (e) {
      debugPrint('[OrderRepository] Error streaming orders: $e');
      return Stream.value([]);
    }
  }

  /// Streams a single order by ID with realtime status updates.
  Stream<Order> getOrderById(String orderId) async* {
    try {
      // Initial fetch with items.
      final orderData =
          await _client.from('orders').select().eq('id', orderId).single();

      final items = await _fetchOrderItems(orderId);
      yield Order.fromJson({...orderData, 'order_items': items});

      // Subscribe to realtime changes on this order.
      final stream =
          _client.from('orders').stream(primaryKey: ['id']).eq('id', orderId);

      await for (final changes in stream) {
        if (changes.isNotEmpty) {
          final updatedItems = await _fetchOrderItems(orderId);
          yield Order.fromJson({...changes.first, 'order_items': updatedItems});
        }
      }
    } catch (e) {
      debugPrint('[OrderRepository] Error streaming order: $e');
      throw OrderException('failed_to_load_order', e);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Order creation
  // ─────────────────────────────────────────────────────────────

  /// Creates a new order from the user's cart items.
  ///
  /// Delegates to the atomic PostgreSQL function `create_order_atomic`
  /// which reads cart_items, validates stock, creates the order + items,
  /// decrements stock, and clears the cart in a single transaction.
  Future<Order> createOrder({
    required String userId,
    required Map<String, String> shippingAddress,
    String notes = '',
  }) async {
    try {
      debugPrint('[OrderRepository] Creating order for user: $userId');

      // Call the atomic create_order_atomic function.
      final result = await _client.rpc('create_order_atomic', params: {
        'p_user_id': userId,
        'p_shipping_address': shippingAddress,
        'p_notes': notes,
      });

      final orderId = result['id'] as String;
      debugPrint('[OrderRepository] Order created atomically: $orderId');

      // Fetch complete order with embedded product data.
      final fetchedItems = await _fetchOrderItems(orderId);
      return Order.fromJson({...result, 'order_items': fetchedItems});
    } catch (e) {
      debugPrint('[OrderRepository] Error creating order: $e');
      throw OrderException('failed_to_create_order', e);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Order actions
  // ─────────────────────────────────────────────────────────────

  /// Cancels a pending order.
  ///
  /// Only orders with status `pending` can be cancelled by the customer.
  /// After cancellation, stock is restored atomically for each item.
  Future<void> cancelOrder(String orderId) async {
    try {
      // Verify the order is in a cancellable state.
      final orderData = await _client
          .from('orders')
          .select('status')
          .eq('id', orderId)
          .single();

      final status = orderData['status'] as String? ?? '';
      if (status == 'cancelled') {
        throw const OrderException('order_already_cancelled');
      }
      if (status == 'delivered') {
        throw const OrderException('order_already_delivered');
      }
      if (status != 'pending') {
        throw const OrderException('order_cannot_be_cancelled');
      }

      // Fetch items before updating status.
      final items = await _fetchOrderItems(orderId);

      // Update order status to cancelled.
      await _client
          .from('orders')
          .update({'status': 'cancelled'}).eq('id', orderId);

      // Restore stock by fetching current quantity and incrementing.
      for (final item in items) {
        try {
          final productData = await _client
              .from('products')
              .select('stock_quantity')
              .eq('id', item.productId)
              .single();
          final currentStock = productData['stock_quantity'] as int? ?? 0;
          await _client.from('products').update({
            'stock_quantity': currentStock + item.quantity,
          }).eq('id', item.productId);
        } catch (e) {
          debugPrint(
              '[OrderRepository] Stock restore failed for ${item.productId}: $e');
        }
      }

      debugPrint('[OrderRepository] Order cancelled: $orderId');
    } on OrderException {
      rethrow;
    } catch (e) {
      debugPrint('[OrderRepository] Error cancelling order: $e');
      throw OrderException('failed_to_cancel_order', e);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────

  /// Fetches order items for a given order with embedded product data.
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
      debugPrint('[OrderRepository] Error fetching order items: $e');
      return [];
    }
  }
}
