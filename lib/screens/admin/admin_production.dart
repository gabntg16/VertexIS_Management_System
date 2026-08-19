// lib/screens/admin/admin_production.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/data_service.dart';
import '../../utils/theme.dart';
import '../../widgets/shared_widgets.dart';

class AdminProduction extends StatefulWidget {
  const AdminProduction({super.key});

  @override
  State<AdminProduction> createState() => _AdminProductionState();
}

class _AdminProductionState extends State<AdminProduction> {
  String? _selectedBranchId;
  String? _selectedProductId;
  String? _prodProductId;
  final _prodQtyCtrl = TextEditingController(text: '100');
  final _distQtyCtrl = TextEditingController(text: '50');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final svc = context.watch<DataService>();
    final insights = svc.adminRestockInsights;

    return Scaffold(
      appBar: AppBar(title: const Text('Production & Distribution')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Production Section
            const SectionHeader(title: '1. Log New Production Batch'),
            const SizedBox(height: 6),
            Text('Add fresh batches to central Admin stock',
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _prodProductId,
                      dropdownColor: theme.cardTheme.color,
                      decoration: const InputDecoration(labelText: 'Product / Flavor'),
                      items: svc.products
                          .map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text('${p.flavor} (${p.name})',
                                  style: theme.textTheme.bodyMedium)))
                          .toList(),
                      onChanged: (v) => setState(() => _prodProductId = v),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _prodQtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantity Produced (Packs)'),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _prodProductId == null
                            ? null
                            : () => _submitLogProduction(context, svc),
                        icon: const Icon(Icons.add_task_rounded),
                        label: const Text('LOG PRODUCTION'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGold),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 36),

            // 2. Distribution Section
            const SectionHeader(title: '2. Transfer Stock to Branch'),
            const SizedBox(height: 6),
            Text('Move stock from Admin warehouse to specific branches',
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedProductId,
                      dropdownColor: theme.cardTheme.color,
                      decoration: const InputDecoration(labelText: 'Product to Transfer'),
                      items: svc.products
                          .map((p) => DropdownMenuItem(
                              value: p.id,
                              child: Text('${p.flavor} (Avail: ${p.adminStock})',
                                  style: theme.textTheme.bodyMedium)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedProductId = v),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedBranchId,
                      dropdownColor: theme.cardTheme.color,
                      decoration: const InputDecoration(labelText: 'Target Branch'),
                      items: svc.branches
                          .map((b) => DropdownMenuItem(
                              value: b.id,
                              child: Text(b.name, style: theme.textTheme.bodyMedium)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedBranchId = v),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _distQtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Transfer Quantity'),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (_selectedBranchId == null || _selectedProductId == null)
                            ? null
                            : () => _submitDistribution(context, svc),
                        icon: const Icon(Icons.local_shipping_rounded),
                        label: const Text('CONFIRM TRANSFER'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 36),
            const SectionHeader(title: 'Production Planning Insights'),
            const SizedBox(height: 6),
            Text('Based on branch sales and predictive analytics',
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 20),
            if (insights.isEmpty)
              const EmptyState(icon: Icons.analytics_outlined, message: 'No urgent production needs detected')
            else
              ...insights.map((insight) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(insight['productName'],
                                    style: theme.textTheme.titleSmall),
                                const SizedBox(height: 4),
                                Text('Needed for ${insight['branchName']}',
                                    style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('+${insight['suggested']}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                      color: AppTheme.success, fontWeight: FontWeight.w900)),
                              Text(insight['urgency'],
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: insight['urgency'] == 'Urgent' ? AppTheme.error : AppTheme.warning,
                                    fontWeight: FontWeight.w800,
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Future<void> _submitLogProduction(BuildContext context, DataService svc) async {
    final qty = int.tryParse(_prodQtyCtrl.text) ?? 0;
    if (qty <= 0) return;

    await svc.logProduction(_prodProductId!, qty);

    if (!context.mounted) return;
    showSnack(context, 'Production logged to central Admin stock!');
    setState(() {
      _prodQtyCtrl.text = '100';
    });
  }

  Future<void> _submitDistribution(BuildContext context, DataService svc) async {
    final qty = int.tryParse(_distQtyCtrl.text) ?? 0;
    if (qty <= 0) return;

    try {
      await svc.addProductionStock(_selectedBranchId!, _selectedProductId!, qty);
      if (!context.mounted) return;
      showSnack(context, 'Stock transferred to branch successfully!');
      setState(() {
        _distQtyCtrl.text = '50';
      });
    } catch (e) {
      if (!context.mounted) return;
      showSnack(context, e.toString().replaceAll('Exception: ', ''), error: true);
    }
  }
}
