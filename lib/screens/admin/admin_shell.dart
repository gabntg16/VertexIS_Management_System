// lib/screens/admin/admin_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/data_service.dart';
import '../../utils/theme.dart';
import 'admin_dashboard.dart';
import 'admin_orders.dart';
import 'admin_branches.dart';
import 'admin_menu.dart';
import 'admin_production.dart';
import 'admin_announcements.dart';
import 'admin_calendar.dart';
import 'admin_history.dart';
import '../settings_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  final List<Widget> _pages = const [
    AdminDashboard(),
    AdminOrders(),
    AdminProduction(),
    AdminBranches(),
    AdminMenu(),
    AdminAnnouncements(),
    AdminCalendar(),
    AdminHistory(),
    SettingsScreen(),
  ];

  final List<NavigationRailDestination> _railItems = const [
    NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard_rounded),
      label: Text('Dashboard'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.receipt_long_outlined),
      selectedIcon: Icon(Icons.receipt_long_rounded),
      label: Text('Orders'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.factory_outlined),
      selectedIcon: Icon(Icons.factory_rounded),
      label: Text('Production'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.store_outlined),
      selectedIcon: Icon(Icons.store_rounded),
      label: Text('Branches'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book_rounded),
      label: Text('Menu'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.campaign_outlined),
      selectedIcon: Icon(Icons.campaign_rounded),
      label: Text('Announcements'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.calendar_month_outlined),
      selectedIcon: Icon(Icons.calendar_month_rounded),
      label: Text('Calendar'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.history_outlined),
      selectedIcon: Icon(Icons.history_rounded),
      label: Text('History'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings_rounded),
      label: Text('Settings'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final svc = context.watch<DataService>();
    final isWide = MediaQuery.of(context).size.width > 700;
    final idx = svc.adminTabIndex;

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: theme.scaffoldBackgroundColor,
              selectedIndex: idx,
              onDestinationSelected: (i) => svc.setAdminTab(i),
              extended: MediaQuery.of(context).size.width > 1000,
              indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              selectedIconTheme:
                  IconThemeData(color: theme.colorScheme.primary),
              selectedLabelTextStyle: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
              unselectedIconTheme: IconThemeData(color: theme.disabledColor),
              unselectedLabelTextStyle: TextStyle(color: theme.disabledColor),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Hero(
                  tag: 'logo',
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        'assets/images/marshbites_logo.jpg',
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.account_tree_rounded,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              destinations: _railItems,
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: IndexedStack(
                index: idx,
                children: _pages,
              ),
            ),
          ],
        ),
      );
    }

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
          onDestinationSelected: (i) => svc.setAdminTab(i),
          indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: Icon(Icons.factory_outlined),
              selectedIcon: Icon(Icons.factory_rounded),
              label: 'Production',
            ),
            NavigationDestination(
              icon: Icon(Icons.store_outlined),
              selectedIcon: Icon(Icons.store_rounded),
              label: 'Branches',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book_rounded),
              label: 'Menu',
            ),
            NavigationDestination(
              icon: Icon(Icons.campaign_outlined),
              selectedIcon: Icon(Icons.campaign_rounded),
              label: 'Announce',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded),
              label: 'Calendar',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history_rounded),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
