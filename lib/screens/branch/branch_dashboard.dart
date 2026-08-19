// lib/screens/branch/branch_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/data_service.dart';
import '../../models/models.dart';
import '../../utils/theme.dart';
import '../../widgets/shared_widgets.dart';
import 'branch_history.dart';

class BranchDashboard extends StatelessWidget {
  const BranchDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<DataService>();
    final theme = Theme.of(context);
    final user = svc.currentUser!;
    final branch = svc.getBranch(user.branchId ?? '');
    final restockSuggestions = svc.branchRestockSuggestions;

    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 700;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Welcome back,',
                                style: theme.textTheme.bodySmall),
                            Text(user.name,
                                style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900)),
                            if (branch != null)
                              Text(branch.location,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppTheme.accentOrange,
                                      fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Stats
                  GridView.count(
                    crossAxisCount: isDesktop ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isDesktop ? 2.2 : 1.3,
                    children: [
                      StatCard(
                        label: 'Total Sales',
                        value:
                            '₱${NumberFormat('#,##0').format(svc.branchTotalSales)}',
                        icon: Icons.payments_rounded,
                        color: AppTheme.success,
                      ),
                      StatCard(
                        label: 'Pending Orders',
                        value: svc.branchPendingOrders.toString(),
                        icon: Icons.pending_actions_rounded,
                        color: AppTheme.warning,
                      ),
                      StatCard(
                        label: 'Total Inventory',
                        value: svc.branchTotalInventory.toString(),
                        icon: Icons.inventory_2_rounded,
                        color: AppTheme.pending,
                      ),
                      StatCard(
                        label: 'Orders',
                        value: svc.branchOrders.length.toString(),
                        icon: Icons.receipt_long_rounded,
                        color: AppTheme.accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const SectionHeader(title: 'Branch Insights'),
                  const SizedBox(height: 16),
                  _buildInsightPerk(theme, svc),
                  const SizedBox(height: 32),
                  const SectionHeader(title: 'Auto Restock Suggestions'),
                  const SizedBox(height: 16),
                  if (restockSuggestions.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                            'Predictive analytics monitors branch sales and inventory to suggest reorder quantities.',
                            style: TextStyle(fontSize: 13)),
                      ),
                    )
                  else
                    ...restockSuggestions.take(3).map((suggestion) {
                      return _buildRestockItem(theme, suggestion);
                    }),
                  const SizedBox(height: 32),

                  // Announcements
                  const SectionHeader(title: 'Announcements'),
                  const SizedBox(height: 16),
                  if (svc.announcements.isEmpty)
                    const EmptyState(
                        icon: Icons.campaign_outlined,
                        message: 'No announcements')
                  else
                    ...svc.announcements
                        .take(3)
                        .map((a) => AnnouncementCard(announcement: a)),

                  const SizedBox(height: 32),
                  const SectionHeader(title: 'Recent Orders'),
                  const SizedBox(height: 16),
                  ...svc.branchOrders.take(3).map((o) => OrderCard(order: o)),
                  if (svc.branchOrders.isEmpty)
                    const EmptyState(
                        icon: Icons.receipt_long_outlined,
                        message: 'No orders yet'),

                  const SizedBox(height: 32),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const BranchHistory()),
                        );
                      },
                      icon: const Icon(Icons.history_rounded,
                          color: AppTheme.accent),
                      label: const Text('View All History',
                          style: TextStyle(
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInsightPerk(ThemeData theme, DataService svc) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_rounded,
                  color: Color(0xFF4CAF50), size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Text('Predictive Demand Analytics',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(svc.branchDemandForecast,
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFF4CAF50),
                fontWeight: FontWeight.w900,
              )),
          const SizedBox(height: 12),
          Text(
              'Forecasts demand trends so your branch can stock smarter and reduce waste.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white54,
              )),
        ],
      ),
    );
  }

  Widget _buildRestockItem(ThemeData theme, RestockSuggestion suggestion) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(suggestion.productName,
                      style: theme.textTheme.titleSmall?.copyWith(color: Colors.white)),
                  const SizedBox(height: 6),
                  Text(
                      'Stock: ${suggestion.currentStock} • Weekly Demand: ${suggestion.expectedWeeklyDemand.toStringAsFixed(0)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.white38)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Order ${suggestion.suggestedOrderQuantity}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF4CAF50),
                      fontWeight: FontWeight.w900,
                    )),
                const SizedBox(height: 4),
                Text(suggestion.urgency, 
                    style: theme.textTheme.labelSmall?.copyWith(color: Colors.white54)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
