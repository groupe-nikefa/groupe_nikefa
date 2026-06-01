// Catalog providers — Riverpod providers for categories and products.
//
// These providers connect the ProductRepository to the UI layer,
// managing state for category selection, product filtering, search,
// and pagination.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/models/category.dart';
import '../../../data/models/product.dart';

// ──────────────────────────────────────────────────────────────
// Repository provider
// ──────────────────────────────────────────────────────────────

/// Provides a singleton [ProductRepository] instance.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

// ──────────────────────────────────────────────────────────────
// Category providers
// ──────────────────────────────────────────────────────────────

/// Streams all top-level categories.
final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getCategories();
});

/// Streams subcategories for a given parent category.
final subcategoriesProvider = StreamProvider.family<List<Category>, String>((
  ref,
  parentId,
) {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getCategories(parentId: parentId);
});

/// The currently selected category ID (null means "all categories").
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// ──────────────────────────────────────────────────────────────
// Product filter state
// ──────────────────────────────────────────────────────────────

/// Represents the current filter state for product listing.
class ProductFilterState {
  /// Minimum price filter (null = no minimum).
  final double? minPrice;

  /// Maximum price filter (null = no maximum).
  final double? maxPrice;

  /// Selected medical classifications (empty = no filter).
  final List<String> classifications;

  /// If true, only show products in stock.
  final bool inStockOnly;

  /// If true, only show featured products.
  final bool featuredOnly;

  /// Creates a new filter state.
  const ProductFilterState({
    this.minPrice,
    this.maxPrice,
    this.classifications = const [],
    this.inStockOnly = false,
    this.featuredOnly = false,
  });

  /// Returns a copy with modified fields.
  ProductFilterState copyWith({
    double? minPrice,
    double? maxPrice,
    List<String>? classifications,
    bool? inStockOnly,
    bool? featuredOnly,
  }) {
    return ProductFilterState(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      classifications: classifications ?? this.classifications,
      inStockOnly: inStockOnly ?? this.inStockOnly,
      featuredOnly: featuredOnly ?? this.featuredOnly,
    );
  }

  /// Returns `true` if any filter is active.
  bool get hasActiveFilters =>
      minPrice != null ||
      maxPrice != null ||
      classifications.isNotEmpty ||
      inStockOnly ||
      featuredOnly;

  /// Resets all filters to default.
  ProductFilterState reset() => const ProductFilterState();
}

/// The current product filter state.
final filterStateProvider =
    NotifierProvider<FilterStateNotifier, ProductFilterState>(
  FilterStateNotifier.new,
);

/// Notifier for managing product filter state.
class FilterStateNotifier extends Notifier<ProductFilterState> {
  @override
  ProductFilterState build() => const ProductFilterState();

  /// Sets the minimum price.
  void setMinPrice(double? price) {
    state = state.copyWith(minPrice: price);
  }

  /// Sets the maximum price.
  void setMaxPrice(double? price) {
    state = state.copyWith(maxPrice: price);
  }

  /// Toggles a medical classification filter.
  void toggleClassification(String classification) {
    final updated = List<String>.from(state.classifications);
    if (updated.contains(classification)) {
      updated.remove(classification);
    } else {
      updated.add(classification);
    }
    state = state.copyWith(classifications: updated);
  }

  /// Toggles the in-stock filter.
  void toggleInStock(bool value) {
    state = state.copyWith(inStockOnly: value);
  }

  /// Toggles the featured filter.
  void toggleFeatured(bool value) {
    state = state.copyWith(featuredOnly: value);
  }

  /// Resets all filters.
  void reset() {
    state = const ProductFilterState();
  }
}

// ──────────────────────────────────────────────────────────────
// Search provider
// ──────────────────────────────────────────────────────────────

/// The current search query (debounced in the UI layer).
final searchQueryProvider = StateProvider<String>((ref) => '');

// ──────────────────────────────────────────────────────────────
// Pagination provider
// ──────────────────────────────────────────────────────────────

/// The current pagination offset (number of items loaded).
final paginationOffsetProvider = StateProvider<int>((ref) => 0);

/// The page size for pagination (20 for mobile, 40 for web).
final pageSizeProvider = StateProvider<int>((ref) => 20);

// ──────────────────────────────────────────────────────────────
// Product list provider
// ──────────────────────────────────────────────────────────────

/// Streams the filtered product list.
///
/// This provider combines:
///   - Selected category
///   - Search query
///   - Filter state
///   - Pagination offset
///
/// It automatically re-fetches when any of these change.
final productListProvider = StreamProvider<List<Product>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final searchQuery = ref.watch(searchQueryProvider);
  final filterState = ref.watch(filterStateProvider);
  final offset = ref.watch(paginationOffsetProvider);
  final pageSize = ref.watch(pageSizeProvider);

  return repository.getProducts(
    categoryId: selectedCategory,
    searchQuery: searchQuery.isEmpty ? null : searchQuery,
    minPrice: filterState.minPrice,
    maxPrice: filterState.maxPrice,
    classifications: filterState.classifications.isEmpty
        ? null
        : filterState.classifications,
    inStock: filterState.inStockOnly ? true : null,
    featured: filterState.featuredOnly ? true : null,
    limit: pageSize,
    offset: offset,
  );
});

// ──────────────────────────────────────────────────────────────
// Single product provider
// ──────────────────────────────────────────────────────────────

/// Streams a single product by ID.
final productByIdProvider = StreamProvider.family<Product, String>((
  ref,
  productId,
) {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getProductById(productId);
});

// ──────────────────────────────────────────────────────────────
// Featured products provider
// ──────────────────────────────────────────────────────────────

/// Streams featured products for the home page.
final featuredProductsProvider = StreamProvider<List<Product>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getFeaturedProducts(limit: 8);
});
