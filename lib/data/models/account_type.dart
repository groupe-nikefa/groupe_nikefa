// Account type enum — represents the type of customer account.
//
// Values map directly to the `account_type` enum column in the
// Supabase `profiles` table: 'individual', 'hospital', 'laboratory'.

import 'package:flutter/material.dart';

/// Enumeration of possible account types for a NIKEFA user.
///
/// Each value corresponds to a database enum value and provides
/// display metadata (icon, localized label key).
enum AccountType {
  /// Individual customer — personal medical supply purchases.
  individual,

  /// Hospital / clinic — bulk procurement for healthcare facility.
  hospital,

  /// Laboratory — medical testing and diagnostic equipment needs.
  laboratory,
}

/// Extension providing display helpers for [AccountType].
extension AccountTypeDisplay on AccountType {
  /// The database string value for this account type.
  ///
  /// This is the value stored in Supabase and used in queries.
  String get dbValue => switch (this) {
        AccountType.individual => 'individual',
        AccountType.hospital => 'hospital',
        AccountType.laboratory => 'laboratory',
      };

  /// Icon representing this account type in the UI.
  IconData get icon => switch (this) {
        AccountType.individual => Icons.person_outline,
        AccountType.hospital => Icons.local_hospital_outlined,
        AccountType.laboratory => Icons.science_outlined,
      };

  /// Localization key for the display name of this account type.
  ///
  /// The actual translated string is fetched via `AppLocalizations`
  /// using this key (e.g. `l10n.account_type_individual`).
  String get l10nKey => switch (this) {
        AccountType.individual => 'account_type_individual',
        AccountType.hospital => 'account_type_hospital',
        AccountType.laboratory => 'account_type_laboratory',
      };
}

/// Parses a database string into the corresponding [AccountType].
///
/// Returns `null` if the string does not match any known value.
AccountType? parseAccountType(String? value) {
  if (value == null) return null;
  return switch (value.toLowerCase()) {
    'individual' => AccountType.individual,
    'hospital' => AccountType.hospital,
    'laboratory' => AccountType.laboratory,
    _ => null,
  };
}
