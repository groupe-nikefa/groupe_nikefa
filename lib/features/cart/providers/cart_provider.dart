// Cart providers — Riverpod providers for cart state management.
//
// Connects the CartRepository to the UI layer. Handles both guest
// and authenticated cart states with automatic merge on login.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/cart_item.dart';
import '../../../data/repositories/cart_repository.dart';
import '../../../core/providers/auth_provider.dart';

// ──────────────────────────────────────────────────────────────
// Repository provider
// ──────────────────────────────────────────────────────────────

/// Provides a singleton [CartRepository] instance.
final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository();
});

// ──────────────────────────────────────────────────────────────
// Cart items stream
// ──────────────────────────────────────────────────────────────

/// Streams cart items for the current user (or guest cart).
///
/// Automatically switches between Supabase and Hive based on auth state.
/// For guest cart, uses Hive's box watch() for reactive updates.
final cartItemsProvider = StreamProvider<List<CartItem>>((ref) {
  final repository = ref.watch(cartRepositoryProvider);
  final user = ref.watch(currentUserProvider);

  if (user != null) {
    return repository.getCartItems(user.id);
  }

  // Guest mode: reactive Hive cart stream.
  return repository.watchGuestCart();
});

// ──────────────────────────────────────────────────────────────
// Cart count (for badge)
// ──────────────────────────────────────────────────────────────

/// Streams the total number of items in the cart (for badge counter).
final cartCountProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(cartRepositoryProvider);
  final user = ref.watch(currentUserProvider);

  if (user != null) {
    return repository.watchCartCount(user.id);
  }

  // Guest mode: reactive Hive count stream.
  return repository.watchGuestCartCount();
});

// ──────────────────────────────────────────────────────────────
// Cart total
// ──────────────────────────────────────────────────────────────

/// Computes the cart total including bulk pricing.
final cartTotalProvider = Provider<double>((ref) {
  final items = ref.watch(cartItemsProvider).valueOrNull ?? [];
  return items.fold<double>(0, (sum, item) => sum + (item.lineTotal));
});

// ──────────────────────────────────────────────────────────────
// Cart actions notifier
// ──────────────────────────────────────────────────────────────

/// State for cart actions (add, update, remove, clear).
class CartActionState {
  final bool isLoading;
  final String? error;

  const CartActionState({this.isLoading = false, this.error});

  CartActionState copyWith({bool? isLoading, String? error}) {
    return CartActionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for cart actions with loading/error state.
class CartActionNotifier extends Notifier<CartActionState> {
  CartRepository get _repository => ref.watch(cartRepositoryProvider);

  @override
  CartActionState build() => const CartActionState();

  /// Adds a product to the cart (guest or authenticated).
  Future<bool> addToCart({
    required String productId,
    required int quantity,
    Map<String, dynamic>? variantSelection,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        await _repository.addToCart(
          userId: user.id,
          productId: productId,
          quantity: quantity,
          variantSelection: variantSelection,
        );
      } else {
        await _repository.addToGuestCart(
          productId: productId,
          quantity: quantity,
          variantSelection: variantSelection,
        );
      }
      state = const CartActionState();
      return true;
    } catch (e) {
      final message = e is CartException ? e.message : 'something_went_wrong';
      state = state.copyWith(isLoading: false, error: message);
      return false;
    }
  }

  /// Updates a cart item's quantity.
  Future<bool> updateQuantity(String itemId, int quantity) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        await _repository.updateCartItem(itemId: itemId, quantity: quantity);
      } else {
        await _repository.updateGuestCartItem(
            itemId: itemId, quantity: quantity);
      }
      state = const CartActionState();
      return true;
    } catch (e) {
      final message = e is CartException ? e.message : 'something_went_wrong';
      state = state.copyWith(isLoading: false, error: message);
      return false;
    }
  }

  /// Removes a cart item.
  Future<bool> removeItem(String itemId) async {
    state = state.copyWith(isLoading: true);
    try {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        await _repository.removeCartItem(itemId);
      } else {
        await _repository.removeGuestCartItem(itemId);
      }
      state = const CartActionState();
      return true;
    } catch (e) {
      final message = e is CartException ? e.message : 'something_went_wrong';
      state = state.copyWith(isLoading: false, error: message);
      return false;
    }
  }

  /// Clears the entire cart.
  Future<bool> clearCart() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        await _repository.clearCart(user.id);
      } else {
        await _repository.clearGuestCart();
      }
      state = const CartActionState();
      return true;
    } catch (e) {
      final message = e is CartException ? e.message : 'something_went_wrong';
      state = state.copyWith(isLoading: false, error: message);
      return false;
    }
  }

  /// Merges guest cart into authenticated user's cart on login.
  Future<void> mergeGuestCart(String userId) async {
    try {
      await _repository.mergeGuestCart(userId);
    } catch (e) {
      debugPrint('[CartActionNotifier] Error merging guest cart: $e');
    }
  }
}

/// Provider for cart action notifier.
final cartActionProvider =
    NotifierProvider<CartActionNotifier, CartActionState>(
  CartActionNotifier.new,
);
