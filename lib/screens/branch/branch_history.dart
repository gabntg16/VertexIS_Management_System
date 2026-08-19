// lib/screens/branch/branch_history.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/data_service.dart';
import '../../models/models.dart';
import '../../utils/theme.dart';
import '../../widgets/shared_widgets.dart';

class BranchHistory extends StatefulWidget {
  const BranchHistory({super.key});

  @override
  State<BranchHistory> createState() => _BranchHistoryState();
}

class _BranchHistoryState extends State<BranchHistory> {
  String _activeFilter = 'All';
  final List<String> _filters = [
    'All',
    'Sales',
    'Pending',
    'Waiting Approval',
    'Approved',
    'Rejected'
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final svc = context.watch<DataService>();
    final orders = svc.branchOrders;
    final sales = svc.branchSales;

    final filteredOrders = orders.where((o) {
      if (_activeFilter == 'All') return true;
      if (_activeFilter == 'Pending') return o.status == OrderStatus.pending;
      if (_activeFilter == 'Waiting Approval') {
        return o.status == OrderStatus.waitingApproval;
      }
      if (_activeFilter == 'Approved') return o.status == OrderStatus.approved;
      if (_activeFilter == 'Rejected') return o.status == OrderStatus.rejected;
      return false;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction History')),
      body: Column(
        children: [
          // Filter Bar
          Container(
            height: 60,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _activeFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _activeFilter = filter);
                    },
                    selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                    backgroundColor: theme.cardTheme.color,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodyMedium?.color,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w500,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.dividerColor.withValues(alpha: 0.1),
                      ),
                    ),
                    showCheckmark: false,
                    elevation: 0,
                    pressElevation: 0,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filtered Sales
                  if (_activeFilter == 'All' || _activeFilter == 'Sales') ...[
                    if (sales.isNotEmpty) ...[
                      const SectionHeader(title: 'Sales History'),
                      const SizedBox(height: 12),
                      ...sales.take(20).map((s) => _HistorySaleItem(sale: s)),
                      const SizedBox(height: 24),
                    ] else if (_activeFilter == 'Sales')
                      const EmptyState(
                        icon: Icons.bar_chart_outlined,
                        message: 'No sales found',
                      ),
                  ],

                  // Filtered Orders
                  if (_activeFilter != 'Sales') ...[
                    if (filteredOrders.isNotEmpty) ...[
                      const SectionHeader(title: 'Order History'),
                      const SizedBox(height: 12),
                      ...filteredOrders.map((o) => OrderHistoryCard(order: o)),
                      const SizedBox(height: 24),
                    ]
                  ],

                  // Overall Empty State
                  if (_activeFilter != 'All' &&
                      _activeFilter != 'Sales' &&
                      filteredOrders.isEmpty)
                    const EmptyState(
                      icon: Icons.history_rounded,
                      message: 'No transactions match this status',
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistorySaleItem extends StatelessWidget {
  final Sale sale;
  const _HistorySaleItem({required this.sale});

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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.point_of_sale_rounded,
                  color: AppTheme.success, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sale.productName,
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    '${sale.quantity} units • ${DateFormat('MMM d, yyyy h:mm a').format(sale.date)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              '₱${NumberFormat('#,##0.00').format(sale.total)}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.success,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
