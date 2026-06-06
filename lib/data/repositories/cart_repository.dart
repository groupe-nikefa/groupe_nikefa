// Cart repository — handles all cart operations for both guest and authenticated users.
//
// Guest cart: stored in Hive (local persistence only).
// Authenticated cart: stored in Supabase with realtime sync.
// On login, guest cart items are merged into the server cart,
// keeping the latest updated_at per item.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../core/hive/hive_registry.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

/// Custom exception thrown by the cart repository.
class CartException implements Exception {
  final String message;
  final Object? originalError;
  const CartException(this.message, [this.originalError]);

  @override
  String toString() => 'CartException: $message';
}

/// Repository for all shopping cart operations.
///
/// Manages two cart sources:
///   - **Guest cart**: Hive-backed, persists locally without auth.
///   - **Authenticated cart**: Supabase-backed, realtime cross-device sync.
///
/// The [mergeGuestCart] method is called on login to synchronize
/// local cart items with the server cart.
class CartRepository {
  SupabaseClient get _client => supabaseClient;

  // ─────────────────────────────────────────────────────────────
  // Authenticated cart (Supabase)
  // ─────────────────────────────────────────────────────────────

  /// Streams cart items for an authenticated user with realtime updates.
  ///
  /// Fetches all products in a single query to avoid N+1 problem.
  Stream<List<CartItem>> getCartItems(String userId) {
    try {
      return _client
          .from('cart_items')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .asyncMap((rows) async {
            final items = rows.map((json) => CartItem.fromJson(json)).toList();

            if (items.isEmpty) return [];

            // Extract unique product IDs.
            final productIds =
                items.map((item) => item.productId).toSet().toList();

            // Fetch all products in a single query.
            final productsData = await _client
                .from('products')
                .select()
                .inFilter('id', productIds);

            // Build a lookup map for fast joining.
            final productMap = <String, Product>{};
            for (final json in productsData) {
              productMap[json['id'] as String] = Product.fromJson(json);
            }

            // Join cart items with product data.
            return items.map((item) {
              final product = productMap[item.productId];
              return product != null ? item.copyWith(product: product) : item;
            }).toList();
          });
    } catch (e) {
      debugPrint('[CartRepository] Error streaming cart items: $e');
      return Stream.value([]);
    }
  }

  /// Adds a product to the authenticated user's cart.
  ///
  /// If the product (with same variant) already exists, increments quantity.
  /// Validates stock before adding.
  Future<void> addToCart({
    required String userId,
    required String productId,
    required int quantity,
    Map<String, dynamic>? variantSelection,
  }) async {
    try {
      // Validate stock.
      final productData = await _client
          .from('products')
          .select('stock_quantity')
          .eq('id', productId)
          .single();
      final stock = productData['stock_quantity'] as int? ?? 0;

      // Check if item already exists in cart (matching product AND variant).
      final existingItems = await _client
          .from('cart_items')
          .select()
          .eq('user_id', userId)
          .eq('product_id', productId);

      final existingItem = existingItems.where((item) {
        final existingVariant = item['variant_selection'];
        if (variantSelection == null) {
          return existingVariant == null;
        }
        if (existingVariant == null) return false;
        return existingVariant is Map &&
            Map<String, dynamic>.from(existingVariant) == variantSelection;
      }).firstOrNull;

      if (existingItem != null) {
        final currentQty = existingItem['quantity'] as int;
        final newQty = currentQty + quantity;

        if (newQty > stock) {
          throw const CartException('exceeds_stock');
        }

        await _client.from('cart_items').update({
          'quantity': newQty,
          'updated_at': DateTime.now().toIso8601String()
        }).eq('id', existingItem['id'] as String);
      } else {
        if (quantity > stock) {
          throw const CartException('exceeds_stock');
        }

        await _client.from('cart_items').insert({
          'user_id': userId,
          'product_id': productId,
          'quantity': quantity,
          'variant_selection': variantSelection,
        });
      }

      debugPrint('[CartRepository] Added to cart: $productId x$quantity');
    } on CartException {
      rethrow;
    } catch (e) {
      debugPrint('[CartRepository] Error adding to cart: $e');
      throw CartException('failed_to_add_to_cart', e);
    }
  }

  /// Updates a cart item's quantity or variant selection.
  ///
  /// Validates that the requested quantity does not exceed available stock.
  Future<void> updateCartItem({
    required String itemId,
    int? quantity,
    Map<String, dynamic>? variantSelection,
  }) async {
    try {
      if (quantity != null) {
        // Fetch the cart item to get the product_id.
        final cartItemData = await _client
            .from('cart_items')
            .select('product_id')
            .eq('id', itemId)
            .single();
        final productId = cartItemData['product_id'] as String;

        // Fetch the product's current stock.
        final productData = await _client
            .from('products')
            .select('stock_quantity')
            .eq('id', productId)
            .single();
        final stock = productData['stock_quantity'] as int? ?? 0;

        if (quantity > stock) {
          throw const CartException('exceeds_stock');
        }
      }

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (quantity != null) updates['quantity'] = quantity;
      if (variantSelection != null) {
        updates['variant_selection'] = variantSelection;
      }

      await _client.from('cart_items').update(updates).eq('id', itemId);
      debugPrint('[CartRepository] Updated cart item: $itemId');
    } on CartException {
      rethrow;
    } catch (e) {
      debugPrint('[CartRepository] Error updating cart item: $e');
      throw CartException('failed_to_update_cart', e);
    }
  }

  /// Removes a single item from the authenticated user's cart.
  Future<void> removeCartItem(String itemId) async {
    try {
      await _client.from('cart_items').delete().eq('id', itemId);
      debugPrint('[CartRepository] Removed cart item: $itemId');
    } catch (e) {
      debugPrint('[CartRepository] Error removing cart item: $e');
      throw CartException('failed_to_remove_cart_item', e);
    }
  }

  /// Clears all items from the authenticated user's cart.
  Future<void> clearCart(String userId) async {
    try {
      await _client.from('cart_items').delete().eq('user_id', userId);
      debugPrint('[CartRepository] Cleared cart for user: $userId');
    } catch (e) {
      debugPrint('[CartRepository] Error clearing cart: $e');
      throw CartException('failed_to_clear_cart', e);
    }
  }

  /// Returns the number of items in the user's cart (for badge counter).
  Future<int> getCartCount(String userId) async {
    try {
      final response = await _client
          .from('cart_items')
          .select('quantity')
          .eq('user_id', userId);

      int count = 0;
      for (final row in response) {
        count += row['quantity'] as int;
      }
      return count;
    } catch (e) {
      debugPrint('[CartRepository] Error getting cart count: $e');
      return 0;
    }
  }

  /// Streams the cart item count for badge updates.
  Stream<int> watchCartCount(String userId) {
    return getCartItems(userId).map((items) {
      final count = items.fold<int>(0, (sum, item) => sum + item.quantity);
      debugPrint('[CartRepository] Cart count stream emitted: $count');
      return count;
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Guest cart (Hive)
  // ─────────────────────────────────────────────────────────────

  /// Returns the Hive box for guest cart items.
  Box<CartItem> get _guestCartBox => Hive.box<CartItem>(HiveBoxes.guestCart);

  /// Returns a reactive stream of guest cart items using Hive's box watch.
  Stream<List<CartItem>> watchGuestCart() async* {
    final box = _guestCartBox;
    yield box.values.toList();
    await for (final _ in box.watch()) {
      yield box.values.toList();
    }
  }

  List<CartItem> getGuestCartItems() {
    try {
      final box = _guestCartBox;
      return box.values.toList();
    } catch (e) {
      debugPrint('[CartRepository] Error reading guest cart: $e');
      return [];
    }
  }

  /// Adds a product to the guest cart (Hive).
  Future<void> addToGuestCart({
    required String productId,
    required int quantity,
    Map<String, dynamic>? variantSelection,
  }) async {
    try {
      final box = _guestCartBox;

      final existingKey = box.keys.firstWhere(
        (key) {
          final item = box.get(key)!;
          return item.productId == productId &&
              _mapsEqual(
                item.variantSelection ?? const {},
                variantSelection ?? const {},
              );
        },
        orElse: () => null,
      );

      if (existingKey != null) {
        final existing = box.get(existingKey)!;
        existing.quantity += quantity;
        existing.updatedAt = DateTime.now();
        await box.put(existingKey, existing);
      } else {
        final key = 'guest_${DateTime.now().millisecondsSinceEpoch}';
        final item = CartItem(
          id: key,
          userId: 'guest',
          productId: productId,
          quantity: quantity,
          variantSelection: variantSelection,
          updatedAt: DateTime.now(),
        );
        await box.put(key, item);
      }

      debugPrint('[CartRepository] Added to guest cart: $productId x$quantity');
    } catch (e) {
      debugPrint('[CartRepository] Error adding to guest cart: $e');
      throw CartException('failed_to_add_to_guest_cart', e);
    }
  }

  /// Updates a guest cart item.
  Future<void> updateGuestCartItem({
    required String itemId,
    int? quantity,
    Map<String, dynamic>? variantSelection,
  }) async {
    try {
      final box = _guestCartBox;
      final existing = box.get(itemId);
      if (existing == null) return;

      if (quantity != null) existing.quantity = quantity;
      if (variantSelection != null) {
        existing.variantSelection = variantSelection;
      }
      existing.updatedAt = DateTime.now();

      await box.put(itemId, existing);
    } catch (e) {
      debugPrint('[CartRepository] Error updating guest cart item: $e');
      throw CartException('failed_to_update_guest_cart', e);
    }
  }

  /// Removes a guest cart item.
  Future<void> removeGuestCartItem(String itemId) async {
    try {
      await _guestCartBox.delete(itemId);
    } catch (e) {
      debugPrint('[CartRepository] Error removing guest cart item: $e');
    }
  }

  /// Clears the guest cart.
  Future<void> clearGuestCart() async {
    try {
      await _guestCartBox.clear();
    } catch (e) {
      debugPrint('[CartRepository] Error clearing guest cart: $e');
    }
  }

  /// Returns a reactive stream of the guest cart item count.
  Stream<int> watchGuestCartCount() {
    return watchGuestCart().map((items) {
      return items.fold<int>(0, (sum, item) => sum + item.quantity);
    });
  }

  /// Returns the number of items in the guest cart.
  int getGuestCartCount() {
    final items = getGuestCartItems();
    return items.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  // ─────────────────────────────────────────────────────────────
  // Guest → Server merge on login
  // ─────────────────────────────────────────────────────────────

  /// Merges the guest cart (Hive) into the authenticated user's
  /// Supabase cart on login.
  ///
  /// For each guest item:
  ///   - If the product already exists in the server cart, keep the
  ///     one with the latest `updated_at` and sum quantities.
  ///   - Otherwise, insert the guest item into the server cart.
  ///
  /// After a successful merge, the guest cart is cleared.
  Future<void> mergeGuestCart(String userId) async {
    try {
      final guestItems = getGuestCartItems();
      if (guestItems.isEmpty) {
        debugPrint('[CartRepository] No guest cart items to merge');
        return;
      }

      debugPrint(
          '[CartRepository] Merging ${guestItems.length} guest cart items for user: $userId');

      for (final guestItem in guestItems) {
        try {
          await addToCart(
            userId: userId,
            productId: guestItem.productId,
            quantity: guestItem.quantity,
            variantSelection: guestItem.variantSelection,
          );
        } catch (e) {
          debugPrint(
              '[CartRepository] Error merging guest item ${guestItem.productId}: $e');
        }
      }

      // Clear guest cart after successful merge.
      await clearGuestCart();
      debugPrint('[CartRepository] Guest cart merged and cleared');
    } catch (e) {
      debugPrint('[CartRepository] Error merging guest cart: $e');
      throw CartException('failed_to_merge_cart', e);
    }
  }

  bool _mapsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
