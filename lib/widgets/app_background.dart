import 'package:flutter/material.dart';

import '../core/theme.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF0B1220)
        : const Color(0xFFF9FBFF),
    child: CustomPaint(
      painter: _LibraryPatternPainter(
        dark: Theme.of(context).brightness == Brightness.dark,
      ),
      child: child,
    ),
  );
}

class _LibraryPatternPainter extends CustomPainter {
  const _LibraryPatternPainter({required this.dark});
  final bool dark;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (dark ? const Color(0xFFA9B9D2) : AppColors.blue).withValues(
        alpha: dark ? .065 : .045,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (var row = 0; row * 165 < size.height; row++) {
      for (var col = 0; col * 150 < size.width; col++) {
        canvas.save();
        canvas.translate(col * 150.0 + (row.isOdd ? 80 : 24), row * 165.0 + 40);
        canvas.rotate(row.isOdd ? -.18 : .12);
        switch ((row + col) % 3) {
          case 0:
            canvas.drawPath(
              Path()
                ..moveTo(0, 5)
                ..quadraticBezierTo(10, -1, 20, 5)
                ..quadraticBezierTo(30, -1, 40, 5)
                ..lineTo(40, 32)
                ..quadraticBezierTo(30, 26, 20, 32)
                ..quadraticBezierTo(10, 26, 0, 32)
                ..close(),
              paint,
            );
            canvas.drawLine(const Offset(20, 5), const Offset(20, 32), paint);
          case 1:
            canvas.drawPath(
              Path()
                ..moveTo(5, 0)
                ..lineTo(31, 0)
                ..lineTo(31, 38)
                ..lineTo(18, 29)
                ..lineTo(5, 38)
                ..close(),
              paint,
            );
          default:
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                const Rect.fromLTWH(0, 0, 30, 40),
                const Radius.circular(3),
              ),
              paint,
            );
            for (var y = 10; y <= 28; y += 9) {
              canvas.drawLine(
                Offset(7, y.toDouble()),
                Offset(23, y.toDouble()),
                paint,
              );
            }
        }
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LibraryPatternPainter oldDelegate) =>
      dark != oldDelegate.dark;
}
