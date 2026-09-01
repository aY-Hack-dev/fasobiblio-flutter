import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/app_state.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key, required this.state, required this.onNotifications});
  final AppState state;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final text = Theme.of(context).colorScheme.onSurface;
    return Material(
      color: surface,
      elevation: 0,
      child: Container(
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: .45)))),
        child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(11), child: Image.asset('assets/branding/icon.png', width: 40, height: 40, fit: BoxFit.cover)),
          const SizedBox(width: 10),
          Expanded(child: Text.rich(
            const TextSpan(children: [TextSpan(text: 'Faso', style: TextStyle(fontWeight: FontWeight.w900)), TextSpan(text: 'biblio', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.blue))]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 20, letterSpacing: -.4, color: text),
          )),
          IconButton(
            onPressed: onNotifications,
            tooltip: 'Notifications',
            icon: Badge(
              isLabelVisible: state.unreadNotifications > 0,
              label: Text(state.unreadNotifications > 99 ? '99+' : '${state.unreadNotifications}'),
              child: const Icon(Icons.notifications_none_rounded, size: 27),
            ),
          ),
        ]),
      ),
    );
  }
}
