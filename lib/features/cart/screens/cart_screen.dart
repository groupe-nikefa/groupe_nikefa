// Cart screen — synced shopping cart view with guest/auth support.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../../../core/providers/auth_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cartAsync = ref.watch(cartItemsProvider);
    final actionState = ref.watch(cartActionProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        leading: user != null
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  ref
                      .read(appShellScaffoldKeyProvider)
                      .currentState
                      ?.openDrawer();
                },
              )
            : null,
        title: Text(l10n.cart),
      ),
      body: cartAsync.when(
        loading: () => const _CartSkeleton(),
        error: (e, _) => _ErrorView(
          message: l10n.something_went_wrong,
          onRetry: () => ref.invalidate(cartItemsProvider),
        ),
        data: (items) {
          if (items.isEmpty) return _EmptyCartView(l10n: l10n);

          final hasOutOfStock = items.any((item) => !item.isAvailable);
          final total = items.fold(0.0, (sum, item) => sum + item.lineTotal);
          final deliveryFee = total >= 50 ? 0.0 : 5.0;
          final grandTotal = total + deliveryFee;

          return Column(
            children: [
              if (user == null) const _GuestBanner(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => ref.invalidate(cartItemsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: items.length,
                    itemBuilder: (context, index) => _DismissibleCartItem(
                      item: items[index],
                      onDismiss: () {
                        final removed = items[index];
                        ref
                            .read(cartActionProvider.notifier)
                            .removeItem(removed.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.item_removed),
                            action: SnackBarAction(
                              label: l10n.undo,
                              onPressed: () async {
                                final success = await ref
                                    .read(cartActionProvider.notifier)
                                    .addToCart(
                                      productId: removed.productId,
                                      quantity: removed.quantity,
                                      variantSelection:
                                          removed.variantSelection,
                                    );
                                if (!success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text(l10n.something_went_wrong)),
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              _OrderSummary(
                subtotal: total,
                deliveryFee: deliveryFee,
                grandTotal: grandTotal,
                hasOutOfStock: hasOutOfStock,
                l10n: l10n,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed:
                        (user == null || hasOutOfStock || actionState.isLoading)
                            ? null
                            : () => context.go('/checkout'),
                    style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: actionState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(
                            user == null
                                ? l10n.login_to_checkout
                                : l10n.proceed_to_checkout,
                            style: const TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DismissibleCartItem extends ConsumerWidget {
  final CartItem item;
  final VoidCallback onDismiss;
  const _DismissibleCartItem({required this.item, required this.onDismiss});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final product = item.product;

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        color: AppColors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: product?.primaryImageUrl.isNotEmpty == true
                      ? CachedNetworkImage(
                          imageUrl: product!.primaryImageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                              color: AppColors.surface,
                              child: const Icon(Icons.inventory_2_outlined,
                                  color: AppColors.textSecondary)),
                          errorWidget: (_, __, ___) => Container(
                              color: AppColors.surface,
                              child: const Icon(Icons.inventory_2_outlined,
                                  color: AppColors.textSecondary)),
                        )
                      : Container(
                          color: AppColors.surface,
                          child: const Icon(Icons.inventory_2_outlined,
                              color: AppColors.textSecondary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product?.getLocalizedName(locale) ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    if (item.variantLabel != null) ...[
                      const SizedBox(height: 2),
                      Text(item.variantLabel!,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                    const SizedBox(height: 4),
                    if (product != null &&
                        product.stock <= 3 &&
                        product.stock > 0)
                      Text('${l10n.only} ${product.stock} ${l10n.left}!',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.red,
                              fontWeight: FontWeight.w500)),
                    if (product != null && product.stock == 0)
                      Text(l10n.out_of_stock,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.red,
                              fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${item.effectivePrice.toStringAsFixed(0)} DZD',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.deepBlue,
                                fontSize: 15)),
                        _QuantityStepper(item: item),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityStepper extends ConsumerWidget {
  final CartItem item;
  const _QuantityStepper({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(cartActionProvider).isLoading;
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: AppColors.surface),
          borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
              icon: const Icon(Icons.remove, size: 18),
              onPressed: (isLoading || item.quantity <= 1)
                  ? null
                  : () => ref
                      .read(cartActionProvider.notifier)
                      .updateQuantity(item.id, item.quantity - 1),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero),
          SizedBox(
              width: 36,
              child: Text('${item.quantity}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  textAlign: TextAlign.center)),
          IconButton(
              icon: const Icon(Icons.add, size: 18),
              onPressed: (isLoading ||
                      (item.product != null &&
                          item.quantity >= item.product!.stock))
                  ? null
                  : () => ref
                      .read(cartActionProvider.notifier)
                      .updateQuantity(item.id, item.quantity + 1),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero),
        ],
      ),
    );
  }
}

class _GuestBanner extends ConsumerWidget {
  const _GuestBanner();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.goldenYellow.withValues(alpha: 0.3),
      child: Row(children: [
        const Icon(Icons.info_outline, size: 20, color: AppColors.deepBlue),
        const SizedBox(width: 8),
        Expanded(
            child: Text(l10n.login_to_sync_cart,
                style:
                    const TextStyle(fontSize: 13, color: AppColors.deepBlue))),
        TextButton(
            onPressed: () => context.go('/login'),
            style: TextButton.styleFrom(
                foregroundColor: AppColors.deepBlue,
                padding: const EdgeInsets.symmetric(horizontal: 12)),
            child: Text(l10n.login)),
      ]),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final double subtotal;
  final double deliveryFee;
  final double grandTotal;
  final bool hasOutOfStock;
  final AppLocalizations l10n;
  const _OrderSummary(
      {required this.subtotal,
      required this.deliveryFee,
      required this.grandTotal,
      required this.hasOutOfStock,
      required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: Color(0xFFE0E0E0)))),
      child: Column(children: [
        _row(l10n.subtotal, '${subtotal.toStringAsFixed(0)} DZD'),
        _row(
            l10n.delivery_fee,
            deliveryFee == 0
                ? l10n.free
                : '${deliveryFee.toStringAsFixed(0)} DZD',
            valueColor: deliveryFee == 0 ? Colors.green : null),
        const Divider(height: 20),
        _row(l10n.total, '${grandTotal.toStringAsFixed(0)} DZD', isBold: true),
        if (hasOutOfStock) ...[
          const SizedBox(height: 8),
          Text(l10n.remove_out_of_stock_items,
              style: const TextStyle(color: AppColors.red, fontSize: 12)),
        ],
      ]),
    );
  }

  Widget _row(String label, String value,
          {Color? valueColor, bool isBold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: AppColors.textSecondary)),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: valueColor ?? AppColors.textPrimary)),
        ]),
      );
}

class _EmptyCartView extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyCartView({required this.l10n});
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Padding(
            padding: const EdgeInsets.all(32),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.shopping_cart_outlined,
                  size: 80, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(l10n.cart_is_empty,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(l10n.start_shopping_message,
                  style: const TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(
                  onPressed: () => context.go('/catalog'),
                  child: Text(l10n.browse_catalog)),
            ])));
  }
}

class _CartSkeleton extends StatelessWidget {
  const _CartSkeleton();
  @override
  Widget build(BuildContext context) => ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 4,
        itemBuilder: (_, __) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Container(
                            width: 160,
                            height: 14,
                            decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(4))),
                        const SizedBox(height: 8),
                        Container(
                            width: 100,
                            height: 12,
                            decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(4))),
                      ])),
                ]))),
      );
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
