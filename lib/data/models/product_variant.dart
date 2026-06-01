// Product variant model — represents packaging/size options for a product.
//
// Maps to the `product_variants` table in Supabase. Each variant has
// its own price, stock, and bulk pricing tiers. Includes Hive adapter
// for offline caching.

/// Represents a bulk pricing tier (quantity range with unit price).
class BulkPricingTier {
  /// Minimum quantity for this tier (inclusive).
  final int minQty;

  /// Maximum quantity for this tier (inclusive), or null for unlimited.
  final int? maxQty;

  /// Unit price for this tier.
  final double unitPrice;

  /// Creates a new [BulkPricingTier].
  const BulkPricingTier({
    required this.minQty,
    this.maxQty,
    required this.unitPrice,
  });

  /// Creates a tier from JSON.
  factory BulkPricingTier.fromJson(Map<String, dynamic> json) {
    return BulkPricingTier(
      minQty: json['min_qty'] as int? ?? 0,
      maxQty: json['max_qty'] as int?,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() {
    return {
      'min_qty': minQty,
      'max_qty': maxQty,
      'unit_price': unitPrice,
    };
  }

  /// Returns `true` if the given quantity falls within this tier.
  bool appliesToQuantity(int quantity) {
    if (quantity < minQty) return false;
    if (maxQty != null && quantity > maxQty!) return false;
    return true;
  }

  /// Creates a copy with modified fields.
  BulkPricingTier copyWith({
    int? minQty,
    int? maxQty,
    double? unitPrice,
  }) {
    return BulkPricingTier(
      minQty: minQty ?? this.minQty,
      maxQty: maxQty ?? this.maxQty,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  @override
  String toString() =>
      'BulkPricingTier(min: $minQty, max: $maxQty, price: $unitPrice)';
}

/// Represents a product variant (e.g., different packaging quantities).
///
/// Each variant has its own price, stock level, and bulk pricing tiers.
class ProductVariant {
  /// Unique identifier from Supabase.
  final String id;

  /// ID of the parent product.
  final String productId;

  /// Variant name/label (e.g., "Box of 10", "Box of 50").
  final String name;

  /// Packaging quantity (e.g., 10, 50, 100).
  final int quantity;

  /// Base unit price for this variant.
  final double price;

  /// Available stock for this variant.
  final int stock;

  /// Bulk pricing tiers for this variant.
  final List<BulkPricingTier> bulkPricing;

  /// Whether this variant is active/available for purchase.
  final bool isActive;

  /// Creates a new [ProductVariant].
  const ProductVariant({
    required this.id,
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.stock,
    this.bulkPricing = const [],
    this.isActive = true,
  });

  /// Creates a [ProductVariant] from Supabase JSON.
  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    // Parse bulk pricing from JSONB column.
    List<BulkPricingTier> tiers = [];
    final bulkPricingData = json['bulk_pricing'];
    if (bulkPricingData is List) {
      tiers = bulkPricingData
          .map((t) => BulkPricingTier.fromJson(t as Map<String, dynamic>))
          .toList();
    } else if (bulkPricingData is Map<String, dynamic>) {
      // Handle case where it's a single object instead of array.
      tiers = [BulkPricingTier.fromJson(bulkPricingData)];
    }

    return ProductVariant(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      stock: json['stock'] as int? ?? 0,
      bulkPricing: tiers,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Converts to JSON for Supabase operations.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'quantity': quantity,
      'price': price,
      'stock': stock,
      'bulk_pricing': bulkPricing.map((t) => t.toJson()).toList(),
      'is_active': isActive,
    };
  }

  /// Returns the effective unit price for a given quantity.
  ///
  /// Checks bulk pricing tiers first, falls back to base price.
  double getPriceForQuantity(int quantity) {
    for (final tier in bulkPricing) {
      if (tier.appliesToQuantity(quantity)) {
        return tier.unitPrice;
      }
    }
    return price;
  }

  /// Returns `true` if this variant is in stock.
  bool get isInStock => stock > 0 && isActive;

  /// Creates a copy with modified fields.
  ProductVariant copyWith({
    String? id,
    String? productId,
    String? name,
    int? quantity,
    double? price,
    int? stock,
    List<BulkPricingTier>? bulkPricing,
    bool? isActive,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      bulkPricing: bulkPricing ?? this.bulkPricing,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() =>
      'ProductVariant(id: $id, name: $name, qty: $quantity, price: $price)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductVariant &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
