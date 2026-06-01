// Hive adapter registry — registers all Hive type adapters for offline caching.
//
// This file must be called during app initialization (in main.dart) before
// any Hive boxes are opened. It registers adapters for all cached models.

import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/product.dart';
import '../../data/models/category.dart';
import '../../data/models/product_variant.dart';
import '../../data/models/cart_item.dart';

/// Hive box names for cached data.
abstract final class HiveBoxes {
  /// Box storing cached products.
  static const String products = 'products';

  /// Box storing cached categories.
  static const String categories = 'categories';

  /// Box storing guest cart items (Hive-backed).
  static const String guestCart = 'guest_cart';
}

/// Initializes all Hive adapters and opens cached boxes.
///
/// Must be called during app startup, before any Hive operations.
Future<void> initHiveAdapters() async {
  // Register adapters for all cached models.
  Hive.registerAdapter(_ProductAdapter());
  Hive.registerAdapter(_CategoryAdapter());
  Hive.registerAdapter(_ProductVariantAdapter());
  Hive.registerAdapter(_BulkPricingTierAdapter());
  Hive.registerAdapter(_CartItemAdapter());

  // Open Hive boxes for cached data.
  await Hive.openBox<Product>(HiveBoxes.products);
  await Hive.openBox<Category>(HiveBoxes.categories);
  await Hive.openBox<CartItem>(HiveBoxes.guestCart);
}

// ──────────────────────────────────────────────────────────────
// Manual Hive Adapters
// ──────────────────────────────────────────────────────────────

/// Hive adapter for [Product].
class _ProductAdapter extends TypeAdapter<Product> {
  @override
  final int typeId = 0;


  @override
  Product read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Product(
      id: fields[0] as String,
      sku: fields[1] as String,
      nameFr: fields[2] as String,
      nameAr: fields[3] as String,
      descriptionFr: fields[4] as String?,
      descriptionAr: fields[5] as String?,
      categoryId: fields[6] as String,
      basePrice: (fields[7] as num?)?.toDouble() ?? 0.0,
      stock: fields[8] as int? ?? 0,
      isActive: fields[9] as bool? ?? true,
      medicalClassifications:
          (fields[10] as List<dynamic>?)?.cast<String>() ?? [],
      images: (fields[11] as List<dynamic>?)?.cast<String>() ?? [],
      variants: (fields[12] as List<dynamic>?)?.cast<ProductVariant>() ?? [],
      isFeatured: fields[13] as bool? ?? false,
      createdAt: fields[14] as DateTime?,
      updatedAt: fields[15] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Product obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sku)
      ..writeByte(2)
      ..write(obj.nameFr)
      ..writeByte(3)
      ..write(obj.nameAr)
      ..writeByte(4)
      ..write(obj.descriptionFr)
      ..writeByte(5)
      ..write(obj.descriptionAr)
      ..writeByte(6)
      ..write(obj.categoryId)
      ..writeByte(7)
      ..write(obj.basePrice)
      ..writeByte(8)
      ..write(obj.stock)
      ..writeByte(9)
      ..write(obj.isActive)
      ..writeByte(10)
      ..write(obj.medicalClassifications)
      ..writeByte(11)
      ..write(obj.images)
      ..writeByte(12)
      ..write(obj.variants)
      ..writeByte(13)
      ..write(obj.isFeatured)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.updatedAt);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ProductAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}

/// Hive adapter for [Category].
class _CategoryAdapter extends TypeAdapter<Category> {
  @override
  final int typeId = 1;


  @override
  Category read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Category(
      id: fields[0] as String,
      nameFr: fields[1] as String,
      nameAr: fields[2] as String,
      descriptionFr: fields[3] as String?,
      descriptionAr: fields[4] as String?,
      iconUrl: fields[5] as String?,
      parentId: fields[6] as String?,
      createdAt: fields[7] as DateTime?,
      slug: fields[8] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, Category obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nameFr)
      ..writeByte(2)
      ..write(obj.nameAr)
      ..writeByte(3)
      ..write(obj.descriptionFr)
      ..writeByte(4)
      ..write(obj.descriptionAr)
      ..writeByte(5)
      ..write(obj.iconUrl)
      ..writeByte(6)
      ..write(obj.parentId)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.slug);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _CategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}

/// Hive adapter for [ProductVariant].
class _ProductVariantAdapter extends TypeAdapter<ProductVariant> {
  @override
  final int typeId = 2;


  @override
  ProductVariant read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductVariant(
      id: fields[0] as String,
      productId: fields[1] as String,
      name: fields[2] as String,
      quantity: fields[3] as int,
      price: (fields[4] as num?)?.toDouble() ?? 0.0,
      stock: fields[5] as int? ?? 0,
      bulkPricing: (fields[6] as List<dynamic>?)?.cast<BulkPricingTier>() ?? [],
      isActive: fields[7] as bool? ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, ProductVariant obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.productId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.price)
      ..writeByte(5)
      ..write(obj.stock)
      ..writeByte(6)
      ..write(obj.bulkPricing)
      ..writeByte(7)
      ..write(obj.isActive);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ProductVariantAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}

/// Hive adapter for [BulkPricingTier].
class _BulkPricingTierAdapter extends TypeAdapter<BulkPricingTier> {
  @override
  final int typeId = 3;


  @override
  BulkPricingTier read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BulkPricingTier(
      minQty: fields[0] as int? ?? 0,
      maxQty: fields[1] as int?,
      unitPrice: (fields[2] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  void write(BinaryWriter writer, BulkPricingTier obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.minQty)
      ..writeByte(1)
      ..write(obj.maxQty)
      ..writeByte(2)
      ..write(obj.unitPrice);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _BulkPricingTierAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}

/// Hive adapter for [CartItem].
class _CartItemAdapter extends TypeAdapter<CartItem> {
  @override
  final int typeId = 4;


  @override
  CartItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CartItem(
      id: fields[0] as String,
      userId: fields[1] as String,
      productId: fields[2] as String,
      quantity: fields[3] as int,
      variantSelection: fields[4] as Map<String, dynamic>?,
      updatedAt: fields[5] as DateTime,
      product: fields[6] as Product?,
    );
  }

  @override
  void write(BinaryWriter writer, CartItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.productId)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.variantSelection)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.product);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _CartItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
