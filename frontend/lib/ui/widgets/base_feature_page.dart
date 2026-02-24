import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';

/// Base widget for feature pages with a common layout structure.
///
/// Displays a centered column with an icon, title, and description text.
/// The [SecuredLayout] (banner) is provided by the [ShellRoute] in the router.
class BaseFeaturePage extends StatelessWidget {
  /// Creates a base feature page.
  const BaseFeaturePage({
    required this.icon,
    required this.title,
    required this.description,
    super.key,
  });

  /// Icon displayed at the top of the page.
  final IconData icon;

  /// Title text displayed below the icon.
  final String title;

  /// Description text displayed below the title.
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: AppColors.primary),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
