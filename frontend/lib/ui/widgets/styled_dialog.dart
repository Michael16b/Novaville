import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';

/// A reusable styled dialog shell matching the application design system.
///
/// Provides a colored header with icon, a scrollable body,
/// and a footer with action buttons.
class StyledDialog extends StatelessWidget {
  /// Creates a [StyledDialog].
  const StyledDialog({
    required this.title,
    required this.icon,
    required this.body,
    this.accentColor = AppColors.primary,
    this.actions = const [],
    this.maxWidth = 500,
    this.closeTooltip = 'Fermer',
    super.key,
  });

  /// Dialog title text.
  final String title;

  /// Icon displayed in the header badge.
  final IconData icon;

  /// Accent color for the header.
  final Color accentColor;

  /// Main body widget.
  final Widget body;

  /// Bottom action buttons.
  final List<Widget> actions;

  /// Maximum width constraint.
  final double maxWidth;

  /// Tooltip for the close button.
  final String closeTooltip;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 20, color: accentColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: closeTooltip,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      minimumSize: const Size(36, 36),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ──
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: body,
              ),
            ),

            // ── Footer ──
            if (actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Row(
                  children: _buildSpacedActions(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSpacedActions() {
    final spaced = <Widget>[];
    for (var i = 0; i < actions.length; i++) {
      if (i > 0) spaced.add(const SizedBox(width: 10));
      spaced.add(Expanded(child: actions[i]));
    }
    return spaced;
  }

  // ─── Factory helpers for common button styles ─────────────────

  /// A cancel / secondary outlined button.
  static Widget cancelButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.secondaryText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// A primary action elevated button.
  static Widget primaryButton({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    Color color = AppColors.primary,
  }) {
    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    }
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    );
  }

  /// A destructive action button (red).
  static Widget destructiveButton({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    return primaryButton(
      label: label,
      onPressed: onPressed,
      icon: icon ?? Icons.delete_outline_rounded,
      color: AppColors.error,
    );
  }
}

