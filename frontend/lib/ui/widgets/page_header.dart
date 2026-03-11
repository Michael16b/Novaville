import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/ui/widgets/breadcrumb.dart';

/// A reusable page header component with an icon, title, and description.
///
/// This component is designed to be used at the top of main pages like
/// ReportsPage and UserAccountsPage to provide a consistent look and feel.
/// It can optionally display a [Breadcrumb] at the top left.
class PageHeader extends StatelessWidget {
  /// Creates a [PageHeader].
  const PageHeader({
    required this.title,
    required this.description,
    required this.icon,
    this.breadcrumbItems,
    super.key,
  });

  /// The main title of the page.
  final String title;

  /// A brief description or subtitle for the page.
  final String description;

  /// The icon to display next to the title.
  final IconData icon;

  /// Optional items to display in a breadcrumb above the title.
  final List<BreadcrumbItem>? breadcrumbItems;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (breadcrumbItems != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Breadcrumb(items: breadcrumbItems!),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 32,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryText,
                            letterSpacing: 0.3,
                            height: 1.3,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.secondaryText,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}
