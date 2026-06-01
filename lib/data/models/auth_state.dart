// Auth state model — tracks the current authentication status.
//
// This model is used by Riverpod providers to represent the
// complete auth state at any point in time, including loading,
// authenticated, and unauthenticated states.

import 'user_profile.dart';

/// Represents the complete authentication state of the app.
///
/// Used by the Riverpod auth notifier to drive UI updates:
/// - [isLoading]: Show loading spinners during async auth operations.
/// - [currentUser]: The logged-in user profile (null when not authenticated).
/// - [isAuthenticated]: Convenience flag derived from [currentUser].
/// - [error]: Optional error message to display to the user.
class AuthState {
  /// Whether an auth operation is currently in progress.
  final bool isLoading;

  /// The currently authenticated user, or null if logged out.
  final UserProfile? currentUser;

  /// Optional error message from the last failed auth operation.
  final String? error;

  /// Creates an [AuthState] with the given values.
  const AuthState({
    this.isLoading = false,
    this.currentUser,
    this.error,
  });

  /// Returns `true` if a user is currently authenticated.
  bool get isAuthenticated => currentUser != null;

  /// Creates the initial (logged-out) state.
  const AuthState.initial()
      : isLoading = false,
        currentUser = null,
        error = null;

  /// Returns a copy of this state with selectively updated fields.
  AuthState copyWith({
    bool? isLoading,
    UserProfile? currentUser,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      currentUser: currentUser ?? this.currentUser,
      error: error, // Clear error on any state change.
    );
  }

  /// Returns a new state with loading set to [value].
  AuthState withLoading(bool value) => copyWith(isLoading: value);

  /// Returns a new state with the current user set.
  AuthState withUser(UserProfile? user) => copyWith(currentUser: user);

  /// Returns a new state with an error message.
  AuthState withError(String error) => copyWith(isLoading: false, error: error);

  /// Returns a new state representing a successful logout.
  AuthState loggedOut() => const AuthState.initial();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthState &&
          runtimeType == other.runtimeType &&
          isLoading == other.isLoading &&
          currentUser == other.currentUser &&
          error == other.error;

  @override
  int get hashCode => Object.hash(isLoading, currentUser, error);

  @override
  String toString() =>
      'AuthState(isLoading: $isLoading, user: $currentUser, error: $error)';
}
