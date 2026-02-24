import 'package:flutter/material.dart';
import 'package:frontend/constants/texts/texts_features.dart';
import 'package:frontend/constants/texts/texts_home.dart';
import 'package:frontend/ui/widgets/base_feature_page.dart';

/// Reports feature page.
class ReportsPage extends StatelessWidget {
  /// Creates the reports page.
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseFeaturePage(
      icon: Icons.report_problem_outlined,
      title: AppTextsHome.reports,
      description: AppTextsFeatures.reportsDescription,
    );
  }
}
