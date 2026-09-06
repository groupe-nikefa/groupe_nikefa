// Order detail screen — displays full order info with realtime status tracking.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/order.dart';
import '../../../data/models/order_item.dart';
import '../providers/order_provider.dart';
import '../widgets/status_timeline.dart';
import '../../cart/providers/cart_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final orderAsync = ref.watch(orderByIdProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.order_details)),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: l10n.something_went_wrong,
          onRetry: () => ref.invalidate(orderByIdProvider(orderId)),
        ),
        data: (order) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(orderByIdProvider(orderId)),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order header
                _OrderHeader(order: order, l10n: l10n),
                const SizedBox(height: 20),

                // Status timeline
                StatusTimeline(
                  status: order.status,
                  isRTL: locale == 'ar',
                ),
                const SizedBox(height: 20),

                // Order items
                Text(l10n.order_items,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepBlue)),
                const SizedBox(height: 8),
                ...order.items
                    .map((item) => _OrderItemCard(item: item, locale: locale)),
                const SizedBox(height: 20),

                // Shipping address
                Text(l10n.shipping_address,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepBlue)),
                const SizedBox(height: 8),
                Card(
                    child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(order.formattedAddress,
                            style: const TextStyle(fontSize: 14)))),
                const SizedBox(height: 20),

                // Payment method
                Text(l10n.payment_method,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepBlue)),
                const SizedBox(height: 8),
                Card(
                    child: ListTile(
                  leading: const Icon(Icons.payments_outlined,
                      color: AppColors.deepBlue),
                  title: Text(l10n.cash_on_delivery),
                )),
                const SizedBox(height: 20),

                // Total
                Card(
                  color: AppColors.deepBlue,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.total,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        Text('${order.totalAmount.toStringAsFixed(0)} FCFA',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.goldenYellow)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action buttons
                if (order.status.canCancel)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.red,
                          side: const BorderSide(color: AppColors.red),
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () =>
                          _showCancelDialog(context, ref, order, l10n),
                      child: Text(l10n.cancel_order),
                    ),
                  ),
                if (order.status == OrderStatus.delivered)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () =>
                          _handleReorder(context, ref, order, l10n),
                      child: Text(l10n.reorder),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCancelDialog(
      BuildContext context, WidgetRef ref, Order order, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancel_order),
        content: Text(l10n.cancel_order_confirmation),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.no)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(createOrderProvider.notifier)
                  .cancelOrder(order.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.order_cancelled)));
              }
            },
            child: Text(l10n.yes),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReorder(BuildContext context, WidgetRef ref, Order order,
      AppLocalizations l10n) async {
    final cartNotifier = ref.read(cartActionProvider.notifier);
    var success = true;

    for (final item in order.items) {
      final added = await cartNotifier.addToCart(
        productId: item.productId,
        quantity: item.quantity,
        variantSelection: item.variantSelection,
      );
      if (!added) {
        success = false;
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? l10n.reorder_success : l10n.reorder_failed),
          backgroundColor: success ? Colors.green : AppColors.red,
        ),
      );
      if (success) {
        context.go('/cart');
      }
    }
  }
}

class _OrderHeader extends StatelessWidget {
  final Order order;
  final AppLocalizations l10n;
  const _OrderHeader({required this.order, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${l10n.order_number}: #${order.shortId}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                _StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('${l10n.order_date}: ${_formatDate(order.createdAt)}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = _getStatusStyle(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  (Color, String) _getStatusStyle(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isAr = locale == 'ar';
    return switch (status) {
      OrderStatus.pending => (
          AppColors.goldenYellow,
          isAr ? 'قيد الانتظار' : 'En attente'
        ),
      OrderStatus.confirmed => (Colors.blue, isAr ? 'مؤكد' : 'Confirmé'),
      OrderStatus.shipped => (Colors.purple, isAr ? 'تم الشحن' : 'Expédié'),
      OrderStatus.delivered => (Colors.green, isAr ? 'تم التسليم' : 'Livré'),
      OrderStatus.cancelled => (AppColors.red, isAr ? 'ملغي' : 'Annulé'),
    };
  }
}

class _OrderItemCard extends StatelessWidget {
  final OrderItem item;
  final String locale;
  const _OrderItemCard({required this.item, required this.locale});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              height: 52,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: item.product?.primaryImageUrl.isNotEmpty == true
                    ? CachedNetworkImage(
                        imageUrl: item.product!.primaryImageUrl,
                        fit: BoxFit.cover)
                    : Container(
                        color: AppColors.surface,
                        child: const Icon(Icons.inventory_2_outlined,
                            size: 20, color: AppColors.textSecondary)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.product?.getLocalizedName(locale) ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (item.variantLabel != null)
                    Text(item.variantLabel!,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                  Text(
                      'x${item.quantity}  •  ${item.unitPrice.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Text('${item.lineTotal.toStringAsFixed(0)} FCFA',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, size: 48, color: AppColors.red),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        OutlinedButton(
            onPressed: onRetry,
            child: Text(AppLocalizations.of(context)!.try_again)),
      ]));
}
