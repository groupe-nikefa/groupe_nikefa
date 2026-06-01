// Core app constants — brand colors, strings, and configuration values.
//
// Color system inspired by the Chad national flag:
// Deep Blue (#002664) for medical professionalism,
// Golden Yellow (#FECB00) for energy and highlights,
// Red (#C60C30) for alerts and important notices.

import 'package:flutter/material.dart';

/// Brand color palette for GROUPE NIKEFA.
abstract final class AppColors {
  // ── Primary Brand Colors ───────────────────────────────────

  /// Deep Blue — medical professionalism, trust, and authority.
  /// Used for: app bars, primary buttons, links, selected states.
  static const Color deepBlue = Color(0xFF002664);

  /// Golden Yellow — energy, optimism, and calls to action.
  /// Used for: CTA buttons, highlights, badges, accent elements.
  static const Color goldenYellow = Color(0xFFFECB00);

  /// Red — urgency, alerts, and important notices.
  /// Used for: error states, destructive actions, promotional banners.
  static const Color red = Color(0xFFC60C30);

  // ── Legacy Aliases (for backward compatibility) ─────────────

  /// @deprecated Use [deepBlue] instead.
  @Deprecated('Use deepBlue instead')
  static const Color nikefaBlue = deepBlue;

  /// @deprecated Use [goldenYellow] instead.
  @Deprecated('Use goldenYellow instead')
  static const Color nikefaYellow = goldenYellow;

  /// @deprecated Use [red] instead.
  @Deprecated('Use red instead')
  static const Color nikefaRed = red;

  /// @deprecated Use [deepBlue] instead.
  @Deprecated('Use deepBlue instead')
  static const Color primary = deepBlue;

  // ── Interface Colors ───────────────────────────────────────

  /// White — primary interface background.
  /// Used for: screen backgrounds, headers, card surfaces.
  static const Color white = Color(0xFFFFFFFF);

  /// Neutral surface color for subtle card backgrounds and dividers.
  static const Color surface = Color(0xFFF5F5F5);

  // ── Text Colors ────────────────────────────────────────────

  /// Text color for primary content.
  static const Color textPrimary = Color(0xFF1A1A1A);

  /// Text color for secondary / muted content.
  static const Color textSecondary = Color(0xFF6B7280);
}

/// App-wide string constants.
abstract final class AppStrings {
  /// Default Supabase storage bucket for product images.
  static const String productImagesBucket = 'product-images';

  /// Default pagination page size.
  static const int defaultPageSize = 20;
}
