// OrderItem model — represents a single line item within an order.
//
// Maps to the `order_items` table in Supabase. Includes an embedded
// [Product] reference for display purposes.

import 'product.dart';

/// Represents a single line item within an order.
class OrderItem {
  /// Unique identifier from Supabase.
  final String id;

  /// ID of the parent order.
  final String orderId;

  /// ID of the product.
  final String productId;

  /// Quantity ordered.
  final int quantity;

  /// Unit price at the time of order (snapshotted, not dynamic).
  final double unitPrice;

  /// Selected variant at the time of order.
  final Map<String, dynamic>? variantSelection;

  /// Embedded product data for display (populated via JOIN).
  Product? product;

  /// Creates a new [OrderItem].
  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    this.variantSelection,
    this.product,
  });

  /// Creates an [OrderItem] from a Supabase JSON response.
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    Product? product;
    if (json['products'] is Map<String, dynamic>) {
      product = Product.fromJson(json['products'] as Map<String, dynamic>);
    }

    Map<String, dynamic>? variant;
    final vs = json['variant_selection'];
    if (vs is Map<String, dynamic>) {
      variant = vs;
    }

    return OrderItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      variantSelection: variant,
      product: product,
    );
  }

  /// Converts to JSON for Supabase operations.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'variant_selection': variantSelection,
    };
  }

  /// Returns the line total (unit_price * quantity).
  double get lineTotal => unitPrice * quantity;

  /// Returns a display-friendly variant label, or null.
  String? get variantLabel {
    if (variantSelection == null) return null;
    return variantSelection!['name'] as String?;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'OrderItem(id: $id, productId: $productId, qty: $quantity, price: $unitPrice)';
}
