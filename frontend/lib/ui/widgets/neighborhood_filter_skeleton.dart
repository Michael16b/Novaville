import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';

/// Animated skeleton placeholder shown while neighborhood data is loading.
class NeighborhoodFilterSkeleton extends StatefulWidget {
  /// Creates a [NeighborhoodFilterSkeleton].
  const NeighborhoodFilterSkeleton({super.key});

  @override
  State<NeighborhoodFilterSkeleton> createState() =>
      _NeighborhoodFilterSkeletonState();
}

class _NeighborhoodFilterSkeletonState extends State<NeighborhoodFilterSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = _pulseController.value;
        final barColor = Color.lerp(
          AppColors.secondaryText.withValues(alpha: 0.12),
          AppColors.secondaryText.withValues(alpha: 0.24),
          pulseValue,
        );

        return Container(
          height: 32,
          decoration: BoxDecoration(
            border: Border.all(color: barColor ?? Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(height: 14, width: 80, color: barColor),
                ),
                const SizedBox(width: 8),
                Container(height: 16, width: 16, color: barColor),
              ],
            ),
          ),
        );
      },
    );
  }
}
