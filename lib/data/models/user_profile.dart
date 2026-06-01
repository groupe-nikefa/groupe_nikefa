// User profile model — represents a row in the Supabase `profiles` table.
//
// The `profiles` table extends `auth.users` via a foreign-key reference.
// Profile rows are automatically created by a database trigger when a
// new user signs up, so the Flutter app never inserts directly into
// this table.

import 'account_type.dart';

/// Role enum for user authorization.
///
/// Maps to the `role` enum column in the `profiles` table.
enum UserRole {
  /// Regular customer — can browse, order, and manage own profile.
  customer,

  /// Administrator — full access to product and order management.
  admin,
}

/// Parses a database role string into [UserRole].
UserRole? parseUserRole(String? value) {
  if (value == null) return null;
  return switch (value.toLowerCase()) {
    'customer' => UserRole.customer,
    'admin' => UserRole.admin,
    _ => null,
  };
}

/// Represents a user profile fetched from the Supabase `profiles` table.
///
/// Fields:
/// - [id]: UUID from Supabase Auth (primary key, references auth.users.id).
/// - [email]: User's email address (stored in auth.users, denormalized here).
/// - [phone]: User's phone number (required at registration).
/// - [accountType]: Type of account (individual, hospital, laboratory).
/// - [role]: Authorization role (customer or admin).
/// - [createdAt]: Timestamp when the profile was created.
class UserProfile {
  /// Unique identifier (UUID) matching the Supabase Auth user.
  final String id;

  /// User's email address.
  final String email;

  /// User's phone number.
  final String phone;

  /// Account type (individual, hospital, or laboratory).
  final AccountType accountType;

  /// Authorization role (customer or admin).
  final UserRole role;

  /// Profile creation timestamp.
  final DateTime createdAt;

  /// Creates a [UserProfile] with the given fields.
  const UserProfile({
    required this.id,
    required this.email,
    required this.phone,
    required this.accountType,
    required this.role,
    required this.createdAt,
  });

  /// Creates a [UserProfile] from a Supabase database row (JSON map).
  ///
  /// The expected map keys match the `profiles` table column names:
  /// `id`, `email`, `phone`, `account_type`, `role`, `created_at`.
  ///
  /// Unknown or missing enum values default to safe fallbacks:
  /// - accountType: [AccountType.individual]
  /// - role: [UserRole.customer]
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      accountType: parseAccountType(json['account_type'] as String?) ??
          AccountType.individual,
      role: parseUserRole(json['role'] as String?) ?? UserRole.customer,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Converts this profile to a JSON map for serialization.
  ///
  /// Useful for debugging, logging, and local caching scenarios.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'account_type': accountType.dbValue,
      'role': switch (role) {
        UserRole.customer => 'customer',
        UserRole.admin => 'admin',
      },
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Returns a copy of this profile with selectively updated fields.
  UserProfile copyWith({
    String? id,
    String? email,
    String? phone,
    AccountType? accountType,
    UserRole? role,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      accountType: accountType ?? this.accountType,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Returns `true` if this user has the admin role.
  bool get isAdmin => role == UserRole.admin;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'UserProfile(id: $id, email: $email, role: $role, accountType: $accountType)';
}
