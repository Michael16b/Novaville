import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color page = Color(0xFFEEEEEE);

  static const Color primary = Color(0xFF2E6B55);
  static const Color secondary = Color(0xFFF9C846);
  static const Color primaryText = Color(0xFF333333);
  static const Color secondaryText = Color(0xFF757575);

  // Autres couleurs
  static const Color white = Color(0xFFFFFFFF);

  static final Color highlight = primary.withValues(alpha: 0.3);

  static const Color error = Color(0xFFC94A4A);
  static const Color success = Color(0xFF5DB075);
}
