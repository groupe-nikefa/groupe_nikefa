// App theme — ThemeData with brand colors, typography, and RTL support.
//
// Color palette inspired by the Chad national flag:
// Deep Blue (#002664) for medical professionalism,
// Golden Yellow (#FECB00) for energy and highlights,
// Red (#C60C30) for alerts and important notices.

import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Produces the root [ThemeData] for the application.
///
/// The theme uses the NIKEFA brand palette and configures
/// typography that works well in both Arabic (RTL) and French (LTR).
ThemeData getAppTheme() {
  return ThemeData(
    // ── Color scheme ──────────────────────────────────────────
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.deepBlue,
      primary: AppColors.deepBlue,
      secondary: AppColors.goldenYellow,
      error: AppColors.red,
      surface: AppColors.white,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.white,

    // ── AppBar ────────────────────────────────────────────────
    // Golden Yellow background makes the blue "GROUPE" + red "NIKEFA"
    // brand name fully visible and evokes the Chad national flag palette.
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.goldenYellow,
      foregroundColor: AppColors.deepBlue,
      elevation: 1,
      centerTitle: true,
    ),

    // ── Typography ────────────────────────────────────────────
    // NotoSansArabic will be added as a custom font in a later step.
    // Until then, system fonts handle both Arabic and Latin text.
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: AppColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),

    // ── Buttons ───────────────────────────────────────────────
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.deepBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.deepBlue,
        side: const BorderSide(color: AppColors.deepBlue),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),

    // ── Input decoration ──────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.deepBlue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),

    // ── Cards ─────────────────────────────────────────────────
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: AppColors.white,
    ),

    // ── Bottom navigation ─────────────────────────────────────
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.deepBlue,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
    ),
  );
}
