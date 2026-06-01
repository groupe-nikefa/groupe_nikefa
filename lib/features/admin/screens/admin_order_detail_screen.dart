import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/order.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/admin_providers.dart';

final _orderProvider =
    FutureProvider.family<Order?, String>((ref, orderId) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.fetchOrderById(orderId);
});

class AdminOrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;
  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<AdminOrderDetailScreen> createState() =>
      _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState
    extends ConsumerState<AdminOrderDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final orderAsync = ref.watch(_orderProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(
        title: orderAsync.when(
          data: (order) => order != null
              ? Text('${l10n.order_number}: #${order.shortId}')
              : Text(l10n.order_details),
          loading: () => Text(l10n.order_details),
          error: (_, __) => Text(l10n.order_details),
        ),
        backgroundColor: AppColors.deepBlue,
        foregroundColor: Colors.white,
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${l10n.error_occurred}: $e')),
        data: (order) {
          if (order == null) {
            return Center(child: Text(l10n.error_occurred));
          }
          return _OrderDetailContent(order: order);
        },
      ),
    );
  }
}

class _OrderDetailContent extends ConsumerStatefulWidget {
  final Order order;
  const _OrderDetailContent({required this.order});

  @override
  ConsumerState<_OrderDetailContent> createState() =>
      _OrderDetailContentState();
}

class _OrderDetailContentState extends ConsumerState<_OrderDetailContent> {
  late Order _order;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  Future<void> _refresh() async {
    ref.invalidate(_orderProvider(widget.order.id));
  }

  Future<void> _updateStatus(OrderStatus newStatus) async {
    setState(() => _isUpdating = true);
    final notifier = ref.read(orderStatusProvider.notifier);
    final ok = await notifier.updateStatus(widget.order.id, newStatus);
    if (ok && mounted) {
      final refreshed = await ref.read(_orderProvider(widget.order.id).future);
      if (refreshed != null && mounted) {
        setState(() => _order = refreshed);
      }
    }
    if (mounted) {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusSection(_order, l10n),
            const SizedBox(height: 24),
            _buildCustomerInfo(_order, l10n),
            const SizedBox(height: 24),
            _buildOrderItems(_order, l10n),
            const SizedBox(height: 24),
            _buildOrderSummary(_order, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(Order order, AppLocalizations l10n) {
    final nextStatus = order.status.next;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.order_status,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800])),
            const SizedBox(height: 16),
            _StatusTimeline(order: order),
            if (nextStatus != null) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed:
                        _isUpdating ? null : () => _updateStatus(nextStatus),
                    icon: _isUpdating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.arrow_forward),
                    label: Text(
                        '${l10n.mark_as} ${_statusLabel(nextStatus, l10n)}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.goldenYellow,
                      foregroundColor: AppColors.deepBlue,
                    ),
                  ),
                  if (order.status == OrderStatus.pending) ...[
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _isUpdating
                          ? null
                          : () => _updateStatus(OrderStatus.cancelled),
                      icon: const Icon(Icons.cancel, size: 18),
                      label: Text(l10n.cancel_order),
                      style:
                          OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfo(Order order, AppLocalizations l10n) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.shipping_address,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800])),
            const SizedBox(height: 12),
            ...order.shippingAddress.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(e.key,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13)),
                      ),
                      Expanded(
                        child: Text(e.value,
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems(Order order, AppLocalizations l10n) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.order_items,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800])),
            const SizedBox(height: 12),
            ...order.items.map((item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8)),
                    child: item.product?.primaryImageUrl.isNotEmpty == true
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(item.product!.primaryImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                    Icons.inventory_2,
                                    color: Colors.grey[400])),
                          )
                        : Icon(Icons.inventory_2, color: Colors.grey[400]),
                  ),
                  title: Text(
                      item.product?.getLocalizedName('fr') ?? item.productId,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(
                      '${item.quantity}x ${l10n.currency_symbol}${item.unitPrice.toStringAsFixed(2)}'),
                  trailing: Text(
                      '${l10n.currency_symbol}${item.lineTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepBlue)),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(Order order, AppLocalizations l10n) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[200]!)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.subtotal, style: TextStyle(color: Colors.grey[600])),
                Text(
                    '${l10n.currency_symbol}${order.totalAmount.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.delivery_fee,
                    style: TextStyle(color: Colors.grey[600])),
                Text(l10n.free, style: TextStyle(color: Colors.green)),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.total,
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                    '${l10n.currency_symbol}${order.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepBlue)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(OrderStatus status, AppLocalizations l10n) {
    return switch (status) {
      OrderStatus.pending => l10n.pending,
      OrderStatus.confirmed => l10n.confirmed,
      OrderStatus.shipped => l10n.shipped,
      OrderStatus.delivered => l10n.delivered,
      OrderStatus.cancelled => l10n.cancelled,
    };
  }
}

class _StatusTimeline extends StatelessWidget {
  final Order order;
  const _StatusTimeline({required this.order});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statuses = [
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.shipped,
      OrderStatus.delivered,
    ];

    final currentIdx = statuses.indexOf(order.status);
    final isCancelled = order.status == OrderStatus.cancelled;

    if (isCancelled) {
      return Row(
        children: [
          Icon(Icons.cancel, color: Colors.red[400]),
          const SizedBox(width: 8),
          Text(l10n.cancelled_status,
              style: TextStyle(
                  color: Colors.red[700], fontWeight: FontWeight.w600)),
        ],
      );
    }

    return Row(
      children: statuses.asMap().entries.map((entry) {
        final idx = entry.key;
        final isCompleted = idx <= currentIdx;
        final isCurrent = idx == currentIdx;

        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          isCompleted ? AppColors.deepBlue : Colors.grey[300],
                    ),
                    child: Icon(
                      isCompleted ? Icons.check : Icons.circle,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.value.name[0].toUpperCase() +
                        entry.value.name.substring(1),
                    style: TextStyle(
                      fontSize: 10,
                      color: isCurrent ? AppColors.deepBlue : Colors.grey[600],
                      fontWeight:
                          isCurrent ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              if (idx < statuses.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: idx < currentIdx
                        ? AppColors.deepBlue
                        : Colors.grey[300],
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
