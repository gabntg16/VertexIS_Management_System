import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_service.dart';
import '../utils/theme.dart';

class GlobalActionToolbar extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  
  const GlobalActionToolbar({super.key, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<DataService>();
    if (svc.currentUser == null) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(3), // Reduced padding
        decoration: BoxDecoration(
          color: const Color(0xFF000000), // Pure black capsule
          borderRadius: BorderRadius.circular(12), // Slightly smaller radius
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: _ToolbarButton(
          icon: Icons.notifications_none_rounded,
          badge: svc.pendingOrdersCount > 0 ? svc.pendingOrdersCount.toString() : null,
          onPressed: () => _showNotifications(context, svc),
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context, DataService svc) {
    final theme = Theme.of(context);
    final isAdmin = svc.currentUser?.isAdmin ?? false;
    
    final pendingApprovals = svc.pendingOrdersCount;
    final upcomingEvents = svc.events
        .where((e) =>
            e.date.isAfter(DateTime.now()) &&
            e.date.isBefore(DateTime.now().add(const Duration(days: 7))))
        .toList();

    showModalBottomSheet(
      context: navigatorKey.currentContext!,
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
              Text('System Notifications', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('Tap a task to go there directly.', 
                style: TextStyle(fontSize: 12, color: Colors.white38)),
              const SizedBox(height: 16),
              
              if (pendingApprovals > 0)
                _notifItem(
                    icon: Icons.pending_actions_rounded,
                    color: AppTheme.warning,
                    title: '$pendingApprovals pending approval(s)',
                    sub: 'Orders waiting for review in the system.',
                    theme: theme,
                    onTap: () {
                      Navigator.pop(ctx);
                      if (isAdmin) {
                        svc.setAdminTab(1); // Go to Orders tab in Admin
                      } else {
                        svc.setBranchTab(1); // Go to Orders tab in Branch
                      }
                    }),
              
              if (upcomingEvents.isNotEmpty)
                _notifItem(
                    icon: Icons.event_available_outlined,
                    color: AppTheme.accent,
                    title: '${upcomingEvents.length} upcoming event(s)',
                    sub: 'Important tasks scheduled for this week.',
                    theme: theme,
                    onTap: () {
                      Navigator.pop(ctx);
                      if (isAdmin) {
                        svc.setAdminTab(6); // Admin Calendar index
                      } else {
                        svc.setBranchTab(4); // Branch Calendar index
                      }
                    }),

              if (pendingApprovals == 0 && upcomingEvents.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text('All caught up! No new notifications.'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _notifItem({
    required IconData icon, 
    required Color color, 
    required String title, 
    required String sub,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.white24),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? badge;

  const _ToolbarButton({
    required this.icon,
    required this.onPressed,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: const Color(0xFF1C1C1E), // Dark square tile
          borderRadius: BorderRadius.circular(10), // Reduced radius
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 36, // Reduced size (from 48)
              height: 36,
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 18, // Reduced icon size (from 24)
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            top: -3, // Adjusted for smaller button
            right: -3,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935), // Red badge
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8, // Smaller text
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
