import 'package:flutter/material.dart';
import '../core/app_feedback.dart';
import '../core/theme.dart';
import '../models/app_notification.dart';
import '../services/app_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.state});
  final AppState state;
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _unreadOnly = false;
  bool _marking = false;
  AppState get state => widget.state;

  Future<void> _markAll() async {
    if (_marking) return;
    setState(() => _marking = true);
    try {
      await state.markAllNotificationsRead();
      if (mounted) showToast(context, 'Toutes les notifications sont marquées comme lues.', success: true);
    } catch (error) {
      if (mounted) showToast(context, friendlyFailure(error, action: 'synchroniser les notifications'));
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }

  Future<void> _open(AppNotification item) async {
    if (!state.notificationReads.contains(item.id)) {
      try { await state.markNotificationRead(item.id); } catch (error) {
        if (mounted) showToast(context, friendlyFailure(error, action: 'synchroniser la lecture'));
      }
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context, showDragHandle: true, isScrollControlled: true, useSafeArea: true,
      builder: (context) => SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(_icon(item), color: Theme.of(context).colorScheme.primary, size: 28),
          const SizedBox(height: 14),
          Text(item.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(_date(item.createdAt), style: const TextStyle(fontSize:12, color: AppColors.muted)),
          const SizedBox(height: 20),
          SelectableText(item.message, style: const TextStyle(fontSize: 15, height: 1.6)),
        ]),
      )),
    );
  }

  String _period(int timestamp) {
    if (timestamp <= 0) return 'Autres annonces';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (!date.isBefore(today)) return 'Aujourd’hui';
    if (!date.isBefore(DateTime(now.year, now.month, now.day - 1))) return 'Hier';
    if (!date.isBefore(DateTime(now.year, now.month, now.day - 6))) return 'Ces 7 derniers jours';
    return 'Plus anciennes';
  }

  IconData _icon(AppNotification item) {
    final value = item.icon.toLowerCase();
    if (value.contains('book') || value.contains('file')) return AppIcons.fileText;
    if (value.contains('crown') || value.contains('star')) return Icons.workspace_premium_outlined;
    if (value.contains('wrench') || value.contains('tools') || value.contains('gear')) return Icons.build_outlined;
    if (value.contains('gift') || value.contains('tag') || value.contains('bullhorn')) return Icons.campaign_outlined;
    return AppIcons.bell;
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: state,
    builder: (context, _) {
      final items = state.notifications.where((item) => !_unreadOnly || !state.notificationReads.contains(item.id)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final colors = Theme.of(context).colorScheme;
      return Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(title: const Text('Notifications'), actions: [
          if (_marking) const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          else if (state.unreadNotifications > 0) PopupMenuButton<String>(
            tooltip: 'Actions',
            onSelected: (_) => _markAll(),
            itemBuilder: (_) => [const PopupMenuItem(value: 'read', child: Text('Tout marquer comme lu'))],
          ),
        ]),
        body: Column(children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), child: Row(children: [
            ChoiceChip(label: const Text('Toutes'), selected: !_unreadOnly, onSelected: (_) => setState(() => _unreadOnly = false)),
            const SizedBox(width: 8),
            Flexible(child: ChoiceChip(label: Text('Non lues (${state.unreadNotifications})'), selected: _unreadOnly, onSelected: (_) => setState(() => _unreadOnly = true))),
          ])),
          Expanded(child: items.isEmpty
            ? Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(AppIcons.bellOff, size: 42, color: colors.primary),
                const SizedBox(height: 16),
                Text(_unreadOnly ? 'Vous êtes à jour !' : 'Aucune notification', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(_unreadOnly ? 'Vous avez lu toutes vos notifications.' : 'Les nouvelles annonces apparaîtront ici.', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
              ])))
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final read = state.notificationReads.contains(item.id);
                  final period = _period(item.createdAt);
                  final showHeading = index == 0 || _period(items[index - 1].createdAt) != period;
                  return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    if (showHeading) Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                      child: Text(period, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.muted))),
                    Material(
                      color: read ? colors.surface : colors.primary.withValues(alpha: .055),
                      child: InkWell(onTap: () => _open(item), child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(width: 38, height: 38, decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: .09), borderRadius: BorderRadius.circular(12)),
                            child: Icon(_icon(item), size: 19, color: colors.primary)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 14, fontWeight: read ? FontWeight.w600 : FontWeight.w800))),
                              if (!read) Padding(padding: const EdgeInsets.only(left: 8), child: Semantics(
                                label: 'Non lue', child: Container(width: 7, height: 7, decoration: BoxDecoration(color: colors.primary, shape: BoxShape.circle)))),
                            ]),
                            const SizedBox(height: 4),
                            Text(item.message, maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, height: 1.45, color: colors.onSurfaceVariant)),
                            const SizedBox(height: 7),
                            Text(_date(item.createdAt), style: const TextStyle(fontSize:12, color: AppColors.muted)),
                          ])),
                        ]),
                      )),
                    ),
                    Divider(height: 1, indent: 70, endIndent: 20, color: colors.outlineVariant.withValues(alpha: .4)),
                  ]);
                },
              )),
        ]),
      );
    },
  );

  static String _date(int milliseconds) {
    if (milliseconds <= 0) return '';
    final value = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} · ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}
