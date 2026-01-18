import 'package:flutter/material.dart';
import 'package:frontend/constants/texts.dart';
import 'package:frontend/ui/widgets/base_feature_page.dart';

/// Page des signalements
class ReportsPage extends StatelessWidget {
  /// Crée la page des signalements
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseFeaturePage(
      icon: Icons.report_problem_outlined,
      title: AppTexts.reports,
      description: 'Page des signalements',
    );
  }
}
