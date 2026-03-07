import 'package:flutter/material.dart';

class AppleCalendarIcon extends StatelessWidget {
  const AppleCalendarIcon({super.key, this.size = 32});

  /// Icon size (width and height).
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _AppleCalendarPainter(date: DateTime.now())),
    );
  }
}

class _AppleCalendarPainter extends CustomPainter {
  _AppleCalendarPainter({required this.date});

  /// The date displayed on the icon (used for staleness checks).
  final DateTime date;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.03);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.02, s * 0.04, s * 0.96, s * 0.96),
        Radius.circular(s * 0.18),
      ),
      shadowPaint,
    );

    // Background: white rounded square
    final bgPaint = Paint()..color = Colors.white;
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, s, s),
      Radius.circular(s * 0.18),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // Red header bar
    final headerPaint = Paint()..color = const Color(0xFFFF3B30);
    final headerRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, s, s * 0.32),
      topLeft: Radius.circular(s * 0.18),
      topRight: Radius.circular(s * 0.18),
    );
    canvas.drawRRect(headerRect, headerPaint);

    // Day name in header (e.g. "SAM")
    final dayName = _shortDayName();
    final headerText = TextPainter(
      text: TextSpan(
        text: dayName,
        style: TextStyle(
          color: Colors.white,
          fontSize: s * 0.16,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    headerText.paint(
      canvas,
      Offset((s - headerText.width) / 2, (s * 0.32 - headerText.height) / 2),
    );

    // Day number
    final dayNumber = date.day.toString();
    final numberText = TextPainter(
      text: TextSpan(
        text: dayNumber,
        style: TextStyle(
          color: Colors.grey.shade900,
          fontSize: s * 0.38,
          fontWeight: FontWeight.w300,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    numberText.paint(
      canvas,
      Offset(
        (s - numberText.width) / 2,
        s * 0.34 + (s * 0.66 - numberText.height) / 2,
      ),
    );
  }

  String _shortDayName() {
    const days = ['LUN', 'MAR', 'MER', 'JEU', 'VEN', 'SAM', 'DIM'];
    return days[date.weekday - 1];
  }

  @override
  bool shouldRepaint(covariant _AppleCalendarPainter oldDelegate) {
    return date.day != oldDelegate.date.day;
  }
}

