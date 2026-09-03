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
    final background = dark ? const Color(0xFF101827) : Colors.white;
    final foreground = dark ? Colors.white : AppColors.ink;

    return Material(
      color: background,
      elevation: 0,
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: dark ? Colors.white.withValues(alpha: .07) : AppColors.line,
            ),
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            IgnorePointer(child: CustomPaint(painter: _HeaderPatternPainter(dark: dark))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: dark ? Colors.white.withValues(alpha: .07) : const Color(0xFFF4F7FC),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: dark ? Colors.white.withValues(alpha: .08) : AppColors.line,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset('assets/branding/icon.png', fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'FASO',
                            style: AppTypography.display(
                              size: 18,
                              weight: FontWeight.w900,
                              color: foreground,
                            ),
                          ),
                          TextSpan(
                            text: 'BIBLIO',
                            style: AppTypography.display(
                              size: 18,
                              weight: FontWeight.w900,
                              color: AppColors.blue,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: onNotifications,
                    tooltip: 'Notifications',
                    visualDensity: VisualDensity.compact,
                    icon: Badge(
                      isLabelVisible: state.unreadNotifications > 0,
                      backgroundColor: const Color(0xFFFFB020),
                      textColor: AppColors.ink,
                      label: Text(state.unreadNotifications > 99 ? '99+' : '${state.unreadNotifications}'),
                      child: Icon(AppIcons.bell, size: 23, color: foreground),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderPatternPainter extends CustomPainter {
  const _HeaderPatternPainter({required this.dark});
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.blue.withValues(alpha: dark ? .055 : .04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    for (double x = 180; x < size.width + 40; x += 76) {
      canvas.drawCircle(Offset(x, 14), 18, paint);
      canvas.drawLine(Offset(x - 12, 45), Offset(x + 12, 45), paint);
      canvas.drawLine(Offset(x - 7, 50), Offset(x + 15, 50), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HeaderPatternPainter oldDelegate) => oldDelegate.dark != dark;
}
