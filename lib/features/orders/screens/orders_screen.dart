// Orders screen — order history with status filters and pull-to-refresh.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../data/models/order.dart';
import '../providers/order_provider.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ordersAsync = ref.watch(userOrdersProvider);
    final filter = ref.watch(orderStatusFilterProvider);
    final filteredOrders = ref.watch(filteredOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () =>
              ref.read(appShellScaffoldKeyProvider).currentState?.openDrawer(),
        ),
        title: Text(l10n.orders),
      ),
      body: Column(
        children: [
          // Status filter chips
          _StatusFilterBar(
              l10n: l10n,
              selectedFilter: filter,
              onFilterChanged: (v) =>
                  ref.read(orderStatusFilterProvider.notifier).state = v),

          // Order list
          Expanded(
            child: ordersAsync.when(
              loading: () => const _OrdersSkeleton(),
              error: (e, _) => _ErrorView(
                message: l10n.something_went_wrong,
                onRetry: () => ref.invalidate(userOrdersProvider),
              ),
              data: (allOrders) {
                if (allOrders.isEmpty) return _EmptyOrdersView(l10n: l10n);
                if (filteredOrders.isEmpty && filter != null) {
                  return _NoFilteredResultsView(
                      l10n: l10n,
                      onClear: () => ref
                          .read(orderStatusFilterProvider.notifier)
                          .state = null);
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(userOrdersProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) =>
                        _OrderCard(order: filteredOrders[index], l10n: l10n),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  final AppLocalizations l10n;
  final OrderStatus? selectedFilter;
  final ValueChanged<OrderStatus?> onFilterChanged;

  const _StatusFilterBar(
      {required this.l10n,
      required this.selectedFilter,
      required this.onFilterChanged});

  @override
  Widget build(BuildContext context) {
    final filters = <MapEntry<OrderStatus?, String>>[
      MapEntry(null, l10n.all_orders),
      MapEntry(OrderStatus.pending, l10n.pending),
      MapEntry(OrderStatus.confirmed, l10n.confirmed),
      MapEntry(OrderStatus.shipped, l10n.shipped),
      MapEntry(OrderStatus.delivered, l10n.delivered),
      MapEntry(OrderStatus.cancelled, l10n.cancelled),
    ];

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: filters.map((entry) {
          final isSelected = selectedFilter == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(entry.value,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal)),
              selected: isSelected,
              onSelected: (_) => onFilterChanged(isSelected ? null : entry.key),
              selectedColor: AppColors.deepBlue,
              labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final AppLocalizations l10n;

  const _OrderCard({required this.order, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: () => context.push('/orders/${order.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('#${order.shortId}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  _StatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${l10n.order_date}: ${_formatDate(order.createdAt)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  Text('${order.itemCount} ${l10n.items}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${order.totalAmount.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.deepBlue,
                          fontSize: 15)),
                  const Icon(Icons.chevron_right,
                      color: AppColors.textSecondary, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = _getStyle(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  (Color, String) _getStyle(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
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

class _EmptyOrdersView extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptyOrdersView({required this.l10n});

  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.receipt_long_outlined,
                size: 80, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(l10n.no_orders_yet,
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

class _NoFilteredResultsView extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onClear;
  const _NoFilteredResultsView({required this.l10n, required this.onClear});

  @override
  Widget build(BuildContext context) => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(l10n.no_orders_with_filter,
            style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        TextButton(onPressed: onClear, child: Text(l10n.view_all_orders)),
      ]));
}

class _OrdersSkeleton extends StatelessWidget {
  const _OrdersSkeleton();
  @override
  Widget build(BuildContext context) => ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 5,
        itemBuilder: (_, __) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                                width: 100,
                                height: 14,
                                decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(4))),
                            Container(
                                width: 60,
                                height: 20,
                                decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(10))),
                          ]),
                      const SizedBox(height: 10),
                      Container(
                          width: 140,
                          height: 12,
                          decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 8),
                      Container(
                          width: 80,
                          height: 14,
                          decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(4))),
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
