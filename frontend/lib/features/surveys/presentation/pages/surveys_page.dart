import 'package:flutter/material.dart';
import 'package:frontend/constants/texts.dart';
import 'package:frontend/ui/widgets/base_feature_page.dart';

/// Page des sondages
class SurveysPage extends StatelessWidget {
  /// Crée la page des sondages
  const SurveysPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseFeaturePage(
      icon: Icons.how_to_vote,
      title: AppTexts.surveys,
      description: 'Page des sondages',
    );
  }
}
