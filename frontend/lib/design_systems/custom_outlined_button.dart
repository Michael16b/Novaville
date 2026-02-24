import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';

/// A customizable outlined button with transparent background and primary-colored border.
///
/// Displays either a text label or a combination of icon and text, and can
/// show a loading spinner when [isLoading] is true.
class CustomOutlinedButton extends StatelessWidget {
  const CustomOutlinedButton({
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
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        side: const BorderSide(
          color: AppColors.primary,
          width: 2,
        ),
        overlayColor: AppColors.primary.withValues(alpha: 0.1),
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          : (iconAsset == null && iconData == null)
          ? Text(
              text,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (iconData != null)
                  Icon(iconData, size: 18, color: AppColors.primary)
                else if (iconAsset != null && iconAsset!.isNotEmpty)
                  Image.asset(iconAsset!, height: 18, width: 18),
                if (text.isNotEmpty) const SizedBox(width: 8),
                if (text.isNotEmpty)
                  Text(
                    text,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
    );
  }
}

