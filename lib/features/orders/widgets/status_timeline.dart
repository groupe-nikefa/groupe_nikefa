// Status timeline widget — visual order status progression.
//
// Displays a horizontal timeline showing the order lifecycle:
// pending → confirmed → shipped → delivered.
// Cancelled orders show a special state.

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/order.dart';

/// Visual timeline widget for order status tracking.
///
/// Shows each status step as a node with a connecting line.
/// Completed steps are highlighted, the current step pulses,
/// and future steps are dimmed.
class StatusTimeline extends StatelessWidget {
  /// The current order status.
  final OrderStatus status;

  /// Whether the layout should be RTL (Arabic).
  final bool isRTL;

  const StatusTimeline({
    super.key,
    required this.status,
    this.isRTL = false,
  });

  /// Ordered list of statuses in the lifecycle.
  static const _lifecycle = [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.shipped,
    OrderStatus.delivered,
  ];

  /// Maps a status to its icon.
  static const _statusIcons = {
    OrderStatus.pending: Icons.schedule_outlined,
    OrderStatus.confirmed: Icons.check_circle_outline,
    OrderStatus.shipped: Icons.local_shipping_outlined,
    OrderStatus.delivered: Icons.done_all,
    OrderStatus.cancelled: Icons.cancel_outlined,
  };

  @override
  Widget build(BuildContext context) {
    // Cancelled orders get a special display.
    if (status == OrderStatus.cancelled) {
      return _buildCancelledTimeline(context);
    }

    final currentIndex = _lifecycle.indexOf(status);

    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          children: List.generate(_lifecycle.length * 2 - 1, (index) {
            if (index.isEven) {
              final stepIndex = index ~/ 2;
              final stepStatus = _lifecycle[stepIndex];
              final isCompleted = stepIndex < currentIndex;
              final isCurrent = stepIndex == currentIndex;

              return _buildStep(
                context: context,
                status: stepStatus,
                isCompleted: isCompleted,
                isCurrent: isCurrent,
              );
            } else {
              final lineIndex = index ~/ 2;
              final isCompleted = lineIndex < currentIndex;

              return Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.deepBlue : AppColors.surface,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }
          }),
        ),
      ),
    );
  }

  /// Builds a single status step node.
  Widget _buildStep({
    required BuildContext context,
    required OrderStatus status,
    required bool isCompleted,
    required bool isCurrent,
  }) {
    final l10n = _getStatusLabel(context, status);

    Color bgColor;
    Color iconColor;
    if (isCompleted) {
      bgColor = AppColors.deepBlue;
      iconColor = Colors.white;
    } else if (isCurrent) {
      bgColor = AppColors.goldenYellow;
      iconColor = AppColors.deepBlue;
    } else {
      bgColor = AppColors.surface;
      iconColor = AppColors.textSecondary;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: isCurrent
                ? Border.all(color: AppColors.deepBlue, width: 2)
                : null,
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: AppColors.goldenYellow.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            _statusIcons[status] ?? Icons.circle,
            color: iconColor,
            size: 22,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent
                ? AppColors.deepBlue
                : isCompleted
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Builds the cancelled state timeline.
  Widget _buildCancelledTimeline(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.red,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cancel_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _getStatusLabel(context, OrderStatus.cancelled),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.red,
            ),
          ),
        ],
      ),
    );
  }

  /// Returns a localized status label.
  String _getStatusLabel(BuildContext context, OrderStatus status) {
    // Use hard-coded fallback since we can't depend on l10n directly
    // in a widget that might be used in different contexts.
    final locale = Localizations.localeOf(context).languageCode;
    final isAr = locale == 'ar';

    if (isAr) {
      return switch (status) {
        OrderStatus.pending => 'قيد الانتظار',
        OrderStatus.confirmed => 'مؤكد',
        OrderStatus.shipped => 'تم الشحن',
        OrderStatus.delivered => 'تم التسليم',
        OrderStatus.cancelled => 'ملغي',
      };
    }
    return switch (status) {
      OrderStatus.pending => 'En attente',
      OrderStatus.confirmed => 'Confirmé',
      OrderStatus.shipped => 'Expédié',
      OrderStatus.delivered => 'Livré',
      OrderStatus.cancelled => 'Annulé',
    };
  }
}
