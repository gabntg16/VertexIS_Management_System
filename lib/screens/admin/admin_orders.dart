// lib/screens/admin/admin_orders.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/data_service.dart';
import '../../models/models.dart';
import '../../utils/image_preview.dart';
import '../../utils/theme.dart';
import '../../widgets/shared_widgets.dart';

class AdminOrders extends StatefulWidget {
  const AdminOrders({super.key});

  @override
  State<AdminOrders> createState() => _AdminOrdersState();
}

class _AdminOrdersState extends State<AdminOrders> {
  OrderStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<DataService>();
    final orders = _filter == null
        ? svc.allOrders
        : svc.allOrders.where((o) => o.status == _filter).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('All Orders')),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _chip('All', null),
                const SizedBox(width: 8),
                ...OrderStatus.values.map((s) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _chip(s.label, s),
                    )),
              ],
            ),
          ),
          Expanded(
            child: orders.isEmpty
                ? const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    message: 'No orders found')
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: orders.length,
                    itemBuilder: (ctx, i) => OrderCard(
                      order: orders[i],
                      onTap: () => _showOrderDetail(ctx, orders[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, OrderStatus? status) {
    final theme = Theme.of(context);
    final selected = _filter == status;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = status),
      backgroundColor: theme.cardTheme.color,
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
          color: selected
              ? theme.colorScheme.primary
              : theme.textTheme.bodyMedium?.color,
          fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          fontSize: 12),
      side: BorderSide(
          color: selected
              ? theme.colorScheme.primary
              : theme.dividerColor.withValues(alpha: 0.1)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      showCheckmark: false,
    );
  }

  void _showOrderDetail(BuildContext context, Order order) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _OrderDetailSheet(order: order),
    );
  }
}

class _OrderDetailSheet extends StatefulWidget {
  final Order order;
  const _OrderDetailSheet({required this.order});

  @override
  State<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<_OrderDetailSheet> {
  final _rejectCtrl = TextEditingController();

  @override
  void dispose() {
    _rejectCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final svc = context.watch<DataService>();
    // Get fresh order
    final order = svc.allOrders
        .firstWhere((o) => o.id == widget.order.id, orElse: () => widget.order);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.disabledColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child:
                      Text('Order Details', style: theme.textTheme.titleLarge),
                ),
                StatusBadge(
                    label: order.status.label, color: order.status.color),
                if (order.status == OrderStatus.approved ||
                    order.status == OrderStatus.rejected) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _deleteOrder(context, svc, order),
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppTheme.error),
                    tooltip: 'Delete Order Record',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(DateFormat('MMM d, yyyy h:mm a').format(order.createdAt),
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 24),

            _infoRow(theme, 'Branch', order.branchName),
            _infoRow(theme, 'Order ID', order.id.substring(0, 8).toUpperCase()),
            const Divider(height: 32),

            Text('Items',
                style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(item.productName,
                            style: theme.textTheme.bodyMedium),
                      ),
                      Text('${item.quantity} packs',
                          style: theme.textTheme.bodySmall),
                      const SizedBox(width: 16),
                      Text('₱${item.subtotal.toStringAsFixed(2)}',
                          style: theme.textTheme.titleSmall),
                    ],
                  ),
                )),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Amount', style: theme.textTheme.titleMedium),
                Text('₱${NumberFormat('#,##0.00').format(order.totalAmount)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w900)),
              ],
            ),

            if (order.proofImagePath != null &&
                order.proofImagePath!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Payment Proof', style: theme.textTheme.labelLarge),
              const SizedBox(height: 12),
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.1)),
                ),
                clipBehavior: Clip.hardEdge,
                child: order.proofImagePath!.startsWith('http') ||
                        order.proofImagePath!.startsWith('blob:')
                    ? Image.network(
                        order.proofImagePath!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                          child: Icon(Icons.broken_image_outlined, size: 40),
                        ),
                      )
                    : (!kIsWeb
                        ? localImagePreview(order.proofImagePath!)
                        : const Center(
                            child: Text('Open locally to view proof.',
                                style: TextStyle(fontSize: 12)),
                          )),
              ),
            ],

            if (order.rejectionReason != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppTheme.error, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Rejection Reason: ${order.rejectionReason}',
                          style: const TextStyle(
                              color: AppTheme.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],

            if (order.status == OrderStatus.pending) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.warning.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: AppTheme.warning, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No payment proof uploaded yet.',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.warning,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Actions
            if (order.status == OrderStatus.waitingApproval ||
                order.status == OrderStatus.pending) ...[
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _reject(context, svc),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: const BorderSide(color: AppTheme.error),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('REJECT'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approve(context, svc),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('APPROVE'),
                    ),
                  ),
                ],
              ),
            ],

            if (order.status == OrderStatus.approved) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _createDelivery(context, svc, order),
                  icon: const Icon(Icons.local_shipping_rounded),
                  label: const Text('DISPATCH ORDER'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _deleteOrder(
      BuildContext context, DataService svc, Order order) async {
    final ok = await showConfirmDialog(context,
        title: 'Delete Order Record',
        message:
            'This will permanently remove this order from history. Inventory changes will NOT be reverted.',
        confirmText: 'Delete',
        confirmColor: AppTheme.error);
    if (ok == true) {
      await svc.deleteOrder(order.id);
      if (context.mounted) {
        showSnack(context, 'Order record deleted');
        Navigator.pop(context);
      }
    }
  }

  Future<void> _createDelivery(
      BuildContext context, DataService svc, Order order) async {
    final theme = Theme.of(context);
    final addrCtrl =
        TextEditingController(text: '${order.branchName} Warehouse');
    final courierCtrl = TextEditingController(text: 'J&T Express');
    final trackCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.disabledColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Dispatch Order', style: theme.textTheme.titleLarge),
              const SizedBox(height: 24),
              TextField(
                controller: addrCtrl,
                decoration:
                    const InputDecoration(labelText: 'Delivery Address'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: courierCtrl,
                decoration: const InputDecoration(labelText: 'Courier Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: trackCtrl,
                decoration: const InputDecoration(labelText: 'Tracking Number'),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await svc.createDelivery(
                      order.id,
                      addrCtrl.text,
                      courierName: courierCtrl.text,
                      trackingNumber: trackCtrl.text,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      showSnack(context, 'Delivery created and dispatched!');
                    }
                  },
                  child: const Text('CONFIRM DISPATCH'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(label, style: theme.textTheme.bodySmall),
            ),
            Text(value, style: theme.textTheme.titleSmall),
          ],
        ),
      );

  Future<void> _approve(BuildContext context, DataService svc) async {
    final order = svc.allOrders.firstWhere(
      (o) => o.id == widget.order.id,
      orElse: () => widget.order,
    );
    final message = order.status == OrderStatus.pending
        ? 'Approve this order directly without payment proof and update inventory?'
        : 'Approve this order and update inventory?';

    final ok = await showConfirmDialog(context,
        title: 'Approve Order',
        message: message,
        confirmText: 'Approve',
        confirmColor: AppTheme.success);
    if (ok != true || !mounted) return;
    await svc.approveOrder(widget.order.id);
    if (mounted) {
      if (context.mounted) {
        showSnack(context, 'Order approved!');
        Navigator.pop(context);
      }
    }
  }

  Future<void> _reject(BuildContext context, DataService svc) async {
    final theme = Theme.of(context);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Provide a reason for rejection:',
                style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _rejectCtrl,
              decoration:
                  const InputDecoration(hintText: 'e.g. Invalid payment proof'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  Text('Cancel', style: TextStyle(color: theme.disabledColor))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await svc.rejectOrder(widget.order.id, _rejectCtrl.text);
              if (mounted) {
                if (context.mounted) {
                  showSnack(context, 'Order rejected', error: true);
                  Navigator.pop(context);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('REJECT'),
          ),
        ],
      ),
    );
  }
}
