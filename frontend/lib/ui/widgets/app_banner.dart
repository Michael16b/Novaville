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
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  spacing: 16,
                  children: [
                    InkWell(
                      onTap: () => context.go(AppRoutes.home),
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        AppAssets.login_logo,
                        height: 70,
                        width: 70,
                      ),
                    ),
                    if (isHomePage)
                      CustomElevatedFlatButton(
                        text: AppTextsNavigation.homeButton,
                        onPressed: () {},
                        iconData: Icons.home_outlined,
                      )
                    else
                      CustomElevatedStrokedButton(
                        text: AppTextsNavigation.homeButton,
                        onPressed: () => context.go(AppRoutes.home),
                        iconData: Icons.home_outlined,
                      ),
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isAdmin =
                            state.user?.role == UserRole.globalAdmin;
                        if (!isAdmin) {
                          return const SizedBox.shrink();
                        }
                        if (isUserAccounts) {
                          return CustomElevatedFlatButton(
                            text: AppTextsNavigation.userAccountButton,
                            onPressed: () {},
                            iconData: Icons.group_outlined,
                          );
                        }
                        return CustomElevatedStrokedButton(
                          text: AppTextsNavigation.userAccountButton,
                          onPressed: () => context.go(AppRoutes.userAccounts),
                          iconData: Icons.group_outlined,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final user = state.user;
                final fullName = user != null
                    ? '${user.firstName} ${user.lastName}'
                    : AppTextsNavigation.myAccount;
                final roleLabel = user?.role?.label ?? '';

                return PopupMenuButton<String>(
                  offset: const Offset(0, 45),
                  color: Colors.white, // Force white background
                  surfaceTintColor: Colors.white, // Prevent Material 3 tint
                  onSelected: (value) {
                    if (value == 'logout') {
                      context.read<AuthBloc>().add(const AuthLogoutRequested());
                    } else if (value == 'personal_info') {
                      context.go(AppRoutes.myAccount);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'personal_info',
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Flexible(
                            child: Text(
                              AppTextsNavigation.personalInfo,
                              style: TextStyle(color: AppColors.primaryText),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.logout,
                              size: 16,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Flexible(
                            child: Text(
                              AppTextsAuth.logout,
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            fullName,
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (roleLabel.isNotEmpty)
                            Text(
                              roleLabel,
                              style: const TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
