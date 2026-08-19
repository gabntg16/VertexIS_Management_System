// lib/screens/branch/branch_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/data_service.dart';
import 'branch_dashboard.dart';
import 'branch_orders.dart';
import 'branch_inventory.dart';
import 'branch_logistics.dart';
import 'branch_calendar.dart';
import 'branch_sales.dart';
import '../settings_screen.dart';

class BranchShell extends StatefulWidget {
  const BranchShell({super.key});

  @override
  State<BranchShell> createState() => _BranchShellState();
}

class _BranchShellState extends State<BranchShell> {
  final _pages = const [
    BranchDashboard(),
    BranchOrders(),
    BranchLogistics(),
    BranchInventory(),
    BranchCalendar(),
    BranchSales(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final svc = context.watch<DataService>();
    final idx = svc.branchTabIndex;

    return Scaffold(
      body: IndexedStack(
        index: idx,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          selectedIndex: idx,
          onDestinationSelected: (i) => svc.setBranchTab(i),
          indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: 'Orders'),
            NavigationDestination(
                icon: Icon(Icons.local_shipping_outlined),
                selectedIcon: Icon(Icons.local_shipping_rounded),
                label: 'Logistics'),
            NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2_rounded),
                label: 'Inventory'),
            NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month_rounded),
                label: 'Calendar'),
            NavigationDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics_rounded),
                label: 'Sales'),
            NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
