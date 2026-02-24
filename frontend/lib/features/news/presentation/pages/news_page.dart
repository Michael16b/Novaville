import 'package:flutter/material.dart';
import 'package:frontend/constants/texts/texts_features.dart';
import 'package:frontend/constants/texts/texts_home.dart';
import 'package:frontend/ui/widgets/base_feature_page.dart';

/// News feature page.
class NewsPage extends StatelessWidget {
  /// Creates the news page.
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseFeaturePage(
      icon: Icons.newspaper,
      title: AppTextsHome.news,
      description: AppTextsFeatures.newsDescription,
    );
  }
}
