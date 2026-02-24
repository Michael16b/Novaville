import 'package:flutter/material.dart';
import 'package:frontend/constants/texts/texts_features.dart';
import 'package:frontend/constants/texts/texts_home.dart';
import 'package:frontend/ui/widgets/base_feature_page.dart';

/// Agenda feature page.
class AgendaPage extends StatelessWidget {
  /// Creates the agenda page.
  const AgendaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseFeaturePage(
      icon: Icons.calendar_month,
      title: AppTextsHome.agenda,
      description: AppTextsFeatures.agendaDescription,
    );
  }
}
