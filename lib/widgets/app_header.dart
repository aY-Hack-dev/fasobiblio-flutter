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
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.blueDeep, AppColors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x331860F0),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: SizedBox(
        height: 66,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Color(0x22000000), blurRadius: 12, offset: Offset(0, 5)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset('assets/branding/icon.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: 'FASO',
                        style: AppTypography.display(size: 20, weight: FontWeight.w900, color: Colors.white),
                      ),
                      TextSpan(
                        text: 'BIBLIO',
                        style: AppTypography.display(size: 20, weight: FontWeight.w900, color: const Color(0xFFDCE8FF)),
                      ),
                    ]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Le savoir, partout avec vous',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: .74),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: dark ? .12 : .16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: .18)),
              ),
              child: IconButton(
                onPressed: onNotifications,
                tooltip: 'Notifications',
                color: Colors.white,
                icon: Badge(
                  isLabelVisible: state.unreadNotifications > 0,
                  backgroundColor: const Color(0xFFFFB020),
                  textColor: AppColors.ink,
                  label: Text(state.unreadNotifications > 99 ? '99+' : '${state.unreadNotifications}'),
                  child: const Icon(AppIcons.bell, size: 22),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
