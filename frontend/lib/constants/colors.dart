import 'package:flutter/material.dart';

/// Application color palette constants.
class AppColors {
  AppColors._();

  static const Color page = Color(0xFFEEEEEE);

  static const Color primary = Color(0xFF2E6B55);
  static const Color secondary = Color(0xFFF9C846);
  static const Color primaryText = Color(0xFF333333);
  static const Color secondaryText = Color(0xFF757575);

  // Miscellaneous colors
  static const Color white = Color(0xFFFFFFFF);

  static const Color highlight = Color(0x4D2E6B55);

  static const Color error = Color(0xFFC94A4A);
  static const Color success = Color(0xFF5DB075);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);

  // Disabled state
  static const Color disabled = Color(0xFF9E9E9E);

  // Empty state icon color
  static const Color emptyState = Color(0xFFBDBDBD);

  // Skeleton / shimmer placeholder colors
  static const Color skeletonDark = Color(0xFFE0E0E0);
  static const Color skeletonLight = Color(0xFFEEEEEE);

  // Overlay
  static const Color overlay = Color(0x1A000000);

  // Calendar
  /// Background highlight for today's date in the calendar.
  static const Color calendarToday = Color(0x332E6B55);
  static const Color calendarSelected = Color(0xFF2E6B55);
  static const Color calendarMarker = Color(0xFFF9C846);
  static const Color calendarWeekend = Color(0xFF9E9E9E);
  static const Color calendarOutside = Color(0xFFBDBDBD);

  // External services
  /// Google brand blue color.
  static const Color googleBlue = Color(0xFF4285F4);
}
