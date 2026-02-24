import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts.dart';
import 'package:frontend/design_systems/custom_elevated_flat_button.dart';
import 'package:frontend/design_systems/custom_elevated_stroked_button.dart';
import 'package:frontend/features/account/presentation/pages/my_account_page.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/features/home/presentation/pages/home_page.dart';
import 'package:frontend/ui/assets.dart';
import 'package:frontend/ui/layouts/secured_layout.dart';

class AppBanner extends StatelessWidget {
  const AppBanner({this.isHomePage = false, super.key});

  final bool isHomePage;

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
                if (isHomePage)
                  // Bouton désactivé sur la HomePage
                  CustomElevatedFlatButton(
                  text: AppTexts.homeButton,
                  onPressed: () {},
                  iconData: Icons.home_outlined,
                )
                else
                  // Bouton actif sur les autres pages
                  CustomElevatedStrokedButton(
                    text: AppTexts.homeButton,
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute<void>(
                          builder: (context) => const SecuredLayout(
                            isHomePage: true,
                            child: HomePage(),
                          ),
                        ),
                        (route) => route.isFirst,
                      );
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
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const MyAccountPage(),
                        ),
                      );
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
