// CartItem model — represents a single item in the user's shopping cart.
//
// Maps to the `cart_items` table in Supabase. Includes an embedded
// [Product] reference for display purposes. Used by both guest
// (Hive-backed) and authenticated (Supabase-backed) carts.

import 'product.dart';

/// Represents a single item in the shopping cart.
class CartItem {
  /// Unique identifier from Supabase (or local UUID for guest cart).
  final String id;

  /// ID of the user who owns this cart item.
  final String userId;

  /// ID of the product in this cart item.
  final String productId;

  /// Quantity of this product in the cart.
  int quantity;

  /// Selected variant (e.g., packaging option), stored as JSONB.
  Map<String, dynamic>? variantSelection;

  /// Timestamp when this cart item was last updated.
  DateTime updatedAt;

  /// Embedded product data for display (not stored in Supabase).
  ///
  /// Populated via a JOIN query or separate fetch. Null when only
  /// cart metadata is needed (e.g., badge count).
  Product? product;

  /// Creates a new [CartItem].
  CartItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    this.variantSelection,
    required this.updatedAt,
    this.product,
  });

  /// Creates a [CartItem] from a Supabase JSON response.
  ///
  /// Supports both flat and nested (product join) JSON structures.
  factory CartItem.fromJson(Map<String, dynamic> json) {
    Product? product;
    if (json['products'] is Map<String, dynamic>) {
      product = Product.fromJson(json['products'] as Map<String, dynamic>);
    }

    Map<String, dynamic>? variant;
    final vs = json['variant_selection'];
    if (vs is Map<String, dynamic>) {
      variant = vs;
    }

    return CartItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      productId: json['product_id'] as String,
      quantity: json['quantity'] as int,
      variantSelection: variant,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      product: product,
    );
  }

  /// Converts this cart item to a JSON map for Supabase operations.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'quantity': quantity,
      'variant_selection': variantSelection,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Returns a copy of this cart item with modified fields.
  CartItem copyWith({
    String? id,
    String? userId,
    String? productId,
    int? quantity,
    Map<String, dynamic>? variantSelection,
    DateTime? updatedAt,
    Product? product,
  }) {
    return CartItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      variantSelection: variantSelection ?? this.variantSelection,
      updatedAt: updatedAt ?? this.updatedAt,
      product: product ?? this.product,
    );
  }

  /// Returns the effective unit price for this cart item.
  ///
  /// Checks variant bulk pricing first, then variant base price,
  /// then falls back to product base price.
  double get effectivePrice {
    if (product == null) return 0.0;

    if (variantSelection != null && product!.variants.isNotEmpty) {
      final matchingVariant = product!.variants.where(
        (v) => v.id == variantSelection!['variant_id'],
      );
      if (matchingVariant.isNotEmpty) {
        return matchingVariant.first.getPriceForQuantity(quantity);
      }
    }

    if (product!.variants.isNotEmpty) {
      return product!.variants.first.getPriceForQuantity(quantity);
    }

    return product!.basePrice;
  }

  /// Returns the line total (price * quantity).
  double get lineTotal => effectivePrice * quantity;

  /// Returns `true` if the product is still in stock at this quantity.
  bool get isAvailable {
    if (product == null) return true;
    return product!.hasStock && quantity <= product!.stock;
  }

  /// Returns a display-friendly variant label, or null if no variant.
  String? get variantLabel {
    if (variantSelection == null) return null;
    return variantSelection!['name'] as String?;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          productId == other.productId;

  @override
  int get hashCode => Object.hash(id, productId);

  @override
  String toString() =>
      'CartItem(id: $id, productId: $productId, qty: $quantity)';
}
