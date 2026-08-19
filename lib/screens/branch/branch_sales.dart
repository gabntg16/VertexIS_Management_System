// lib/screens/branch/branch_sales.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/data_service.dart';
import '../../models/models.dart';
import '../../utils/theme.dart';
import '../../widgets/shared_widgets.dart';

import 'branch_history.dart';

class BranchSales extends StatelessWidget {
  const BranchSales({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final svc = context.watch<DataService>();
    final sales = svc.branchSales;
    final totalRevenue = sales.fold(0.0, (s, e) => s + e.total);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BranchHistory()),
            ),
            tooltip: 'Transaction History',
          ),
          IconButton(
            icon: const Icon(Icons.add_business_rounded),
            onPressed: () => _recordSale(context, svc),
            tooltip: 'Record Sale',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Revenue card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.8)
                    ]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TOTAL REVENUE',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2)),
                        const SizedBox(height: 8),
                        Text(
                          '₱${NumberFormat('#,##0.00').format(totalRevenue)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text('${sales.length} transactions processed',
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.trending_up_rounded,
                        color: Colors.white, size: 32),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_graph_rounded,
                            color: theme.colorScheme.secondary, size: 20),
                        const SizedBox(width: 10),
                        Text('Demand Forecast',
                            style: theme.textTheme.titleSmall),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      svc.branchDemandForecast,
                      style: theme.textTheme.titleLarge?.copyWith(
                          color: AppTheme.success, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Expected weekly revenue: ₱${NumberFormat('#,##0').format(svc.branchWeeklyDemandForecast)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Analytics are based on your branch\'s historical sales trends.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            const SectionHeader(title: 'Recent Sales'),
            const SizedBox(height: 16),
            if (sales.isEmpty)
              const EmptyState(
                  icon: Icons.bar_chart_outlined,
                  message: 'No sales recorded yet'),
            ...sales.take(20).map((s) => _SaleItem(sale: s)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _recordSale(BuildContext context, DataService svc) async {
    final theme = Theme.of(context);
    String? selectedProductId;
    final qtyCtrl = TextEditingController(text: '1');
    final totalCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    XFile? receiptFile;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Record Manual Sale'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedProductId,
                  isExpanded: true,
                  dropdownColor: theme.cardTheme.color,
                  decoration:
                      const InputDecoration(labelText: 'Select Product'),
                  items: svc.branchInventory
                      .where((i) => i.stock > 0)
                      .fold<List<InventoryItem>>([], (list, item) {
                        if (!list.any((e) => e.productId == item.productId)) {
                          list.add(item);
                        }
                        return list;
                      })
                      .map((i) => DropdownMenuItem(
                            value: i.productId,
                            child: Text(i.productName,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setDlg(() {
                      selectedProductId = v;
                      if (v != null) {
                        final p = svc.products.firstWhere((p) => p.id == v);
                        final qty = int.tryParse(qtyCtrl.text) ?? 1;
                        totalCtrl.text = (p.price * qty).toStringAsFixed(2);
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Quantity'),
                        onChanged: (v) {
                          if (selectedProductId != null) {
                            final p = svc.products
                                .firstWhere((p) => p.id == selectedProductId);
                            final qty = int.tryParse(v) ?? 0;
                            setDlg(() => totalCtrl.text =
                                (p.price * qty).toStringAsFixed(2));
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: totalCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Total Price',
                          prefixText: '₱',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 90)),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setDlg(() => selectedDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            color: theme.colorScheme.primary, size: 18),
                        const SizedBox(width: 12),
                        Text(DateFormat('MMMM d, yyyy').format(selectedDate),
                            style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final picker = ImagePicker();
                    final selected = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1200,
                        imageQuality: 80);
                    if (selected != null) setDlg(() => receiptFile = selected);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: receiptFile != null
                          ? AppTheme.success.withValues(alpha: 0.05)
                          : theme.colorScheme.secondary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                          color: receiptFile != null
                              ? AppTheme.success
                              : theme.colorScheme.secondary
                                  .withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                            receiptFile != null
                                ? Icons.check_circle_rounded
                                : Icons.camera_alt_rounded,
                            color: receiptFile != null
                                ? AppTheme.success
                                : theme.colorScheme.secondary,
                            size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                              receiptFile != null
                                  ? 'Receipt Attached'
                                  : 'Attach Receipt Image',
                              style: theme.textTheme.titleSmall?.copyWith(
                                  color: receiptFile != null
                                      ? AppTheme.success
                                      : theme.colorScheme.secondary)),
                        ),
                        if (receiptFile != null)
                          GestureDetector(
                            onTap: () => setDlg(() => receiptFile = null),
                            child: const Icon(Icons.close_rounded,
                                color: AppTheme.error, size: 18),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: TextStyle(color: theme.disabledColor))),
            ElevatedButton(
              onPressed: () async {
                if (selectedProductId == null) {
                  return;
                }
                final qty = int.tryParse(qtyCtrl.text) ?? 1;
                final total = double.tryParse(totalCtrl.text);
                try {
                  await svc.recordSale(selectedProductId!, qty,
                      date: selectedDate,
                      customTotal: total,
                      receiptPath: receiptFile?.path);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    if (context.mounted) {
                      showSnack(context, 'Sale recorded successfully!');
                    }
                  }
                } catch (e) {
                  if (ctx.mounted && context.mounted) {
                    showSnack(context, e.toString(), error: true);
                  }
                }
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
              child: const Text('RECORD SALE'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaleItem extends StatelessWidget {
  final Sale sale;
  const _SaleItem({required this.sale});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.point_of_sale_rounded,
                  color: AppTheme.success, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(sale.productName, style: theme.textTheme.titleSmall),
                      if (sale.receiptPath != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.receipt_long_rounded,
                            color: theme.colorScheme.secondary, size: 14),
                      ],
                    ],
                  ),
                  Text(
                    '${sale.quantity} packs • ${DateFormat('MMMM d').format(sale.date)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₱${NumberFormat('#,##0.00').format(sale.total)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.success, fontWeight: FontWeight.w900)),
                if (sale.receiptPath != null)
                  GestureDetector(
                    onTap: () => _viewReceipt(context, sale.receiptPath!),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('View Proof',
                          style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.underline)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _viewReceipt(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Sale Receipt'),
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded))
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(path),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image_outlined, size: 40)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
