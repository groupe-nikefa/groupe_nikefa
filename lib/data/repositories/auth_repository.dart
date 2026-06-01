// Auth repository — handles all Supabase authentication operations.
//
// This repository wraps the Supabase Auth SDK and provides typed
// methods for sign-up, sign-in, sign-out, and auth state observation.
// Profile creation is handled by a database trigger on sign-up, so
// this repository never inserts directly into the `profiles` table.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../models/user_profile.dart';
import '../models/account_type.dart';

/// Custom exception thrown by the auth repository.
///
/// Contains a human-readable message suitable for direct display
/// to the user. Messages should be localized via l10n keys when
/// possible.
class AuthException implements Exception {
  /// Error message (prefer l10n keys for user-facing messages).
  final String message;

  /// Optional original exception for debugging.
  final Object? originalError;

  const AuthException(this.message, [this.originalError]);

  @override
  String toString() => 'AuthException: $message';
}

/// Repository for all authentication operations.
///
/// Wraps Supabase Auth calls and maps their errors to user-friendly
/// messages. The repository is stateless and safe to share across
/// Riverpod providers.
class AuthRepository {
  /// Supabase client (accessed via the initialized singleton).
  SupabaseClient get _client => supabaseClient;

  /// ─────────────────────────────────────────────────────────────
  /// Sign Up
  ///
  /// Creates a new user via Supabase Auth. The `profiles` table
  /// row is automatically created by a database trigger.
  ///
  /// Returns the [UserProfile] after successful registration.
  /// Throws [AuthException] on failure.
  /// ─────────────────────────────────────────────────────────────
  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String phone,
    required AccountType accountType,
  }) async {
    try {
      debugPrint('[AuthRepository] Signing up user: $email');

      // Create the auth user. The DB trigger will automatically
      // insert a row into the profiles table.
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        // Store metadata so the trigger can populate the profile.
        data: {
          'phone': phone,
          'account_type': accountType.dbValue,
        },
      );

      if (response.user == null) {
        debugPrint('[AuthRepository] Sign up failed: user is null');
        throw const AuthException('auth_signup_failed');
      }

      debugPrint('[AuthRepository] Auth user created: ${response.user!.id}');

      // Wait for the trigger to create the profile with retry logic.
      final profile = await _fetchProfileWithRetry(response.user!.id);

      if (profile == null) {
        debugPrint('[AuthRepository] Profile not created after retries');
        throw const AuthException('auth_profile_not_created');
      }

      debugPrint('[AuthRepository] Profile created successfully');
      return profile;
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('[AuthRepository] Sign up error: $e');
      throw AuthException(_mapAuthError(e), e);
    }
  }

  /// Fetches a profile with retry logic for eventual consistency.
  ///
  /// The database trigger may take a moment to create the profile,
  /// so we retry up to [maxAttempts] times with a [delay] between attempts.
  Future<UserProfile?> _fetchProfileWithRetry(
    String userId, {
    int maxAttempts = 5,
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      debugPrint(
        '[AuthRepository] Fetching profile attempt $attempt/$maxAttempts',
      );

      final profile = await _fetchProfile(userId);
      if (profile != null) {
        return profile;
      }

      if (attempt < maxAttempts) {
        debugPrint(
            '[AuthRepository] Waiting ${delay.inMilliseconds}ms before retry...');
        await Future.delayed(delay);
      }
    }

    return null;
  }

  /// ─────────────────────────────────────────────────────────────
  /// Sign In
  ///
  /// Authenticates with email and password.
  /// Returns the [UserProfile] after successful login.
  /// Throws [AuthException] on failure.
  /// ─────────────────────────────────────────────────────────────
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('[AuthRepository] Signing in user: $email');

      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        debugPrint('[AuthRepository] Sign in failed: user is null');
        throw const AuthException('auth_login_failed');
      }

      debugPrint('[AuthRepository] User signed in: ${response.user!.id}');

      final profile = await _fetchProfile(response.user!.id);

      if (profile == null) {
        // User exists in auth but has no profile row.
        // This should not happen with the trigger in place.
        debugPrint(
            '[AuthRepository] Profile not found for user: ${response.user!.id}');
        throw const AuthException('auth_profile_not_found');
      }

      return profile;
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('[AuthRepository] Sign in error: $e');
      throw AuthException(_mapAuthError(e), e);
    }
  }

  /// ─────────────────────────────────────────────────────────────
  /// Update Profile
  ///
  /// Updates the current user's profile fields (e.g. phone number).
  /// Throws [AuthException] on failure.
  /// ─────────────────────────────────────────────────────────────
  Future<void> updateProfile({String? phone}) async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) throw const AuthException('session_expired');

      final updates = <String, dynamic>{};
      if (phone != null) updates['phone'] = phone;

      if (updates.isNotEmpty) {
        await _client
            .from('profiles')
            .update(updates)
            .eq('id', session.user.id);
      }
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('profile_update_failed', e);
    }
  }

  /// ─────────────────────────────────────────────────────────────
  /// Sign Out
  ///
  /// Clears the current session. Safe to call when no user is
  /// logged in (no-op).
  /// ─────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw AuthException('auth_signout_failed', e);
    }
  }

  /// ─────────────────────────────────────────────────────────────
  /// Password Reset
  ///
  /// Sends a password reset email to the given email address.
  /// The email contains a link that allows the user to reset their
  /// password via Supabase's hosted password reset page.
  /// Throws [AuthException] on failure.
  /// ─────────────────────────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      debugPrint('[AuthRepository] Sending password reset email to: $email');
      await _client.auth.resetPasswordForEmail(email.trim());
      debugPrint('[AuthRepository] Password reset email sent successfully');
    } catch (e) {
      debugPrint('[AuthRepository] Password reset error: $e');
      throw AuthException(_mapAuthError(e), e);
    }
  }

  /// ─────────────────────────────────────────────────────────────
  /// Auth State Changes (Stream)
  ///
  /// Emits a [UserProfile?] whenever the Supabase auth state
  /// changes (login, logout, session refresh, etc.).
  /// Emits `null` when the user logs out or the session expires.
  /// ─────────────────────────────────────────────────────────────
  Stream<UserProfile?> get authStateChanges {
    return _client.auth.onAuthStateChange.asyncMap((event) async {
      final session = event.session;
      if (session == null) return null;

      final profile = await _fetchProfile(session.user.id);
      return profile;
    });
  }

  /// ─────────────────────────────────────────────────────────────
  /// Get Current User
  ///
  /// Returns the current user's profile if a valid session exists.
  /// Returns `null` if no session is active.
  ///
  /// This method validates the session by attempting to refresh it.
  /// If the session is expired or invalid, it is cleared and null is returned.
  /// ─────────────────────────────────────────────────────────────
  Future<UserProfile?> getCurrentUser() async {
    final session = _client.auth.currentSession;
    if (session == null) return null;

    // Validate the session by attempting to refresh it.
    // This handles cases where the access token has expired but
    // the refresh token is still valid (user should stay logged in).
    // If the session is completely invalid, this will throw and we
    // should sign out the user.
    try {
      debugPrint('[AuthRepository] Validating existing session...');
      final refreshedSession = await _client.auth.refreshSession();
      if (refreshedSession.session == null) {
        debugPrint(
            '[AuthRepository] Session validation failed: no session after refresh');
        await _client.auth.signOut();
        return null;
      }

      debugPrint('[AuthRepository] Session validated successfully');
      return _fetchProfile(refreshedSession.session!.user.id);
    } catch (e) {
      // Session is invalid/expired -- clear it and return null.
      debugPrint('[AuthRepository] Session validation failed: $e');
      try {
        await _client.auth.signOut();
      } catch (_) {
        // Ignore sign-out errors during cleanup
      }
      return null;
    }
  }

  /// ─────────────────────────────────────────────────────────────
  /// Internal: Fetch profile from the `profiles` table.
  /// ─────────────────────────────────────────────────────────────
  Future<UserProfile?> _fetchProfile(String userId) async {
    try {
      debugPrint('[AuthRepository] Fetching profile for user: $userId');

      final response =
          await _client.from('profiles').select().eq('id', userId).single();

      debugPrint('[AuthRepository] Profile fetched successfully');
      return UserProfile.fromJson(response);
    } catch (e) {
      // Profile may not exist yet or the user lacks access.
      debugPrint('[AuthRepository] Failed to fetch profile: $e');
      return null;
    }
  }

  /// ─────────────────────────────────────────────────────────────
  /// Internal: Map Supabase auth errors to user-friendly l10n keys.
  /// ─────────────────────────────────────────────────────────────
  String _mapAuthError(Object error) {
    final message = error.toString().toLowerCase();

    debugPrint('[AuthRepository] Mapping error: $message');

    // Network / connectivity errors.
    if (message.contains('socket') ||
        message.contains('network') ||
        message.contains('connection') ||
        message.contains('timeout')) {
      return 'network_error';
    }

    // Supabase auth error codes (from the API response).
    if (message.contains('invalid login credentials') ||
        message.contains('invalid_credentials')) {
      return 'invalid_credentials';
    }

    if (message.contains('user already registered') ||
        message.contains('already registered') ||
        message.contains('duplicate key') ||
        message.contains('email already')) {
      return 'email_already_exists';
    }

    if (message.contains('password') &&
        (message.contains('should be at least') ||
            message.contains('too short') ||
            message.contains('length'))) {
      return 'password_too_short';
    }

    if (message.contains('email') &&
        (message.contains('not valid') || message.contains('invalid'))) {
      return 'invalid_email';
    }

    if (message.contains('session') || message.contains('expired')) {
      return 'session_expired';
    }

    // Database trigger errors (profile creation failed).
    if (message.contains('trigger') ||
        message.contains('handle_new_user') ||
        message.contains('profile') ||
        message.contains('insert')) {
      debugPrint('[AuthRepository] Possible trigger-related error detected');
      return 'auth_profile_not_created';
    }

    // Fallback for unknown errors.
    return 'something_went_wrong';
  }
}
