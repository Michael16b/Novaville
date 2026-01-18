import 'package:flutter/material.dart';
import 'package:frontend/constants/texts.dart';
import 'package:frontend/ui/widgets/base_feature_page.dart';

/// Page des informations utiles
class UsefulInfoPage extends StatelessWidget {
  /// Crée la page des informations utiles
  const UsefulInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseFeaturePage(
      icon: Icons.info_outlined,
      title: AppTexts.usefulInfo,
      description: 'Page des informations utiles',
    );
  }
}
