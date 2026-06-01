import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/order.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/admin_providers.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(adminStatsProvider);
    final ordersAsync = ref.watch(adminOrdersProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminStatsProvider);
        ref.invalidate(adminOrdersProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.dashboard_overview,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800]),
            ),
            const SizedBox(height: 24),
            statsAsync.when(
              data: (stats) => Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _StatCard(
                    title: l10n.total_products,
                    value: stats.productCount.toString(),
                    icon: Icons.inventory_2,
                    color: Colors.blue,
                  ),
                  _StatCard(
                    title: l10n.pending_orders,
                    value: stats.pendingOrderCount.toString(),
                    icon: Icons.shopping_cart,
                    color: Colors.orange,
                  ),
                  _StatCard(
                    title: l10n.total_revenue,
                    value:
                        '${l10n.currency_symbol}${stats.totalRevenue.toStringAsFixed(0)}',
                    icon: Icons.attach_money,
                    color: Colors.green,
                  ),
                  _StatCard(
                    title: l10n.low_stock_warning,
                    value: stats.lowStockCount.toString(),
                    icon: Icons.warning_amber,
                    color: Colors.red,
                  ),
                ],
              ),
              loading: () => Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _SkeletonCard(),
                  _SkeletonCard(),
                  _SkeletonCard(),
                  _SkeletonCard()
                ],
              ),
              error: (_, __) => Text(l10n.error_occurred),
            ),
            const SizedBox(height: 32),
            _buildQuickActions(context, l10n),
            const SizedBox(height: 32),
            Text(
              l10n.recent_activity,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800]),
            ),
            const SizedBox(height: 16),
            ordersAsync.when(
              data: (orders) {
                if (orders.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(l10n.no_orders_found,
                          style: TextStyle(color: Colors.grey[600])),
                    ),
                  );
                }
                return _RecentOrdersList(orders: orders.take(5).toList());
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Text(l10n.error_occurred),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AppLocalizations l10n) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ActionChip(
          avatar: Icon(Icons.add, color: AppColors.deepBlue),
          label: Text(l10n.add_new_product),
          onPressed: () => context.go('/admin/products'),
          backgroundColor: AppColors.deepBlue.withValues(alpha: 0.08),
        ),
        ActionChip(
          avatar: Icon(Icons.receipt_long, color: Colors.orange),
          label: Text(l10n.view_manage_orders),
          onPressed: () => context.go('/admin/orders'),
          backgroundColor: Colors.orange.withValues(alpha: 0.08),
        ),
        ActionChip(
          avatar: Icon(Icons.category, color: Colors.purple),
          label: Text(l10n.manage_categories),
          onPressed: () => context.go('/admin/categories'),
          backgroundColor: Colors.purple.withValues(alpha: 0.08),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(
      {required this.title,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(value,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800])),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 120,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8))),
          const SizedBox(height: 16),
          Container(width: 60, height: 28, color: Colors.grey[200]),
          const SizedBox(height: 4),
          Container(width: 100, height: 14, color: Colors.grey[200]),
        ],
      ),
    );
  }
}

class _RecentOrdersList extends ConsumerWidget {
  final List<Order> orders;
  const _RecentOrdersList({required this.orders});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: orders.map((order) {
          return ListTile(
            leading: _StatusDot(status: order.status),
            title: Text('#${order.shortId}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
                '${_fmtDate(order.createdAt)} • ${order.itemCount} ${l10n.items}'),
            trailing: Text(
                '${l10n.currency_symbol}${order.totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.deepBlue)),
            onTap: () => context.go('/admin/orders/${order.id}'),
          );
        }).toList(),
      ),
    );
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _StatusDot extends StatelessWidget {
  final OrderStatus status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      OrderStatus.pending => Colors.orange,
      OrderStatus.confirmed => Colors.blue,
      OrderStatus.shipped => Colors.purple,
      OrderStatus.delivered => Colors.green,
      OrderStatus.cancelled => Colors.red,
    };
    return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}
