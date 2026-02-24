import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';

/// Main menu card displaying an icon and a title.
class MenuCard extends StatelessWidget {
  /// Creates a menu card.
  const MenuCard({
    required this.icon,
    required this.title,
    required this.onTap,
    super.key,
  });

  /// Icon displayed on the card.
  final IconData icon;

  /// Title of the card.
  final String title;

  /// Callback invoked when the card is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const borderRadius = BorderRadius.only(
      topLeft: Radius.circular(30),
      topRight: Radius.circular(15),
      bottomLeft: Radius.circular(15),
      bottomRight: Radius.circular(50),
    );

    return Card(
      color: AppColors.primary,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: const RoundedRectangleBorder(
        borderRadius: borderRadius,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 60,
              color: AppColors.secondary,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
