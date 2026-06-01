// Auth Riverpod providers — connects the auth repository to the UI layer.
//
// This file replaces the mock providers from Step 2 with real
// Supabase-backed providers. It uses Riverpod's AsyncNotifier for
// stateful auth operations (sign-in, sign-up, sign-out) while
// streaming auth state changes from Supabase.
//
// Providers:
//   - authRepositoryProvider: Singleton AuthRepository instance.
//   - authStateStreamProvider: Stream of UserProfile? from Supabase.
//   - authNotifierProvider: AsyncNotifier for auth actions.
//   - currentUserProvider: Derived provider for the current user.
//   - isAdminProvider: Derived boolean for admin role check.
//   - authLoadingProvider: Derived boolean for loading state.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/auth_state.dart';
import '../../data/models/account_type.dart';
import '../../data/repositories/auth_repository.dart';

/// A change notifier that fires when auth state changes.
///
/// Used by GoRouter's `refreshListenable` to re-evaluate redirects
/// when the user logs in or out. This notifier is updated by the
/// [AuthNotifier] on every state change.
final authChangeNotifier = AuthChangeNotifier();

/// Internal change notifier for GoRouter redirect refresh.
class AuthChangeNotifier extends ChangeNotifier {
  /// Call this method whenever auth state changes.
  void notify() => notifyListeners();
}

// ──────────────────────────────────────────────────────────────
// Repository provider
// ──────────────────────────────────────────────────────────────

/// Provides a singleton [AuthRepository] instance.
///
/// All auth operations flow through this repository. It is created
/// once and shared across the app.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// ──────────────────────────────────────────────────────────────
// Auth state stream provider
// ──────────────────────────────────────────────────────────────

/// Streams the current user profile from Supabase auth state changes.
///
/// This provider listens to Supabase's `onAuthStateChange` event
/// and emits the corresponding [UserProfile] or `null` on logout.
/// It is the single source of truth for "who is logged in."
final authStateStreamProvider = StreamProvider<UserProfile?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

// ──────────────────────────────────────────────────────────────
// Auth Notifier (AsyncNotifier)
// ──────────────────────────────────────────────────────────────

/// AsyncNotifier managing auth actions (sign-in, sign-up, sign-out).
///
/// This notifier wraps [AuthRepository] methods and manages the
/// loading/error state internally. UI widgets should call methods
/// on this notifier rather than using the repository directly.
class AuthNotifier extends AsyncNotifier<AuthState> {
  late final AuthRepository _repository;

  @override
  Future<AuthState> build() async {
    _repository = ref.watch(authRepositoryProvider);

    // On startup, check if there's an existing session.
    final existingUser = await _repository.getCurrentUser();
    final initial = AuthState(currentUser: existingUser);

    // Listen to external auth state changes (session expiry, etc.).
    ref.listen(authStateStreamProvider, (_, next) {
      next.whenData((user) {
        _setState(AuthState(currentUser: user));
      });
    });

    return initial;
  }

  /// Internal helper to update state and notify the router.
  void _setState(AuthState newState) {
    final prev = state.valueOrNull;
    state = AsyncValue.data(newState);
    // Only notify router when the user actually changed.
    if (prev?.currentUser?.id != newState.currentUser?.id) {
      authChangeNotifier.notify();
    }
  }

  /// Signs in with email and password.
  ///
  /// Returns `true` on success, `false` on failure (error is stored
  /// in state).
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.data(AuthState(isLoading: true));

    try {
      final user = await _repository.signIn(
        email: email,
        password: password,
      );
      _setState(AuthState(currentUser: user));
      return true;
    } catch (e) {
      final message = e is AuthException ? e.message : 'something_went_wrong';
      _setState(AuthState(error: message));
      return false;
    }
  }

  /// Registers a new account.
  ///
  /// Returns `true` on success (user is auto-logged in), `false` on
  /// failure (error is stored in state).
  Future<bool> signUp({
    required String email,
    required String password,
    required String phone,
    required AccountType accountType,
  }) async {
    state = const AsyncValue.data(AuthState(isLoading: true));

    try {
      final user = await _repository.signUp(
        email: email,
        password: password,
        phone: phone,
        accountType: accountType,
      );
      _setState(AuthState(currentUser: user));
      return true;
    } catch (e) {
      final message = e is AuthException ? e.message : 'something_went_wrong';
      _setState(AuthState(error: message));
      return false;
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    state = const AsyncValue.data(AuthState(isLoading: true));

    try {
      await _repository.signOut();
      _setState(const AuthState.initial());
    } catch (e) {
      final message = e is AuthException ? e.message : 'something_went_wrong';
      _setState(AuthState(error: message));
    }
  }

  /// Clears the current error state (e.g., when user dismisses a snackbar).
  void clearError() {
    final current = state.valueOrNull;
    if (current != null && current.error != null) {
      _setState(current.copyWith(error: null));
    }
  }

  /// Sends a password reset email.
  ///
  /// Returns `true` on success, `false` on failure.
  Future<bool> sendPasswordReset(String email) async {
    state = const AsyncValue.data(AuthState(isLoading: true));

    try {
      await _repository.sendPasswordResetEmail(email);
      _setState(const AuthState());
      return true;
    } catch (e) {
      final message = e is AuthException ? e.message : 'something_went_wrong';
      _setState(AuthState(error: message));
      return false;
    }
  }
}

/// Provider for the [AuthNotifier].
final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

// ──────────────────────────────────────────────────────────────
// Derived providers (convenience accessors)
// ──────────────────────────────────────────────────────────────

/// The currently authenticated user, or null if logged out.
///
/// Reads from the auth notifier's current state.
final currentUserProvider = Provider<UserProfile?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.value?.currentUser;
});

/// Returns `true` if the current user has the admin role.
///
/// Used by the router to guard /admin routes.
final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.isAdmin ?? false;
});

/// Returns `true` if any auth operation is currently in progress.
final authLoadingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.value?.isLoading ?? false;
});

/// Returns `true` if a user is currently authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});
