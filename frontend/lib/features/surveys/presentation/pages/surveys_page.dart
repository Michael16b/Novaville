import 'package:flutter/material.dart';
import 'package:frontend/constants/texts/texts_features.dart';
import 'package:frontend/constants/texts/texts_home.dart';
import 'package:frontend/ui/widgets/base_feature_page.dart';

/// Surveys feature page.
class SurveysPage extends StatelessWidget {
  /// Creates the surveys page.
  const SurveysPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseFeaturePage(
      icon: Icons.how_to_vote,
      title: AppTextsHome.agendaTitle,
      description: AppTextsFeatures.surveysDescription,
    );
  }
}
