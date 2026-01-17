import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts.dart';
import 'package:frontend/design_systems/custom_elevated_button.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/ui/assets.dart';

class AppBanner extends StatelessWidget {
  const AppBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset(
                  AppAssets.login_logo,
                  height: 70,
                  width: 70,
                ),
                const SizedBox(width: 16),
                CustomElevatedButton(
                  text: AppTexts.homeButton,
                  onPressed: () {
                    // TODO(new item): Implémenter la redirection vers la page d'accueil
                  },
                  iconData: Icons.home_outlined,
                ),
              ],
            ),
            Row(
              children: [
                PopupMenuButton<String>(
                  offset: const Offset(0, 45),
                  icon: const Icon(
                    Icons.account_circle_outlined,
                  ),
                  onSelected: (value) {
                    if (value == 'logout') {
                      context.read<AuthBloc>().add(const AuthLogoutRequested());
                    } else if (value == 'personal_info') {
                      // TODO(personal_info): Implémenter la navigation vers la page d'informations personnelles
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'personal_info',
                      child: Row(
                        children: [
                          Icon(Icons.person_outline, color: AppColors.primary),
                          SizedBox(width: 12),
                          Text(
                            AppTexts.personalInfo,
                            style: TextStyle(color: AppColors.primaryText),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: AppColors.error),
                          SizedBox(width: 12),
                          Text(
                            AppTexts.logout,
                            style: TextStyle(color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
