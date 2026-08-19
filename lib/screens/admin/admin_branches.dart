// lib/screens/admin/admin_branches.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/data_service.dart';
import '../../utils/theme.dart';
import '../../widgets/shared_widgets.dart';

class AdminBranches extends StatelessWidget {
  const AdminBranches({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final svc = context.watch<DataService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Branches')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin_branches_fab',
        onPressed: () => _showAddBranchDialog(context, svc),
        icon: const Icon(Icons.add_rounded),
        label: const Text('ADD BRANCH'),
      ),
      body: svc.branches.isEmpty
          ? const EmptyState(
              icon: Icons.store_outlined, message: 'No branches yet')
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: svc.branches.length,
              itemBuilder: (_, i) {
                final b = svc.branches[i];
                final orders = svc.getOrdersForBranch(b.id);
                final sales = svc.getSalesForBranch(b.id);
                final totalSales = sales.fold(0.0, (s, e) => s + e.total);
                final forecast = svc.demandForecastForBranch(b.id);
                final manager = svc.users.firstWhere(
                  (u) => u.branchId == b.id,
                  orElse: () => UserModel(
                    id: 'unknown',
                    name: 'Manager',
                    email: 'not.assigned@marshbites.com',
                    password: '',
                    role: 'branch',
                    branchId: b.id,
                  ),
                );

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
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.store_rounded,
                                  color: theme.colorScheme.primary, size: 22),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(b.name,
                                      style: theme.textTheme.titleMedium),
                                  Text(b.location,
                                      style: theme.textTheme.labelSmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(height: 1),
                        ),
                        Text('Branch Manager',
                            style: theme.textTheme.labelSmall),
                        const SizedBox(height: 6),
                        Text(manager.email, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _statChip(theme, '${orders.length} orders',
                                AppTheme.pending),
                            _statChip(
                                theme,
                                '₱${NumberFormat('#,##0').format(totalSales)} sales',
                                AppTheme.success),
                            _statChip(
                                theme, forecast, _forecastColor(forecast)),
                            _statChip(
                                theme,
                                '₱${NumberFormat('#,##0').format(svc.weeklyDemandAmountForBranch(b.id))} forecast',
                                AppTheme.accentOrange),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showAddBranchDialog(
      BuildContext context, DataService svc) async {
    final theme = Theme.of(context);
    final nameCtrl = TextEditingController();
    final locationCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New Branch'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Branch Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: locationCtrl,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: theme.disabledColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty ||
                  locationCtrl.text.trim().isEmpty) {
                return;
              }
              await svc.addBranch(nameCtrl.text, locationCtrl.text);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                if (context.mounted) {
                  showSnack(context,
                      'Branch added with manager account ${svc.users.last.email}');
                }
              }
            },
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }

  Widget _statChip(ThemeData theme, String label, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)));

  Color _forecastColor(String forecast) {
    if (forecast == 'High demand') return AppTheme.error;
    if (forecast == 'Growing demand') return AppTheme.accentOrange;
    if (forecast == 'Stable demand') return AppTheme.success;
    return AppTheme.textSecondary;
  }
}
