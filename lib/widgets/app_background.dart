import 'package:flutter/material.dart';
import '../core/theme.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark
              ? const [Color(0xFF09101F), Color(0xFF0E172A), Color(0xFF09101F)]
              : const [Color(0xFFF5F8FF), Color(0xFFFFFFFF), Color(0xFFEEF4FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -130,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.blue.withValues(alpha: dark ? .10 : .08),
              ),
            ),
          ),
          Positioned(
            top: 280,
            left: -140,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.blueDeep.withValues(alpha: dark ? .08 : .05),
              ),
            ),
          ),
          CustomPaint(
            painter: _LibraryPatternPainter(dark: dark),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _LibraryPatternPainter extends CustomPainter {
  const _LibraryPatternPainter({required this.dark});
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = (dark ? Colors.white : AppColors.blue).withValues(alpha: dark ? .026 : .032)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = (dark ? Colors.white : AppColors.blue).withValues(alpha: dark ? .026 : .03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    const step = 96.0;
    for (double y = 42; y < size.height; y += step) {
      for (double x = 28; x < size.width; x += step) {
        final shiftedX = x + (((y / step).floor().isOdd) ? step / 2 : 0);
        if (shiftedX < size.width) canvas.drawCircle(Offset(shiftedX, y), 1.5, dotPaint);
      }
    }

    for (double y = 150; y < size.height; y += 250) {
      for (double x = 68; x < size.width; x += 270) {
        final path = Path()
          ..moveTo(x - 17, y - 7)
          ..quadraticBezierTo(x - 8, y - 10, x, y - 2)
          ..quadraticBezierTo(x + 8, y - 10, x + 17, y - 7)
          ..lineTo(x + 17, y + 8)
          ..quadraticBezierTo(x + 8, y + 5, x, y + 12)
          ..quadraticBezierTo(x - 8, y + 5, x - 17, y + 8)
          ..close();
        canvas.drawPath(path, linePaint);
        canvas.drawLine(Offset(x, y - 2), Offset(x, y + 12), linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LibraryPatternPainter oldDelegate) => oldDelegate.dark != dark;
}
