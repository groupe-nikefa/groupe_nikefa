import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/order.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/admin_providers.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _statusTabs = [
    null,
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.shipped,
    OrderStatus.delivered,
    OrderStatus.cancelled,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ordersAsync = ref.watch(adminOrdersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Text(
            l10n.orders_management,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800]),
          ),
        ),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.deepBlue,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: AppColors.deepBlue,
          tabs: [
            Tab(text: l10n.all_orders),
            Tab(text: l10n.pending),
            Tab(text: l10n.confirmed),
            Tab(text: l10n.shipped),
            Tab(text: l10n.delivered),
            Tab(text: l10n.cancelled),
          ],
        ),
        Expanded(
          child: ordersAsync.when(
            data: (orders) {
              return TabBarView(
                controller: _tabController,
                children: _statusTabs.map((status) {
                  final filtered = status == null
                      ? orders
                      : orders.where((Order o) => o.status == status).toList();
                  return _OrderList(orders: filtered);
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
          ),
        ),
      ],
    );
  }
}

class _OrderList extends ConsumerWidget {
  final List<Order> orders;
  const _OrderList({required this.orders});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(l10n.no_orders_found,
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(adminOrdersProvider),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _OrderCard(order: order);
        },
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/admin/orders/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${order.shortId}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey[800]),
                  ),
                  _StatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${l10n.order_date}: ${_fmtDate(order.createdAt)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${order.itemCount} ${l10n.items}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    '${l10n.currency_symbol}${order.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.deepBlue),
                  ),
                ],
              ),
              if (!order.status.isTerminal) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _NextStatusButton(order: order),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (color, label) = switch (status) {
      OrderStatus.pending => (Colors.orange, l10n.pending),
      OrderStatus.confirmed => (Colors.blue, l10n.confirmed),
      OrderStatus.shipped => (Colors.purple, l10n.shipped),
      OrderStatus.delivered => (Colors.green, l10n.delivered),
      OrderStatus.cancelled => (Colors.red, l10n.cancelled),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

class _NextStatusButton extends ConsumerStatefulWidget {
  final Order order;
  const _NextStatusButton({required this.order});

  @override
  ConsumerState<_NextStatusButton> createState() => _NextStatusButtonState();
}

class _NextStatusButtonState extends ConsumerState<_NextStatusButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final nextStatus = widget.order.status.next;
    if (nextStatus == null) return const SizedBox.shrink();

    final label = switch (nextStatus) {
      OrderStatus.confirmed => l10n.confirmed,
      OrderStatus.shipped => l10n.shipped,
      OrderStatus.delivered => l10n.delivered,
      _ => l10n.update_status,
    };

    return ElevatedButton(
      onPressed: _isLoading ? null : _handleUpdate,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.deepBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : Text(label),
    );
  }

  Future<void> _handleUpdate() async {
    setState(() => _isLoading = true);
    final notifier = ref.read(orderStatusProvider.notifier);
    final ok =
        await notifier.updateStatus(widget.order.id, widget.order.status.next!);
    if (mounted) {
      setState(() => _isLoading = false);
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(ok ? l10n.order_status_updated : l10n.error_occurred)),
      );
    }
  }
}
