import 'package:flutter/material.dart';
import '../core/app_feedback.dart';
import '../core/theme.dart';
import '../models/app_notification.dart';
import '../services/app_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, required this.state});
  final AppState state;

  Future<void> markAll(BuildContext context) async {
    try {
      await state.markAllNotificationsRead();
      if (context.mounted) showToast(context, 'Toutes les notifications ont été marquées comme lues.', success: true);
    } catch (error) {
      if (context.mounted) showToast(context, friendlyFailure(error, action: 'mettre à jour les notifications'));
    }
  }

  Future<void> open(BuildContext context, AppNotification item) async {
    if (!state.notificationReads.contains(item.id)) {
      try { await state.markNotificationRead(item.id); } catch (_) {}
    }
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(22, 4, 22, 28), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const CircleAvatar(backgroundColor: AppColors.sky, foregroundColor: AppColors.blue, child: Icon(AppIcons.bell)), const SizedBox(width: 12), Expanded(child: Text(item.title, style: Theme.of(context).textTheme.titleLarge))]),
        const SizedBox(height: 18),
        Text(item.message, style: const TextStyle(fontSize: 15, height: 1.6)),
        const SizedBox(height: 18),
        Text(_date(item.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      ]))),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Notifications'),
      actions: [if (state.unreadNotifications > 0) TextButton(onPressed: () => markAll(context), child: const Text('Tout lire'))],
    ),
    body: state.notifications.isEmpty
      ? const Center(child: Padding(padding: EdgeInsets.all(30), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(AppIcons.bellOff, size: 52, color: AppColors.muted), SizedBox(height: 14), Text('Aucune notification pour le moment.', style: TextStyle(fontWeight: FontWeight.w800)), SizedBox(height: 5), Text('Les annonces envoyées depuis Fasobiblio apparaîtront ici.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted))])))
      : ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
          itemCount: state.notifications.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = state.notifications[index];
            final read = state.notificationReads.contains(item.id);
            return Material(
              color: read ? Theme.of(context).colorScheme.surface : AppColors.sky,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: () => open(context, item),
                borderRadius: BorderRadius.circular(18),
                child: Padding(padding: const EdgeInsets.all(15), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  CircleAvatar(backgroundColor: read ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.white, foregroundColor: AppColors.blue, child: const Icon(AppIcons.bell, size: 20)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [Expanded(child: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900))), if (!read) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle))]),
                    const SizedBox(height: 5),
                    Text(item.message, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, height: 1.4, color: AppColors.muted)),
                    const SizedBox(height: 7),
                    Text(_date(item.createdAt), style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                  ])),
                ])),
              ),
            );
          },
        ),
  );

  static String _date(int milliseconds) {
    if (milliseconds <= 0) return '';
    final value = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} • ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}
