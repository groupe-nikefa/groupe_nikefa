// Order model — represents a customer order with items and status tracking.
//
// Maps to the `orders` table in Supabase. Supports the full order
// lifecycle: pending → confirmed → shipped → delivered (or cancelled).

import 'order_item.dart';

/// Order status enum matching the Supabase `order_status` type.
enum OrderStatus {
  pending,
  confirmed,
  shipped,
  delivered,
  cancelled;

  /// Creates an [OrderStatus] from a database string.
  static OrderStatus fromString(String value) {
    return switch (value.toLowerCase()) {
      'pending' => OrderStatus.pending,
      'confirmed' => OrderStatus.confirmed,
      'shipped' => OrderStatus.shipped,
      'delivered' => OrderStatus.delivered,
      'cancelled' => OrderStatus.cancelled,
      _ => OrderStatus.pending,
    };
  }

  /// Returns the database string for this status.
  String get dbValue => name;

  /// Returns `true` if this order can be cancelled by the customer.
  bool get canCancel => this == OrderStatus.pending;

  /// Returns `true` if this order has reached a terminal state.
  bool get isTerminal =>
      this == OrderStatus.delivered || this == OrderStatus.cancelled;

  /// Returns the next status in the lifecycle, or null if terminal.
  OrderStatus? get next => switch (this) {
        OrderStatus.pending => OrderStatus.confirmed,
        OrderStatus.confirmed => OrderStatus.shipped,
        OrderStatus.shipped => OrderStatus.delivered,
        _ => null,
      };
}

/// Payment method enum matching the Supabase `payment_method` type.
/// MVP supports COD only.
enum PaymentMethod {
  cod;

  static PaymentMethod fromString(String value) {
    return switch (value.toLowerCase()) {
      'cod' => PaymentMethod.cod,
      _ => PaymentMethod.cod,
    };
  }

  String get dbValue => name;
}

/// Represents a complete customer order.
class Order {
  /// Unique identifier from Supabase.
  final String id;

  /// ID of the user who placed this order.
  final String userId;

  /// Current order status.
  final OrderStatus status;

  /// Total order amount.
  final double totalAmount;

  /// Payment method (COD only for MVP).
  final PaymentMethod paymentMethod;

  /// Shipping address stored as a structured map.
  final Map<String, String> shippingAddress;

  /// List of line items in this order.
  final List<OrderItem> items;

  /// Timestamp when the order was created.
  final DateTime createdAt;

  /// Timestamp when the order was last updated.
  final DateTime updatedAt;

  /// Creates a new [Order].
  Order({
    required this.id,
    required this.userId,
    required this.status,
    required this.totalAmount,
    this.paymentMethod = PaymentMethod.cod,
    required this.shippingAddress,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates an [Order] from a Supabase JSON response.
  ///
  /// Supports both flat order data and nested order_items via JOIN.
  factory Order.fromJson(Map<String, dynamic> json) {
    List<OrderItem> orderItems = [];
    final itemsData = json['order_items'];
    if (itemsData is List) {
      orderItems = itemsData
          .whereType<Map<String, dynamic>>()
          .map((item) => OrderItem.fromJson(item))
          .toList();
    }

    Map<String, String> address = {};
    final addr = json['shipping_address'];
    if (addr is Map<String, dynamic>) {
      address = addr.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    }

    return Order(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      status: OrderStatus.fromString(json['status'] as String? ?? 'pending'),
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: PaymentMethod.fromString(
        json['payment_method'] as String? ?? 'cod',
      ),
      shippingAddress: address,
      items: orderItems,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  /// Converts this order to a JSON map for Supabase operations.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'status': status.dbValue,
      'total_amount': totalAmount,
      'payment_method': paymentMethod.dbValue,
      'shipping_address': shippingAddress,
    };
  }

  /// Returns a copy of this order with modified fields.
  Order copyWith({
    String? id,
    String? userId,
    OrderStatus? status,
    double? totalAmount,
    PaymentMethod? paymentMethod,
    Map<String, String>? shippingAddress,
    List<OrderItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Returns the number of items in this order.
  int get itemCount => items.length;

  /// Returns the shipping address as a formatted multi-line string.
  String get formattedAddress {
    final parts = [
      shippingAddress['name'],
      shippingAddress['address'],
      if (shippingAddress['building'] != null &&
          shippingAddress['building']!.isNotEmpty)
        shippingAddress['building'],
      shippingAddress['city'],
      shippingAddress['region'],
      shippingAddress['phone'],
    ].where((p) => p != null && p.isNotEmpty);
    return parts.join('\n');
  }

  /// Short display ID for the order (first 8 chars of UUID).
  String get shortId => id.substring(0, 8).toUpperCase();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Order && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Order(id: $shortId, status: $status, total: $totalAmount, items: ${items.length})';
}
