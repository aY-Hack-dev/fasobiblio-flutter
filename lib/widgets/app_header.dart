import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/app_state.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key, required this.state, required this.onNotifications});
  final AppState state;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final unread = state.unreadNotifications;
    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: .32), width: .7)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(children: [
          Expanded(child: RichText(maxLines: 1, overflow: TextOverflow.ellipsis, text: TextSpan(children: [
            TextSpan(text: 'FASO', style: AppTypography.display(size: 22, weight: FontWeight.w900, color: dark ? Colors.white : AppColors.ink).copyWith(letterSpacing: .2)),
            TextSpan(text: 'BIBLIO', style: AppTypography.display(size: 22, weight: FontWeight.w900, color: AppColors.blueDeep).copyWith(letterSpacing: .2)),
          ]))),
          Stack(clipBehavior: Clip.none, children: [
            IconButton(onPressed: onNotifications, tooltip: 'Notifications', visualDensity: VisualDensity.compact, icon: Icon(AppIcons.bell, size: 23, color: dark ? Colors.white : AppColors.ink)),
            if (unread > 0) Positioned(
              right: 1,
              top: 1,
              child: Container(
                constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: const Color(0xFFE5484D), borderRadius: BorderRadius.circular(99), border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 1.5)),
                child: Text(unread > 99 ? '99+' : '$unread', style: const TextStyle(fontSize: 8, height: 1, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
