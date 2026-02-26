import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/config/app_routes.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_auth.dart';
import 'package:frontend/constants/texts/texts_navigation.dart';
import 'package:frontend/design_systems/custom_elevated_flat_button.dart';
import 'package:frontend/design_systems/custom_elevated_stroked_button.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/features/users/data/models/user_role.dart';
import 'package:frontend/ui/assets.dart';
import 'package:go_router/go_router.dart';

class AppBanner extends StatelessWidget {
  const AppBanner({required this.currentLocation, super.key});

  final String currentLocation;

  @override
  Widget build(BuildContext context) {
    final isHomePage = currentLocation == AppRoutes.home;
    final isUserAccounts = currentLocation == AppRoutes.userAccounts;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              spacing: 16,
              children: [
                Image.asset(
                  AppAssets.login_logo,
                  height: 70,
                  width: 70,
                ),
                if (isHomePage)
                  // Button disabled on the HomePage
                  CustomElevatedFlatButton(
                    text: AppTextsNavigation.homeButton,
                    onPressed: () {},
                    iconData: Icons.home_outlined,
                  )
                else
                  // Active button on other pages
                  CustomElevatedStrokedButton(
                    text: AppTextsNavigation.homeButton,
                    onPressed: () => context.go(AppRoutes.home),
                    iconData: Icons.home_outlined,
                  ),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isAdmin = state.user?.role == UserRole.globalAdmin;
                    if (!isAdmin) {
                      return const SizedBox.shrink();
                    }
                    if (isUserAccounts) {
                      // Button disabled on the UserAccountsPage
                      return CustomElevatedFlatButton(
                        text: AppTextsNavigation.userAccountButton,
                        onPressed: () {},
                        iconData: Icons.group_outlined,
                      );
                    } else {
                      // Active button on other pages
                      return CustomElevatedStrokedButton(
                        text: AppTextsNavigation.userAccountButton,
                        onPressed: () => context.go(AppRoutes.userAccounts),
                        iconData: Icons.group_outlined,
                      );
                    }
                  },
                ),
              ],
            ),
            Row(
              children: [
                PopupMenuButton<String>(
                  offset: const Offset(0, 45),
                  icon: const Icon(Icons.account_circle_outlined),
                  onSelected: (value) {
                    if (value == 'logout') {
                      context.read<AuthBloc>().add(const AuthLogoutRequested());
                    } else if (value == 'personal_info') {
                      context.go(AppRoutes.myAccount);
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
                            AppTextsNavigation.personalInfo,
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
                            AppTextsAuth.logout,
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
