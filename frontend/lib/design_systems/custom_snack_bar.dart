import 'package:flutter/material.dart';

/// Custom widget for displaying centered and styled SnackBars.
class CustomSnackBar {
  /// Displays a success SnackBar (green).
  static void showSuccess(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      backgroundColor: Colors.green,
      icon: Icons.check_circle_outline,
    );
  }

  /// Displays an error SnackBar (red).
  static void showError(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      backgroundColor: Colors.red,
      icon: Icons.error_outline,
    );
  }

  /// Displays an info SnackBar (blue).
  static void showInfo(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      backgroundColor: Colors.blue,
      icon: Icons.info_outline,
    );
  }

  /// Displays a warning SnackBar (orange).
  static void showWarning(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      backgroundColor: Colors.orange,
      icon: Icons.warning_amber_outlined,
    );
  }

  /// Private method that renders the SnackBar.
  static void _show({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width * 0.25,
          vertical: 20,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }
}
