import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:go_router/go_router.dart';

class BreadcrumbItem {
  const BreadcrumbItem({required this.label, this.route});
  final String label;
  final String? route;
}

/// A simple breadcrumb widget to display navigation path.
/// Example: Accueil > Signalements
class Breadcrumb extends StatelessWidget {
  const Breadcrumb({super.key, required this.items});
  final List<BreadcrumbItem> items;

  @override
  Widget build(BuildContext context) {
    const homeItem = BreadcrumbItem(label: 'Accueil', route: '/');

    final allItems = [homeItem, ...items];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 520;
        final itemMaxWidth = isCompact
            ? constraints.maxWidth * 0.72
            : constraints.maxWidth;

        return Wrap(
          spacing: 4,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (int i = 0; i < allItems.length; i++) ...[
              _buildItem(
                context,
                allItems[i],
                isLast: i == allItems.length - 1,
                maxWidth: itemMaxWidth,
              ),
              if (i < allItems.length - 1)
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.secondaryText,
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildItem(
    BuildContext context,
    BreadcrumbItem item, {
    required bool isLast,
    required double maxWidth,
  }) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: isLast ? AppColors.primaryText : AppColors.secondaryText,
      fontWeight: isLast ? FontWeight.bold : FontWeight.w500,
      decoration: isLast ? TextDecoration.underline : TextDecoration.none,
    );

    if (isLast) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Text(item.label, softWrap: true, style: textStyle),
      );
    }

    return InkWell(
      onTap: item.route != null ? () => context.go(item.route!) : null,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Text(item.label, softWrap: true, style: textStyle),
      ),
    );
  }
}
