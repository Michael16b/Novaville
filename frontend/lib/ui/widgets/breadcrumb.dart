import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:go_router/go_router.dart';

class BreadcrumbItem {
  final String label;
  final String? route;

  const BreadcrumbItem({
    required this.label,
    this.route,
  });
}

/// A simple breadcrumb widget to display navigation path.
/// Example: Accueil > Signalements
class Breadcrumb extends StatelessWidget {
  final List<BreadcrumbItem> items;

  const Breadcrumb({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    const homeItem = BreadcrumbItem(
      label: 'Accueil',
      route: '/',
    );

    final allItems = [
      homeItem,
      ...items,
    ];

    return Row(
      children: [
        for (int i = 0; i < allItems.length; i++) ...[
          _buildItem(context, allItems[i], isLast: i == allItems.length - 1),
          if (i < allItems.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.0),
              child: Icon(
                Icons.chevron_right,
                size: 16,
                color: AppColors.secondaryText,
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildItem(BuildContext context, BreadcrumbItem item, {required bool isLast}) {
    if (isLast) {
      return Text(
        item.label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.primaryText,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
        ),
      );
    }

    return InkWell(
      onTap: item.route != null ? () => context.go(item.route!) : null,
      child: Text(
        item.label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.secondaryText,
        ),
      ),
    );
  }
}
