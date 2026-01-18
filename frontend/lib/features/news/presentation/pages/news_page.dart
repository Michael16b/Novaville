import 'package:flutter/material.dart';
import 'package:frontend/constants/texts.dart';
import 'package:frontend/ui/widgets/base_feature_page.dart';

/// Page des actualités
class NewsPage extends StatelessWidget {
  /// Crée la page des actualités
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseFeaturePage(
      icon: Icons.newspaper,
      title: AppTexts.news,
      description: 'Page des actualités',
    );
  }
}
