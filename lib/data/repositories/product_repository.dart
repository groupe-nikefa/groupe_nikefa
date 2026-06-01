// Product repository — handles all Supabase product and category operations.
//
// This repository provides methods for fetching products and categories
// with Supabase Realtime subscriptions for live updates. It includes
// Hive caching for offline browsing of previously-loaded data.
//
// Features:
//   - Stream-based product/category fetching with filters
//   - Supabase Realtime subscriptions for live updates
//   - Hive caching for offline access
//   - Pagination support (limit/offset)
//   - Cursor-based pagination on created_at

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/hive/hive_registry.dart';
import '../models/product.dart';
import '../models/category.dart' as models;

/// Custom exception thrown by the product repository.
class ProductException implements Exception {
  /// Error message suitable for user display.
  final String message;

  /// Optional original exception for debugging.
  final Object? originalError;

  const ProductException(this.message, [this.originalError]);

  @override
  String toString() => 'ProductException: $message';
}

/// Repository for all product and category operations.
///
/// Wraps Supabase queries and maps their results to typed models.
/// Includes realtime subscriptions and offline caching via Hive.
class ProductRepository {
  /// Supabase client (accessed via the initialized singleton).
  SupabaseClient get _client => supabaseClient;

  // ─────────────────────────────────────────────────────────────
  // Categories
  // ─────────────────────────────────────────────────────────────

  /// Streams all categories, optionally filtered by parent ID.
  ///
  /// Emits a list of [models.Category] objects. If [parentId] is provided,
  /// only subcategories of that parent are returned.
  Stream<List<models.Category>> getCategories({String? parentId}) {
    return _streamCategories(parentId: parentId);
  }

  /// Internal stream implementation for categories.
  Stream<List<models.Category>> _streamCategories({String? parentId}) async* {
    try {
      debugPrint(
          '[ProductRepository] Streaming categories (parentId: $parentId)');

      // Build query.
      var query = _client.from('categories').select() as dynamic;

      if (parentId != null) {
        query = query.eq('parent_id', parentId);
      } else {
        // If no parentId, get top-level categories (parent_id is null).
        query = query.isFilter('parent_id', null);
      }

      final response = await query.order('created_at');

      final categories = (response as List)
          .map((json) => models.Category.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('[ProductRepository] Fetched ${categories.length} categories');

      // Cache categories in Hive.
      await _cacheCategories(categories);

      yield categories;

      // Subscribe to realtime changes.
      final stream = _client
          .from('categories')
          .stream(primaryKey: ['id']).order('created_at');

      await for (final changes in stream) {
        debugPrint(
            '[ProductRepository] Categories realtime update: ${changes.length} rows');

        final updatedCategories =
            changes.map((json) => models.Category.fromJson(json)).toList();

        // Filter by parentId if needed.
        final filtered = parentId != null
            ? updatedCategories.where((c) => c.parentId == parentId).toList()
            : updatedCategories.where((c) => c.parentId == null).toList();

        await _cacheCategories(filtered);
        yield filtered;
      }
    } catch (e) {
      debugPrint('[ProductRepository] Error streaming categories: $e');

      // On error, try to return cached data.
      final cached = await _getCachedCategories(parentId: parentId);
      if (cached.isNotEmpty) {
        debugPrint(
            '[ProductRepository] Returning cached categories (${cached.length})');
        yield cached;
      }

      throw ProductException('failed_to_load_categories', e);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Products
  // ─────────────────────────────────────────────────────────────

  /// Streams products with optional filters.
  ///
  /// Parameters:
  ///   - [categoryId]: Filter by category ID.
  ///   - [searchQuery]: Search in product names and descriptions.
  ///   - [minPrice]: Minimum price filter.
  ///   - [maxPrice]: Maximum price filter.
  ///   - [classifications]: Filter by medical classifications.
  ///   - [inStock]: If true, only return products with stock > 0.
  ///   - [featured]: If true, only return featured products.
  ///   - [limit]: Maximum number of results (pagination).
  ///   - [offset]: Offset for pagination.
  Stream<List<Product>> getProducts({
    String? categoryId,
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    List<String>? classifications,
    bool? inStock,
    bool? featured,
    int limit = 20,
    int offset = 0,
  }) {
    return _streamProducts(
      categoryId: categoryId,
      searchQuery: searchQuery,
      minPrice: minPrice,
      maxPrice: maxPrice,
      classifications: classifications,
      inStock: inStock,
      featured: featured,
      limit: limit,
      offset: offset,
    );
  }

  /// Internal stream implementation for products.
  Stream<List<Product>> _streamProducts({
    String? categoryId,
    String? searchQuery,
    double? minPrice,
    double? maxPrice,
    List<String>? classifications,
    bool? inStock,
    bool? featured,
    int limit = 20,
    int offset = 0,
  }) async* {
    try {
      debugPrint('[ProductRepository] Streaming products with filters');

      // Build query.
      var query = _client.from('products').select() as dynamic;

      // Apply filters.
      if (categoryId != null) {
        query = query.eq('category_id', categoryId);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Full-text search on name and description.
        query = query.or(
          'name_fr.ilike.%$searchQuery%,name_ar.ilike.%$searchQuery%,'
          'description_fr.ilike.%$searchQuery%,description_ar.ilike.%$searchQuery%',
        );
      }

      if (minPrice != null) {
        query = query.gte('base_price', minPrice);
      }

      if (maxPrice != null) {
        query = query.lte('base_price', maxPrice);
      }

      if (inStock == true) {
        query = query.gt('stock_quantity', 0);
      }

      if (featured == true) {
        query = query.eq('is_featured', true);
      }

      // Pagination and ordering.
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final products = (response as List)
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('[ProductRepository] Fetched ${products.length} products');

      // Cache products in Hive.
      await _cacheProducts(products);

      yield products;

      // Subscribe to realtime changes.
      final stream = _client
          .from('products')
          .stream(primaryKey: ['id']).order('created_at', ascending: false);

      await for (final changes in stream) {
        debugPrint(
            '[ProductRepository] Products realtime update: ${changes.length} rows');

        final updatedProducts = changes
            .map((json) => Product.fromJson(json))
            .where((p) => p.isActive)
            .toList();

        // Apply filters to realtime updates.
        final filtered = updatedProducts.where((p) {
          if (categoryId != null && p.categoryId != categoryId) return false;
          if (inStock == true && !p.hasStock) return false;
          if (featured == true && !p.isFeatured) return false;
          return true;
        }).toList();

        await _cacheProducts(filtered);
        yield filtered;
      }
    } catch (e) {
      debugPrint('[ProductRepository] Error streaming products: $e');

      // On error, try to return cached data.
      final cached = await _getCachedProducts(
        categoryId: categoryId,
        limit: limit,
        offset: offset,
      );
      if (cached.isNotEmpty) {
        debugPrint(
            '[ProductRepository] Returning cached products (${cached.length})');
        yield cached;
      }

      throw ProductException('failed_to_load_products', e);
    }
  }

  /// Streams a single product by ID.
  Stream<Product> getProductById(String id) async* {
    try {
      debugPrint('[ProductRepository] Fetching product: $id');

      final response =
          await _client.from('products').select().eq('id', id).single();

      final product = Product.fromJson(response);

      // Cache this product.
      await _cacheSingleProduct(product);

      yield product;

      // Subscribe to realtime changes for this product.
      final stream =
          _client.from('products').stream(primaryKey: ['id']).eq('id', id);

      await for (final changes in stream) {
        if (changes.isNotEmpty) {
          final updated = Product.fromJson(changes.first);
          await _cacheSingleProduct(updated);
          yield updated;
        }
      }
    } catch (e) {
      debugPrint('[ProductRepository] Error fetching product: $e');
      throw ProductException('failed_to_load_product', e);
    }
  }

  /// Streams featured products for the home page.
  Stream<List<Product>> getFeaturedProducts({int limit = 8}) {
    return _streamProducts(featured: true, limit: limit);
  }

  /// Manually refresh products (e.g., pull-to-refresh).
  Future<void> refreshProducts() async {
    // Clear cache to force fresh fetch.
    await _clearProductCache();
    debugPrint('[ProductRepository] Product cache cleared for refresh');
  }

  // ─────────────────────────────────────────────────────────────
  // Image URL Helper
  // ─────────────────────────────────────────────────────────────

  /// Returns the public URL for a product image from Supabase Storage.
  ///
  /// If [imagePath] is a full URL, returns it as-is.
  /// Otherwise, constructs the URL from the bucket path.
  String getProductImageUrl(String imagePath) {
    if (imagePath.startsWith('http')) return imagePath;

    return _client.storage
        .from(AppStrings.productImagesBucket)
        .getPublicUrl(imagePath);
  }

  // ─────────────────────────────────────────────────────────────
  // Hive Caching
  // ─────────────────────────────────────────────────────────────

  /// Caches a list of products in Hive.
  Future<void> _cacheProducts(List<Product> products) async {
    try {
      final box = Hive.box<Product>(HiveBoxes.products);
      for (final product in products) {
        await box.put(product.id, product);
      }
      debugPrint('[ProductRepository] Cached ${products.length} products');
    } catch (e) {
      debugPrint('[ProductRepository] Error caching products: $e');
    }
  }

  /// Caches a single product in Hive.
  Future<void> _cacheSingleProduct(Product product) async {
    try {
      final box = Hive.box<Product>(HiveBoxes.products);
      await box.put(product.id, product);
    } catch (e) {
      debugPrint('[ProductRepository] Error caching product: $e');
    }
  }

  /// Retrieves cached products from Hive.
  Future<List<Product>> _getCachedProducts({
    String? categoryId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final box = Hive.box<Product>(HiveBoxes.products);
      var products = box.values.toList();

      // Apply filters.
      if (categoryId != null) {
        products = products.where((p) => p.categoryId == categoryId).toList();
      }

      // Sort by createdAt descending.
      products.sort((a, b) {
        final aTime = a.createdAt ?? DateTime(2000);
        final bTime = b.createdAt ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });

      // Apply pagination.
      final end = (offset + limit).clamp(0, products.length);
      products = products.sublist(offset, end);

      return products;
    } catch (e) {
      debugPrint('[ProductRepository] Error getting cached products: $e');
      return [];
    }
  }

  /// Caches categories in Hive.
  Future<void> _cacheCategories(List<models.Category> categories) async {
    try {
      final box = Hive.box<models.Category>(HiveBoxes.categories);
      for (final category in categories) {
        await box.put(category.id, category);
      }
      debugPrint('[ProductRepository] Cached ${categories.length} categories');
    } catch (e) {
      debugPrint('[ProductRepository] Error caching categories: $e');
    }
  }

  /// Retrieves cached categories from Hive.
  Future<List<models.Category>> _getCachedCategories({String? parentId}) async {
    try {
      final box = Hive.box<models.Category>(HiveBoxes.categories);
      var categories = box.values.toList();

      if (parentId != null) {
        categories = categories.where((c) => c.parentId == parentId).toList();
      } else {
        categories = categories.where((c) => c.parentId == null).toList();
      }

      return categories;
    } catch (e) {
      debugPrint('[ProductRepository] Error getting cached categories: $e');
      return [];
    }
  }

  /// Clears all cached products from Hive.
  Future<void> _clearProductCache() async {
    try {
      final box = Hive.box<Product>(HiveBoxes.products);
      await box.clear();
    } catch (e) {
      debugPrint('[ProductRepository] Error clearing product cache: $e');
    }
  }
}
