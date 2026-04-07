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
    final isTownHall = currentLocation == AppRoutes.townHall;
    final authState = context.watch<AuthBloc>().state;
    final isAuthenticated = authState.status == AuthStatus.authenticated;
    final authBloc = context.read<AuthBloc>();
    final router = GoRouter.of(context);
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
                    if (authState.user?.role == UserRole.globalAdmin)
                      if (isTownHall)
                        CustomElevatedFlatButton(
                          text: AppTextsNavigation.townHallButton,
                          onPressed: () {},
                          iconData: Icons.account_balance_outlined,
                        )
                      else
                        CustomElevatedStrokedButton(
                          text: AppTextsNavigation.townHallButton,
                          onPressed: () => context.go(AppRoutes.townHall),
                          iconData: Icons.account_balance_outlined,
                        ),
                    if (isUserAccounts)
                        CustomElevatedFlatButton(
                          text: AppTextsNavigation.userAccountButton,
                          onPressed: () {},
                          iconData: Icons.group_outlined,
                        )
                      else
                        CustomElevatedStrokedButton(
                          text: AppTextsNavigation.userAccountButton,
                          onPressed: () => context.go(AppRoutes.userAccounts),
                          iconData: Icons.group_outlined,
                        ),
                  ],
                ),
              ),
            ),
            if (isAuthenticated)
              MenuAnchor(
                style: MenuStyle(
                  backgroundColor: WidgetStatePropertyAll<Color>(Colors.white),
                  surfaceTintColor: const WidgetStatePropertyAll<Color>(
                    Colors.white,
                  ),
                  shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                menuChildren: [
                  MenuItemButton(
                    onPressed: () => router.go(AppRoutes.myAccount),
                    leadingIcon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    child: const Text(
                      AppTextsNavigation.personalInfo,
                      style: TextStyle(color: AppColors.primaryText),
                    ),
                  ),
                  MenuItemButton(
                    onPressed: () =>
                        authBloc.add(const AuthLogoutRequested()),
                    leadingIcon: Container(
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
                    child: const Text(
                      AppTextsAuth.logout,
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
                builder: (context, controller, child) {
                  return InkWell(
                    onTap: () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
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
                                '${authState.user!.firstName} ${authState.user!.lastName}'
                                    .trim(),
                                style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                authState.user?.role?.label ?? '',
                                style: const TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            controller.isOpen
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: AppColors.secondaryText,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomElevatedStrokedButton(
                    text: AppTextsAuth.register,
                    onPressed: () => context.go(AppRoutes.register),
                    iconData: Icons.person_add_alt_1,
                  ),
                  const SizedBox(width: 8),
                  CustomElevatedStrokedButton(
                    text: AppTextsAuth.login,
                    onPressed: () => context.go(AppRoutes.login),
                    iconData: Icons.login,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
