import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';

class CustomElevatedFlatButton extends StatelessWidget {
  const CustomElevatedFlatButton({
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
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        elevation: 2,
        overlayColor: AppColors.white.withValues(alpha: 0.2),
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.white,
              ),
            )
          : (iconAsset == null && iconData == null)
          ? Text(
              text,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (iconData != null)
                  Icon(iconData, size: 18, color: AppColors.white)
                else if (iconAsset != null && iconAsset!.isNotEmpty)
                  Image.asset(iconAsset!, height: 18, width: 18),
                if (text.isNotEmpty) const SizedBox(width: 8),
                if (text.isNotEmpty)
                  Text(
                    text,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
    );
  }
}
