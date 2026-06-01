// Loading overlay widget — reusable fullscreen loading spinner.
//
// Displays a semi-transparent overlay with a centered circular
// progress indicator and optional message. Used during async
// operations like Supabase initialization and auth flows.

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// A fullscreen loading overlay widget.
///
/// Shows a semi-transparent scrim with a centered [CircularProgressIndicator]
/// and an optional text message below it.
///
/// Can be used as a standalone widget to replace screen content during
/// loading states, or via [LoadingOverlay.show] for a modal overlay
/// on top of existing content.
class LoadingOverlay extends StatelessWidget {
  /// Optional message displayed below the spinner.
  final String? message;

  /// Text style for the message.
  final TextStyle? messageStyle;

  /// Color of the progress indicator. Defaults to brand deep blue.
  final Color? progressColor;

  /// Size of the progress indicator. Defaults to 48.
  final double? progressSize;

  /// Creates a [LoadingOverlay].
  const LoadingOverlay({
    super.key,
    this.message,
    this.messageStyle,
    this.progressColor,
    this.progressSize,
  });

  /// Shows a modal loading overlay on top of [child].
  ///
  /// This is a convenience constructor that wraps [child] in a
  /// [Stack] with the overlay positioned on top.
  static Widget wrap({
    required Widget child,
    required bool isLoading,
    String? message,
  }) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: const LoadingOverlay(),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                progressColor ?? AppColors.deepBlue,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: messageStyle ?? Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
