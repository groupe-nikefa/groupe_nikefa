// Medical classification enum — predefined categories for medical products.
//
// These values map to the medical_classification enum column in the
// Supabase `products` table. Used for filtering and categorization.

import 'package:flutter/material.dart';

/// Enumeration of medical product classifications.
///
/// Each value corresponds to a classification type used in healthcare
/// settings for organizing medical supplies.
enum MedicalClassification {
  /// Disposable medical supplies (gloves, masks, syringes, etc.).
  disposable,

  /// Diagnostic equipment and supplies.
  diagnostic,

  /// Surgical instruments and supplies.
  surgical,

  /// Sterilization equipment and supplies.
  sterilization,

  /// Laboratory supplies and reagents.
  laboratory,

  /// Personal protective equipment.
  ppe,

  /// Wound care and dressings.
  woundCare,

  /// Orthopedic supplies and equipment.
  orthopedic,

  /// Respiratory equipment and supplies.
  respiratory,

  /// General medical supplies (catch-all category).
  general,
}

/// Extension providing display helpers for [MedicalClassification].
extension MedicalClassificationDisplay on MedicalClassification {
  /// The database string value for this classification.
  ///
  /// This is the value stored in Supabase and used in queries.
  String get dbValue => switch (this) {
        MedicalClassification.disposable => 'disposable',
        MedicalClassification.diagnostic => 'diagnostic',
        MedicalClassification.surgical => 'surgical',
        MedicalClassification.sterilization => 'sterilization',
        MedicalClassification.laboratory => 'laboratory',
        MedicalClassification.ppe => 'ppe',
        MedicalClassification.woundCare => 'wound_care',
        MedicalClassification.orthopedic => 'orthopedic',
        MedicalClassification.respiratory => 'respiratory',
        MedicalClassification.general => 'general',
      };

  /// Icon representing this classification in the UI.
  IconData get icon => switch (this) {
        MedicalClassification.disposable => Icons.inventory_2_outlined,
        MedicalClassification.diagnostic => Icons.analytics_outlined,
        MedicalClassification.surgical => Icons.science_outlined,
        MedicalClassification.sterilization => Icons.cleaning_services_outlined,
        MedicalClassification.laboratory => Icons.biotech_outlined,
        MedicalClassification.ppe => Icons.shield_outlined,
        MedicalClassification.woundCare => Icons.healing_outlined,
        MedicalClassification.orthopedic => Icons.accessibility_new_outlined,
        MedicalClassification.respiratory => Icons.air_outlined,
        MedicalClassification.general => Icons.medical_services_outlined,
      };

  /// Localization key for the display name of this classification.
  String get l10nKey => switch (this) {
        MedicalClassification.disposable => 'classification_disposable',
        MedicalClassification.diagnostic => 'classification_diagnostic',
        MedicalClassification.surgical => 'classification_surgical',
        MedicalClassification.sterilization => 'classification_sterilization',
        MedicalClassification.laboratory => 'classification_laboratory',
        MedicalClassification.ppe => 'classification_ppe',
        MedicalClassification.woundCare => 'classification_wound_care',
        MedicalClassification.orthopedic => 'classification_orthopedic',
        MedicalClassification.respiratory => 'classification_respiratory',
        MedicalClassification.general => 'classification_general',
      };
}

/// Parses a database string into the corresponding [MedicalClassification].
///
/// Returns `null` if the string does not match any known value.
MedicalClassification? parseMedicalClassification(String? value) {
  if (value == null) return null;
  return switch (value.toLowerCase()) {
    'disposable' => MedicalClassification.disposable,
    'diagnostic' => MedicalClassification.diagnostic,
    'surgical' => MedicalClassification.surgical,
    'sterilization' => MedicalClassification.sterilization,
    'laboratory' => MedicalClassification.laboratory,
    'ppe' => MedicalClassification.ppe,
    'wound_care' => MedicalClassification.woundCare,
    'orthopedic' => MedicalClassification.orthopedic,
    'respiratory' => MedicalClassification.respiratory,
    'general' => MedicalClassification.general,
    _ => null,
  };
}

/// Parses a list of database strings into [MedicalClassification] values.
///
/// Filters out any unrecognized values.
List<MedicalClassification> parseMedicalClassificationList(
  List<dynamic>? values,
) {
  if (values == null) return [];
  return values
      .map((v) => parseMedicalClassification(v.toString()))
      .whereType<MedicalClassification>()
      .toList();
}
