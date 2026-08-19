// lib/screens/branch/branch_inventory.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/data_service.dart';
import '../../utils/theme.dart';
import '../../widgets/shared_widgets.dart';

class BranchInventory extends StatelessWidget {
  const BranchInventory({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final svc = context.watch<DataService>();
    final inventory = svc.branchInventory;
    final restockSuggestions = svc.branchRestockSuggestions;

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: inventory.isEmpty
          ? const EmptyState(
              icon: Icons.inventory_2_outlined, message: 'No inventory items')
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (restockSuggestions.isNotEmpty) ...[
                  Card(
                    color: theme.colorScheme.primary.withValues(alpha: 0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary, size: 20),
                              const SizedBox(width: 10),
                              Text('Auto Restocking Suggestions',
                                  style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ...restockSuggestions.take(3).map((suggestion) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.cardTheme.color,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(suggestion.productName,
                                            style: theme.textTheme.titleSmall?.copyWith(fontSize: 13)),
                                        const SizedBox(height: 4),
                                        Text(
                                            'Order ${suggestion.suggestedOrderQuantity} packs based on demand',
                                            style: theme.textTheme.bodySmall),
                                      ],
                                    ),
                                  ),
                                  StatusBadge(label: suggestion.urgency, color: AppTheme.accentOrange),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                ...inventory.map((item) {
                  final isLow = item.stock < 10;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: (isLow ? AppTheme.error : AppTheme.success)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.inventory_2_rounded,
                                color: isLow ? AppTheme.error : AppTheme.success,
                                size: 22),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.productName,
                                    style: theme.textTheme.titleSmall),
                                if (isLow)
                                  Text('Low stock alert!',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                          color: AppTheme.error,
                                          fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(item.stock.toString(),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                      color: isLow
                                          ? AppTheme.error
                                          : AppTheme.success,
                                      fontWeight: FontWeight.w900)),
                              Text('packs',
                                  style: theme.textTheme.labelSmall),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}
