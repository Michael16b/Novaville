import 'package:flutter/material.dart';
import 'package:frontend/constants/texts.dart';
import 'package:frontend/ui/widgets/base_feature_page.dart';

/// Page de l'agenda
class AgendaPage extends StatelessWidget {
  /// Crée la page de l'agenda
  const AgendaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseFeaturePage(
      icon: Icons.calendar_month,
      title: AppTexts.agenda,
      description: "Page de l'agenda",
    );
  }
}
