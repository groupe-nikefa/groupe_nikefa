// Password strength indicator — visual feedback bar.
//
// Displays a color-coded strength meter based on the password's
// complexity: length, digit count, and special character presence.

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// Enum representing password strength levels.
enum PasswordStrength {
  weak,
  medium,
  strong,
}

/// Calculates the [PasswordStrength] for a given password string.
///
/// Rules:
/// - Less than 6 characters: [PasswordStrength.weak]
/// - 6+ chars with only letters: [PasswordStrength.weak]
/// - 6+ chars with at least one digit or special char: [PasswordStrength.medium]
/// - 8+ chars with digits AND special chars: [PasswordStrength.strong]
PasswordStrength calculatePasswordStrength(String password) {
  if (password.isEmpty) return PasswordStrength.weak;
  if (password.length < 6) return PasswordStrength.weak;

  final hasDigit = password.contains(RegExp(r'\d'));
  final hasSpecial = password.contains(RegExp(r'[^\w\s]'));
  final hasUpper = password.contains(RegExp(r'[A-Z]'));
  final hasLower = password.contains(RegExp(r'[a-z]'));

  int score = 0;
  if (password.length >= 8) score++;
  if (hasDigit) score++;
  if (hasSpecial) score++;
  if (hasUpper && hasLower) score++;

  if (score >= 3) return PasswordStrength.strong;
  if (score >= 1) return PasswordStrength.medium;
  return PasswordStrength.weak;
}

/// Extension providing display properties for [PasswordStrength].
extension PasswordStrengthDisplay on PasswordStrength {
  /// Color representing this strength level.
  Color get color => switch (this) {
        PasswordStrength.weak => AppColors.red,
        PasswordStrength.medium => AppColors.goldenYellow,
        PasswordStrength.strong => Colors.green,
      };

  /// Localization key for the strength label.
  String get l10nKey => switch (this) {
        PasswordStrength.weak => 'password_strength_weak',
        PasswordStrength.medium => 'password_strength_medium',
        PasswordStrength.strong => 'password_strength_strong',
      };

  /// Localized, human-readable label for this strength level.
  ///
  /// Resolves [l10nKey] through the active [AppLocalizations] so callers
  /// can render the translated string instead of the raw key.
  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (this) {
      PasswordStrength.weak => l10n.password_strength_weak,
      PasswordStrength.medium => l10n.password_strength_medium,
      PasswordStrength.strong => l10n.password_strength_strong,
    };
  }

  /// Number of filled segments (out of 3).
  int get segments => switch (this) {
        PasswordStrength.weak => 1,
        PasswordStrength.medium => 2,
        PasswordStrength.strong => 3,
      };
}

/// A widget that displays a password strength meter.
///
/// Shows a row of colored segments and a text label indicating
/// the strength level of the provided [password].
class PasswordStrengthIndicator extends StatelessWidget {
  /// The password to evaluate.
  final String password;

  /// Optional custom text style for the label.
  final TextStyle? labelStyle;

  /// Optional height of the strength bar. Defaults to 4.
  final double barHeight;

  /// Optional gap between segments. Defaults to 4.
  final double segmentGap;

  /// Creates a [PasswordStrengthIndicator].
  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.labelStyle,
    this.barHeight = 4,
    this.segmentGap = 4,
  });

  @override
  Widget build(BuildContext context) {
    final strength = calculatePasswordStrength(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Strength bar segments
        Row(
          children: List.generate(3, (index) {
            final isFilled = index < strength.segments;
            return Expanded(
              child: Container(
                height: barHeight,
                margin: EdgeInsets.only(
                  right: index < 2 ? segmentGap : 0,
                ),
                decoration: BoxDecoration(
                  color: isFilled ? strength.color : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        // Strength label
        Text(
          strength.label(context),
          style: labelStyle ??
              Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: strength.color,
                  ),
        ),
      ],
    );
  }
}
