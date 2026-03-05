import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';

/// A customizable elevated button with a primary-colored stroke and optional icon.
///
/// Displays either a text label or a combination of icon and text, and can
/// show a loading spinner when [isLoading] is true.
class CustomElevatedStrokedButton extends StatelessWidget {
  const CustomElevatedStrokedButton({
    required this.text,
    required this.onPressed,
    super.key,
    this.iconAsset,
    this.iconData,
    this.isLoading = false,
  });

  final String text;
  final String? iconAsset;
  final IconData? iconData;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.page,
        foregroundColor: AppColors.primaryText, // Changed to primaryText to match previous behavior or theme
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // Updated to match theme radius
          side: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        elevation: 2,
        overlayColor: AppColors.primary.withValues(alpha: 0.1), // Adjusted overlay for better feedback on light bg
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 1,
                color: AppColors.primary, // Changed to primary for visibility on light bg
              ),
            )
          : (iconAsset == null && iconData == null)
          ? Text(
              text,
              style: const TextStyle(
                color: AppColors.primaryText, // Explicitly set color if needed
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (iconData != null)
                  Icon(iconData, size: 18, color: AppColors.primaryText)
                else if (iconAsset != null && iconAsset!.isNotEmpty)
                  Image.asset(iconAsset!, height: 18, width: 18),
                if (text.isNotEmpty) const SizedBox(width: 8),
                if (text.isNotEmpty)
                  Text(
                    text,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
    );
  }
}
