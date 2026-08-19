// lib/screens/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/data_service.dart';
import '../../models/models.dart';
import '../../utils/theme.dart';
import '../../widgets/shared_widgets.dart';
import 'admin_calendar.dart';
import 'admin_history.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<DataService>();
    final theme = Theme.of(context);
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good ${_greeting()},',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            'Admin Dashboard',
                            style: theme.textTheme.displaySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Stats grid
                  GridView.count(
                    crossAxisCount: isDesktop ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isDesktop ? 2.0 : 1.2,
                    children: [
                      StatCard(
                        label: 'Total Branches',
                        value: svc.totalBranches.toString(),
                        icon: Icons.store_rounded,
                        color: AppTheme.accent,
                      ),
                      StatCard(
                        label: 'Pending Approvals',
                        value: svc.pendingOrdersCount.toString(),
                        icon: Icons.pending_actions_rounded,
                        color: AppTheme.warning,
                      ),
                      StatCard(
                        label: 'Total Revenue',
                        value:
                            '₱${NumberFormat('#,##0').format(svc.totalRevenue)}',
                        icon: Icons.payments_rounded,
                        color: AppTheme.success,
                      ),
                      StatCard(
                        label: 'Products',
                        value: svc.totalProducts.toString(),
                        icon: Icons.inventory_2_rounded,
                        color: AppTheme.accentGold,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const SectionHeader(title: 'Top Branch Performance'),
                  const SizedBox(height: 16),
                  if (svc.branches.isEmpty)
                    const EmptyState(
                        icon: Icons.store_outlined,
                        message: 'No branches available')
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: svc.topBranchesByRevenue
                            .take(3)
                            .map((branch) => Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: _BranchPerformanceCard(
                                      branch: branch, svc: svc),
                                ))
                            .toList(),
                      ),
                    ),
                  const SizedBox(height: 32),
                  const SectionHeader(title: 'System Perks'),
                  const SizedBox(height: 16),
                  _buildPerkCard(theme, svc),
                  const SizedBox(height: 32),

                  // Production Restock Insights
                  const SectionHeader(title: 'Global Production Insights'),
                  const SizedBox(height: 16),
                  if (svc.adminRestockInsights.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                            'All branches are currently well-stocked based on sales trends.',
                            style: TextStyle(fontSize: 13)),
                      ),
                    )
                  else
                    ...svc.adminRestockInsights.take(5).map((insight) {
                      return _buildInsightItem(theme, insight);
                    }),
                  const SizedBox(height: 32),

                  // Recent Orders
                  const SectionHeader(title: 'Recent Orders'),
                  const SizedBox(height: 16),
                  ...svc.allOrders.take(5).map((o) => OrderCard(order: o)),
                  if (svc.allOrders.isEmpty)
                    const EmptyState(
                        icon: Icons.receipt_long_outlined,
                        message: 'No orders yet'),

                  const SizedBox(height: 32),

                  // Sales by branch bar chart
                  _SalesByBranchChart(svc: svc),

                  const SizedBox(height: 32),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AdminHistory()),
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

  Widget _buildPerkCard(ThemeData theme, DataService svc) {
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
              const Icon(Icons.auto_graph_rounded,
                  color: Color(0xFF80C7F2), size: 28),
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
          Text(svc.overallDemandForecast,
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFF4CAF50),
                fontWeight: FontWeight.w900,
              )),
          const SizedBox(height: 12),
          Text(
              'Gathers data across all branches to forecast upcoming demand trends.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white54,
              )),
        ],
      ),
    );
  }

  Widget _buildInsightItem(ThemeData theme, Map<String, dynamic> insight) {
    return Card(
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
                  Text('Needed for: ${insight['branchName']}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.accentOrange,
                      )),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Produce ${insight['suggested']}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppTheme.success,
                    )),
                const SizedBox(height: 4),
                Text(insight['urgency'], style: theme.textTheme.labelSmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Morning';
    if (h < 17) return 'Afternoon';
    return 'Evening';
  }

  // ignore: unused_element
  void _showNotifications(BuildContext context, DataService svc) {
    final theme = Theme.of(context);
    final pendingApprovals = svc.pendingOrdersCount;
    final upcomingEvents = svc.events
        .where((e) =>
            e.date.isAfter(DateTime.now()) &&
            e.date.isBefore(DateTime.now().add(const Duration(days: 7))))
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
              const SizedBox(height: 20),
              Text('Notifications', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              if (pendingApprovals > 0)
                _notifItem(
                    Icons.pending_actions_rounded,
                    AppTheme.warning,
                    '$pendingApprovals pending order approval(s)',
                    'Review customer submissions from branches.',
                    theme),
              if (upcomingEvents.isNotEmpty)
                _notifItem(
                    Icons.event_available_outlined,
                    AppTheme.accent,
                    '${upcomingEvents.length} upcoming event(s)',
                    'Events happening in the next 7 days.',
                    theme),
              if (pendingApprovals == 0 && upcomingEvents.isEmpty)
                const EmptyState(
                    icon: Icons.notifications_none_rounded,
                    message: 'No new notifications'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AdminCalendar()));
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: const Text('OPEN CALENDAR'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _notifItem(
      IconData icon, Color color, String title, String sub, ThemeData theme) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: theme.textTheme.titleSmall),
      subtitle: Text(sub, style: theme.textTheme.bodySmall),
    );
  }
}

class _BranchPerformanceCard extends StatelessWidget {
  final Branch branch;
  final DataService svc;
  const _BranchPerformanceCard({required this.branch, required this.svc});

  Color _forecastColor(String forecast) {
    if (forecast == 'High demand') return AppTheme.error;
    if (forecast == 'Growing demand') return AppTheme.accent;
    return AppTheme.success;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final revenue = svc.branchRevenue(branch.id);
    final pending = svc.branchPendingApprovals(branch.id);
    final stock = svc.branchStockCount(branch.id);
    final forecast = svc.demandForecastForBranch(branch.id);

    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.store_rounded,
                    color: AppTheme.accentOrange, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(branch.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        )),
                    Text(branch.location,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white54,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Total Revenue',
              style:
                  theme.textTheme.labelSmall?.copyWith(color: Colors.white38)),
          const SizedBox(height: 4),
          Text('₱${NumberFormat('#,##0').format(revenue)}',
              style: theme.textTheme.displaySmall?.copyWith(
                color: const Color(0xFF4CAF50), // Bright green like screenshot
                fontWeight: FontWeight.w900,
                fontSize: 32,
              )),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _summaryChip('$pending pending', AppTheme.warning),
              _summaryChip('$stock stock', AppTheme.accentGold),
              _summaryChip(forecast, _forecastColor(forecast)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w800)),
      );
}

class _SalesByBranchChart extends StatelessWidget {
  final DataService svc;
  const _SalesByBranchChart({required this.svc});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final branches = svc.branches;
    final data = branches.map((b) {
      final total =
          svc.getSalesForBranch(b.id).fold(0.0, (s, e) => s + e.total);
      return MapEntry(b.name.replaceAll('Branch ', ''), total);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sales Performance by Branch',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 5000,
                  getDrawingHorizontalLine: (_) => FlLine(
                      color: theme.dividerColor.withValues(alpha: 0.5),
                      strokeWidth: 1),
                  drawVerticalLine: false,
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (v, _) => Text(
                        '₱${(v / 1000).toStringAsFixed(0)}k',
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx >= data.length) return const SizedBox();
                        String name = data[idx].key;
                        if (name.startsWith('Marsh Bites ')) {
                          name = name.replaceAll('Marsh Bites ', '');
                        }
                        if (name.length > 8) {
                          name = '${name.substring(0, 7)}..';
                        }
                        return SideTitleWidget(
                          axisSide: AxisSide.bottom,
                          space: 8,
                          child: Text(name, style: theme.textTheme.labelSmall),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: data.asMap().entries.map((e) {
                  return BarChartGroupData(x: e.key, barRods: [
                    BarChartRodData(
                      toY: e.value.value,
                      color: [
                        AppTheme.accent,
                        AppTheme.success,
                        AppTheme.accentGold
                      ][e.key % 3],
                      width: 24,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
