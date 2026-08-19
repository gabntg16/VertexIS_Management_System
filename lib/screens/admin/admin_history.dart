// lib/screens/admin/admin_history.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/data_service.dart';
import '../../models/models.dart';
import '../../utils/theme.dart';
import '../../widgets/shared_widgets.dart';

class AdminHistory extends StatefulWidget {
  const AdminHistory({super.key});

  @override
  State<AdminHistory> createState() => _AdminHistoryState();
}

class _AdminHistoryState extends State<AdminHistory> {
  String _activeFilter = 'All';
  String? _selectedBranchId;
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
    final branches = svc.branches;
    final allOrders = svc.allOrders;
    final allSales = svc.sales;

    // 1. Filter by Branch
    final branchFilteredSales = allSales.where((s) {
      return _selectedBranchId == null || s.branchId == _selectedBranchId;
    }).toList();

    final branchFilteredOrders = allOrders.where((o) {
      return _selectedBranchId == null || o.branchId == _selectedBranchId;
    }).toList();

    // 2. Filter by Status/Type
    final finalOrders = branchFilteredOrders.where((o) {
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
      appBar: AppBar(
        title: const Text('Global Transaction History'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Branch Dropdown Filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _selectedBranchId,
                    isExpanded: true,
                    hint: Text("All Branches",
                        style: theme.textTheme.bodyMedium),
                    dropdownColor: theme.cardTheme.color,
                    icon: Icon(Icons.filter_list_rounded,
                        color: theme.colorScheme.primary),
                    style: theme.textTheme.bodyLarge,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text("All Branches"),
                      ),
                      ...branches.map((b) => DropdownMenuItem<String?>(
                            value: b.id,
                            child: Text(b.name),
                          )),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedBranchId = val);
                    },
                  ),
                ),
              ),
            ),
          ),
          // Status Filter Bar
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
                    if (branchFilteredSales.isNotEmpty) ...[
                      const SectionHeader(title: 'Sales History'),
                      const SizedBox(height: 12),
                      ...branchFilteredSales
                          .take(20)
                          .map((s) => _AdminHistorySaleItem(sale: s)),
                      const SizedBox(height: 24),
                    ] else if (_activeFilter == 'Sales')
                      const EmptyState(
                        icon: Icons.bar_chart_outlined,
                        message: 'No sales found for this branch',
                      ),
                  ],

                  // Filtered Orders
                  if (_activeFilter != 'Sales') ...[
                    if (finalOrders.isNotEmpty) ...[
                      const SectionHeader(title: 'Order History'),
                      const SizedBox(height: 12),
                      ...finalOrders.map((o) => OrderHistoryCard(order: o)),
                      const SizedBox(height: 24),
                    ]
                  ],

                  // Overall Empty State
                  if (_activeFilter != 'All' &&
                      _activeFilter != 'Sales' &&
                      finalOrders.isEmpty)
                    const EmptyState(
                      icon: Icons.history_rounded,
                      message: 'No transactions found for these filters',
                    ),

                  if (_activeFilter == 'All' &&
                      branchFilteredSales.isEmpty &&
                      finalOrders.isEmpty)
                    const EmptyState(
                      icon: Icons.history_rounded,
                      message: 'No transactions found for this branch',
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

class _AdminHistorySaleItem extends StatelessWidget {
  final Sale sale;
  const _AdminHistorySaleItem({required this.sale});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final svc = context.read<DataService>();
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sale.productName,
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    '${sale.quantity} units • ${svc.getBranch(sale.branchId)?.name ?? sale.branchId}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    DateFormat('MMM d, yyyy h:mm a').format(sale.date),
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
