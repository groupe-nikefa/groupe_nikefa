// Product model — represents a medical supply product with multilingual support.
//
// Maps to the `products` table in Supabase. Includes images, medical
// classifications, variants, and localization. Hive adapter for offline caching.

import 'product_variant.dart';

/// Represents a medical supply product with full details.
class Product {
  /// Unique identifier from Supabase.
  final String id;

  /// Stock Keeping Unit — unique product code.
  final String sku;

  /// Product name in French.
  final String nameFr;

  /// Product name in Arabic.
  final String nameAr;

  /// Product description in French.
  final String? descriptionFr;

  /// Product description in Arabic.
  final String? descriptionAr;

  /// ID of the parent category.
  final String categoryId;

  /// Base unit price (used if no variants exist).
  final double basePrice;

  /// Available stock quantity (used if no variants exist).
  final int stock;

  /// Whether this product is active/visible to customers.
  final bool isActive;

  /// List of medical classifications for this product.
  final List<String> medicalClassifications;

  /// List of image URLs from Supabase Storage.
  final List<String> images;

  /// Product variants (packaging options, sizes, etc.).
  /// Empty list means the product has no variants (uses base price/stock).
  final List<ProductVariant> variants;

  /// Whether this product is featured on the home page.
  final bool isFeatured;

  /// Timestamp when the product was created.
  final DateTime? createdAt;

  /// Timestamp when the product was last updated.
  final DateTime? updatedAt;

  /// Creates a new [Product] instance.
  const Product({
    required this.id,
    required this.sku,
    required this.nameFr,
    required this.nameAr,
    this.descriptionFr,
    this.descriptionAr,
    required this.categoryId,
    required this.basePrice,
    required this.stock,
    this.isActive = true,
    this.medicalClassifications = const [],
    this.images = const [],
    this.variants = const [],
    this.isFeatured = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Creates a [Product] from a Supabase JSON response.
  factory Product.fromJson(Map<String, dynamic> json) {
    // Parse medical classifications.
    List<String> classifications = [];
    final classData = json['medical_classification'];
    if (classData is List) {
      classifications = classData.map((e) => e.toString()).toList();
    } else if (classData is String && classData.isNotEmpty) {
      classifications = [classData];
    }

    // Parse images array.
    List<String> imageUrls = [];
    final imagesData = json['images'];
    if (imagesData is List) {
      imageUrls = imagesData.map((e) => e.toString()).toList();
    }

    // Parse variants.
    List<ProductVariant> productVariants = [];
    final variantsData = json['variants'];
    if (variantsData is List) {
      productVariants = variantsData
          .whereType<Map<String, dynamic>>()
          .map((v) => ProductVariant.fromJson(v))
          .toList();
    }

    return Product(
      id: json['id'] as String,
      sku: json['sku'] as String? ?? '',
      nameFr: json['name_fr'] as String? ?? '',
      nameAr: json['name_ar'] as String? ?? '',
      descriptionFr: json['description_fr'] as String?,
      descriptionAr: json['description_ar'] as String?,
      categoryId: json['category_id'] as String? ?? '',
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 0.0,
      stock: json['stock_quantity'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      medicalClassifications: classifications,
      images: imageUrls,
      variants: productVariants,
      isFeatured: json['is_featured'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Converts this product to a JSON map for Supabase operations.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sku': sku,
      'name_fr': nameFr,
      'name_ar': nameAr,
      'description_fr': descriptionFr,
      'description_ar': descriptionAr,
      'category_id': categoryId,
      'base_price': basePrice,
      'stock_quantity': stock,
      'is_active': isActive,
      'medical_classification': medicalClassifications,
      'images': images,
      'variants': variants.map((v) => v.toJson()).toList(),
      'is_featured': isFeatured,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Returns a copy of this product with modified fields.
  Product copyWith({
    String? id,
    String? sku,
    String? nameFr,
    String? nameAr,
    String? descriptionFr,
    String? descriptionAr,
    String? categoryId,
    double? basePrice,
    int? stock,
    bool? isActive,
    List<String>? medicalClassifications,
    List<String>? images,
    List<ProductVariant>? variants,
    bool? isFeatured,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      nameFr: nameFr ?? this.nameFr,
      nameAr: nameAr ?? this.nameAr,
      descriptionFr: descriptionFr ?? this.descriptionFr,
      descriptionAr: descriptionAr ?? this.descriptionAr,
      categoryId: categoryId ?? this.categoryId,
      basePrice: basePrice ?? this.basePrice,
      stock: stock ?? this.stock,
      isActive: isActive ?? this.isActive,
      medicalClassifications:
          medicalClassifications ?? this.medicalClassifications,
      images: images ?? this.images,
      variants: variants ?? this.variants,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Returns the localized name based on the provided locale code.
  ///
  /// Falls back to French if the Arabic name is empty.
  String getLocalizedName(String localeCode) {
    if (localeCode == 'ar' && nameAr.isNotEmpty) return nameAr;
    return nameFr;
  }

  /// Returns the localized description based on the provided locale code.
  ///
  /// Falls back to French if the Arabic description is null/empty.
  String? getLocalizedDescription(String localeCode) {
    if (localeCode == 'ar') {
      return descriptionAr?.isNotEmpty == true ? descriptionAr : descriptionFr;
    }
    return descriptionFr;
  }

  /// Returns the primary display image URL, or empty string if none.
  String get primaryImageUrl => images.isNotEmpty ? images.first : '';

  /// Returns `true` if this product has any stock (including variants).
  bool get hasStock {
    if (variants.isNotEmpty) {
      return variants.any((v) => v.isInStock);
    }
    return stock > 0 && isActive;
  }

  /// Returns the effective price.
  ///
  /// If variants exist, returns the price of the first variant.
  /// Otherwise returns the base price.
  double get effectivePrice {
    if (variants.isNotEmpty && variants.first.isActive) {
      return variants.first.price;
    }
    return basePrice;
  }

  /// Returns `true` if the product is marked as featured.
  bool get isFeaturedProduct => isFeatured;

  @override
  String toString() =>
      'Product(id: $id, sku: $sku, nameFr: $nameFr, price: $basePrice)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
