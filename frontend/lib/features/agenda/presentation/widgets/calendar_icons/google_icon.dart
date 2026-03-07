import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';

class GoogleCalendarIcon extends StatelessWidget {
  /// Creates a [GoogleCalendarIcon].
  const GoogleCalendarIcon({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleCalendarPainter()),
    );
  }
}

class _GoogleCalendarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;

    // Background: white rounded square
    final bgPaint = Paint()..color = Colors.white;
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, s, s),
      Radius.circular(s * 0.18),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // Border
    final borderPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.03;
    canvas.drawRRect(bgRect, borderPaint);

    // Top bar (calendar header) — Google blue
    final headerPaint = Paint()..color = AppColors.googleBlue;
    final headerRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(s * 0.05, s * 0.05, s * 0.9, s * 0.22),
      topLeft: Radius.circular(s * 0.14),
      topRight: Radius.circular(s * 0.14),
    );
    canvas.drawRRect(headerRect, headerPaint);

    // Two small calendar hooks
    final hookPaint = Paint()
      ..color = Colors.grey.shade600
      ..strokeWidth = s * 0.06
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(s * 0.32, s * 0.02),
      Offset(s * 0.32, s * 0.12),
      hookPaint,
    );
    canvas.drawLine(
      Offset(s * 0.68, s * 0.02),
      Offset(s * 0.68, s * 0.12),
      hookPaint,
    );

    // "31" text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '31',
        style: TextStyle(
          color: Colors.grey.shade800,
          fontSize: s * 0.32,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        (s - textPainter.width) / 2,
        s * 0.38 + (s * 0.52 - textPainter.height) / 2,
      ),
    );

    final dotRadius = s * 0.055;
    canvas
        ..drawCircle(Offset(s * 0.2, s * 0.4), dotRadius, Paint()..color = AppColors.googleBlue)
        ..drawCircle(Offset(s * 0.8, s * 0.4), dotRadius, Paint()..color = const Color(0xFF34A853))
        ..drawCircle(Offset(s * 0.2, s * 0.88), dotRadius, Paint()..color = const Color(0xFFFBBC05))
        ..drawCircle(Offset(s * 0.8, s * 0.88), dotRadius, Paint()..color = const Color(0xFFEA4335));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
