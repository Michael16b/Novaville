import 'package:flutter/material.dart';
import 'package:frontend/constants/texts/texts_features.dart';
import 'package:frontend/constants/texts/texts_home.dart';
import 'package:frontend/ui/widgets/base_feature_page.dart';

/// Useful information feature page.
class UsefulInfoPage extends StatelessWidget {
  /// Creates the useful information page.
  const UsefulInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseFeaturePage(
      icon: Icons.info_outlined,
      title: AppTextsHome.usefulInfo,
      description: AppTextsFeatures.usefulInfoDescription,
    );
  }
}
