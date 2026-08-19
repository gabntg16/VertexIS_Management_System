// lib/screens/admin/admin_announcements.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/data_service.dart';
import '../../widgets/shared_widgets.dart';

class AdminAnnouncements extends StatelessWidget {
  const AdminAnnouncements({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<DataService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin_announcements_fab',
        onPressed: () => _add(context, svc),
        icon: const Icon(Icons.add_rounded),
        label: const Text('NEW ANNOUNCEMENT'),
      ),
      body: svc.announcements.isEmpty
          ? const EmptyState(
              icon: Icons.campaign_outlined, message: 'No announcements yet')
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: svc.announcements.length,
              itemBuilder: (_, i) => AnnouncementCard(
                announcement: svc.announcements[i],
                showDelete: true,
                onDelete: () => svc.deleteAnnouncement(svc.announcements[i].id),
              ),
            ),
    );
  }

  Future<void> _add(BuildContext context, DataService svc) async {
    final theme = Theme.of(context);
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Announcement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: msgCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                  labelText: 'Message', alignLabelWithHint: true),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  Text('Cancel', style: TextStyle(color: theme.disabledColor))),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isEmpty) return;
              await svc.addAnnouncement(titleCtrl.text, msgCtrl.text);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                if (context.mounted) {
                  showSnack(context, 'Announcement published!');
                }
              }
            },
            child: const Text('PUBLISH'),
          ),
        ],
      ),
    );
  }
}
