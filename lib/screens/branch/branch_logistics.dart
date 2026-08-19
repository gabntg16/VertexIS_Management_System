// lib/screens/branch/branch_logistics.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/data_service.dart';
import '../../models/models.dart';
import '../../utils/theme.dart';
import '../../widgets/shared_widgets.dart';

class BranchLogistics extends StatelessWidget {
  const BranchLogistics({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final svc = context.watch<DataService>();
    final deliveries = svc.branchDeliveries;
    final receivings = svc.branchReceivings;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Logistics'),
          bottom: TabBar(
            indicatorColor: theme.colorScheme.primary,
            indicatorWeight: 3,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.disabledColor,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            tabs: const [
              Tab(text: 'Incoming Deliveries'),
              Tab(text: 'Receiving History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _IncomingDeliveries(deliveries: deliveries),
            _ReceivingHistory(receivings: receivings),
          ],
        ),
      ),
    );
  }
}

class _IncomingDeliveries extends StatelessWidget {
  final List<Delivery> deliveries;
  const _IncomingDeliveries({required this.deliveries});

  @override
  Widget build(BuildContext context) {
    if (deliveries.isEmpty) {
      return const EmptyState(
          icon: Icons.local_shipping_outlined, message: 'No active deliveries');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: deliveries.length,
      itemBuilder: (_, i) => _DeliveryCard(delivery: deliveries[i]),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  final Delivery delivery;
  const _DeliveryCard({required this.delivery});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final svc = context.read<DataService>();
    final isDelivered = delivery.status == DeliveryStatus.delivered;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Text(delivery.trackingNumber ?? 'No Tracking',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900)),
                ),
                const Spacer(),
                StatusBadge(label: delivery.status.label, color: delivery.status.color),
              ],
            ),
            const SizedBox(height: 20),
            Text('Courier: ${delivery.courierName ?? 'N/A'}',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('Scheduled: ${DateFormat('MMMM d, yyyy').format(delivery.scheduledAt)}',
                style: theme.textTheme.bodySmall),
            if (delivery.trackingNumber != null && 
                (delivery.courierName?.toLowerCase().contains('j&t') == true || 
                 delivery.courierName?.toLowerCase().contains('jnt') == true)) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _launchJNT(context, delivery.trackingNumber!),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('TRACK ON J&T WEBSITE'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE62129),
                    side: const BorderSide(color: Color(0xFFE62129)),
                  ),
                ),
              ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(height: 1),
            ),
            if (!isDelivered)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _confirmReceiving(context, svc),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('CONFIRM RECEIPT'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                ),
              )
            else
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 20),
                  const SizedBox(width: 8),
                  Text('Delivery completed',
                      style: theme.textTheme.titleSmall?.copyWith(color: AppTheme.success, fontWeight: FontWeight.w800)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _confirmReceiving(BuildContext context, DataService svc) async {
    final theme = Theme.of(context);
    final nameCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
              Text('Confirm Receiving',
                  style: theme.textTheme.titleLarge),
              const SizedBox(height: 24),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Receiver Name', hintText: 'Who is receiving the items?'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes / Condition', hintText: 'Any damage or missing items?'),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty) return;
                    await svc.updateDeliveryStatus(delivery.id, DeliveryStatus.delivered, deliveredAt: DateTime.now());
                    await svc.createReceiving(
                      delivery.id,
                      receiverName: nameCtrl.text,
                      notes: notesCtrl.text,
                      receivedAt: DateTime.now(),
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      showSnack(context, 'Receipt confirmed and stock updated!');
                    }
                  },
                  child: const Text('CONFIRM & UPDATE STOCK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchJNT(BuildContext context, String tracking) async {
    Clipboard.setData(ClipboardData(text: tracking));
    final Uri url = Uri.parse('https://www.jtexpress.ph/trajectoryQuery?v=$tracking');
    try {
      final bool launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(Uri.parse('https://www.jtexpress.ph/index/query/query.html'), mode: LaunchMode.externalApplication);
      }
      if (context.mounted) showSnack(context, 'Number copied! Opening tracking tab...');
    } catch (e) {
      if (context.mounted) showSnack(context, 'Tracking number copied!', error: false);
    }
  }
}

class _ReceivingHistory extends StatelessWidget {
  final List<Receiving> receivings;
  const _ReceivingHistory({required this.receivings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (receivings.isEmpty) {
      return const EmptyState(
          icon: Icons.history_rounded, message: 'No receiving history');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: receivings.length,
      itemBuilder: (_, i) {
        final r = receivings[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.success.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.inventory_rounded, color: AppTheme.success, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Received by ${r.receiverName ?? 'Unknown'}',
                          style: theme.textTheme.titleSmall),
                      Text(DateFormat('MMMM d, yyyy • h:mm a').format(r.createdAt),
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: theme.disabledColor),
              ],
            ),
          ),
        );
      },
    );
  }
}
