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
    final foreground = dark ? Colors.white : AppColors.ink;

    return Material(
      color: dark ? const Color(0xFF101827) : Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      child: SizedBox(
        height: 58,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'FASOBIBLIO',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display(
                    size: 19,
                    weight: FontWeight.w900,
                    color: foreground,
                  ).copyWith(letterSpacing: .2),
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: onNotifications,
                    tooltip: 'Notifications',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(AppIcons.bell, size: 22, color: foreground),
                  ),
                  if (state.unreadNotifications > 0)
                    const Positioned(
                      right: 6,
                      top: 5,
                      child: SizedBox(
                        width: 8,
                        height: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: Color(0xFFE5484D), shape: BoxShape.circle),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
