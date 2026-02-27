import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';

/// Action item displayed inside [ExpandableFabMenu].
class FabMenuAction {
  const FabMenuAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
}

/// Floating action button that expands upward to reveal multiple actions.
class ExpandableFabMenu extends StatefulWidget {
  const ExpandableFabMenu({
    required this.actions,
    this.tooltip,
    this.heroTag,
    super.key,
  });

  final List<FabMenuAction> actions;
  final String? tooltip;
  final Object? heroTag;

  @override
  State<ExpandableFabMenu> createState() => _ExpandableFabMenuState();
}

class _ExpandableFabMenuState extends State<ExpandableFabMenu> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        IgnorePointer(
          ignoring: !_expanded,
          child: AnimatedOpacity(
            opacity: _expanded ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              offset: _expanded ? Offset.zero : const Offset(0, 0.15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final action in widget.actions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _FabActionItem(
                        action: action,
                        onPressed: () {
                          setState(() {
                            _expanded = false;
                          });
                          action.onPressed();
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        FloatingActionButton(
          heroTag: widget.heroTag,
          tooltip: widget.tooltip,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          onPressed: () {
            setState(() {
              _expanded = !_expanded;
            });
          },
          child: AnimatedRotation(
            turns: _expanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

class _FabActionItem extends StatelessWidget {
  const _FabActionItem({required this.action, required this.onPressed});

  final FabMenuAction action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(24),
      color: AppColors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(action.icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                action.label,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
