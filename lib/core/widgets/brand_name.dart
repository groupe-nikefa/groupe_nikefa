// BrandName widget — renders "GROUPE NIKEFA" with brand styling and logo.
//
// "GROUPE" in Deep Blue (#002664), "NIKEFA" in Red (#C60C30).
// Includes the brand logo icon on the right side.
// Font: geometric sans-serif, bold, all caps.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_colors.dart';

/// Displays the GROUPE NIKEFA brand name with logo and proper color styling.
///
/// Layout: "GROUPE" (Deep Blue) + "NIKEFA" (Red) + Logo Icon
/// The widget supports both LTR (French) and RTL (Arabic) layouts.
class BrandName extends StatelessWidget {
  /// Font size for the brand text. Defaults to 24.
  final double? fontSize;

  /// FontWeight for the brand text. Defaults to [FontWeight.w800] (extra-bold).
  final FontWeight? fontWeight;

  /// Letter spacing for the brand text. Defaults to 1.5 for a geometric feel.
  final double? letterSpacing;

  /// Optional override for the "GROUPE" portion color.
  final Color? groupeColor;

  /// Optional override for the "NIKEFA" portion color.
  final Color? nikefaColor;

  /// Logo size. Defaults to fontSize * 1.5 if not provided.
  final double? logoSize;

  /// Creates a styled brand name widget with logo.
  const BrandName({
    super.key,
    this.fontSize,
    this.fontWeight,
    this.letterSpacing,
    this.groupeColor,
    this.nikefaColor,
    this.logoSize,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: fontSize ?? 24,
      fontWeight: fontWeight ?? FontWeight.w800,
      letterSpacing: letterSpacing ?? 1.5,
      height: 1.1,
    );

    final logoHeight = logoSize ?? (fontSize ?? 24) * 1.5;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'GROUPE',
            style: textStyle.copyWith(
              color: groupeColor ?? AppColors.deepBlue,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'NIKEFA',
            style: textStyle.copyWith(
              color: nikefaColor ?? AppColors.red,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: logoHeight,
            child: SvgPicture.asset(
              'assets/images/logo.svg',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact inline version for use in AppBar titles and tight spaces.
class BrandNameCompact extends StatelessWidget {
  /// Font size. Defaults to 18 for AppBar usage.
  final double? fontSize;

  /// Creates a compact brand name widget for tight spaces.
  const BrandNameCompact({super.key, this.fontSize});

  @override
  Widget build(BuildContext context) {
    return BrandName(
      fontSize: fontSize ?? 18,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.0,
      logoSize: (fontSize ?? 18) * 1.3,
    );
  }
}
