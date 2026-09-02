import 'package:flutter/material.dart';
import '../core/theme.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: CustomPaint(
        painter: _LibraryPatternPainter(dark: dark),
        child: child,
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
      ..color = (dark ? Colors.white : AppColors.blue).withValues(alpha: dark ? .035 : .045)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = (dark ? Colors.white : AppColors.blue).withValues(alpha: dark ? .035 : .04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    const step = 92.0;
    for (double y = 34; y < size.height; y += step) {
      for (double x = 26; x < size.width; x += step) {
        final shiftedX = x + (((y / step).floor().isOdd) ? step / 2 : 0);
        if (shiftedX < size.width) canvas.drawCircle(Offset(shiftedX, y), 1.7, dotPaint);
      }
    }

    for (double y = 92; y < size.height; y += 230) {
      for (double x = 56; x < size.width; x += 250) {
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
