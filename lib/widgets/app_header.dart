import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/app_state.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key, required this.state, required this.onNotifications});
  final AppState state;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).colorScheme.onSurface;
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      child: SizedBox(
        height: 60,
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(9), child: Image.asset('assets/branding/icon.png', width: 34, height: 34, fit: BoxFit.cover)),
          const SizedBox(width: 9),
          Expanded(child: Text.rich(
            TextSpan(children: [TextSpan(text: 'Faso', style: AppTypography.display(size: 18, weight: FontWeight.w900)), TextSpan(text: 'biblio', style: AppTypography.display(size: 18, weight: FontWeight.w900, color: AppColors.blue))]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: text),
          )),
          IconButton(
            onPressed: onNotifications,
            tooltip: 'Notifications',
            icon: Badge(
              isLabelVisible: state.unreadNotifications > 0,
              label: Text(state.unreadNotifications > 99 ? '99+' : '${state.unreadNotifications}'),
              child: const Icon(Icons.notifications_none_rounded, size: 24),
            ),
          ),
        ]),
        ),
      ),
    );
  }
}
