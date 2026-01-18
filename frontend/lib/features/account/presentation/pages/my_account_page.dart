import 'package:flutter/material.dart';
import 'package:frontend/constants/texts.dart';
import 'package:frontend/ui/widgets/base_feature_page.dart';

/// Page du compte utilisateur
class MyAccountPage extends StatelessWidget {
  /// Crée la page du compte
  const MyAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseFeaturePage(
      icon: Icons.account_circle_outlined,
      title: AppTexts.myAccount,
      description: 'Page de mon compte',
    );
  }
}
