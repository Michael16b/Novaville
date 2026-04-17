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

  static const double _compactBannerBreakpoint = 980;

  final String currentLocation;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isAuthenticated = authState.status == AuthStatus.authenticated;
    final authBloc = context.read<AuthBloc>();
    final router = GoRouter.of(context);
    final navigationActions = _buildNavigationActions(context, authState);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final useCompactLayout = _shouldUseCompactLayout(
              context,
              constraints.maxWidth,
            );

            if (useCompactLayout) {
              return Row(
                children: [
                  _buildLogo(context),
                  const Spacer(),
                  _buildCompactMenu(
                    context: context,
                    navigationActions: navigationActions,
                    isAuthenticated: isAuthenticated,
                    authState: authState,
                    authBloc: authBloc,
                    router: router,
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      spacing: 16,
                      children: [
                        _buildLogo(context),
                        ...navigationActions.map(_buildNavigationButton),
                      ],
                    ),
                  ),
                ),
                if (isAuthenticated)
                  _buildProfileMenu(
                    context: context,
                    authState: authState,
                    authBloc: authBloc,
                    router: router,
                  )
                else
                  _buildGuestActions(context),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _shouldUseCompactLayout(BuildContext context, double maxWidth) {
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final isMobile = shortestSide < 600;
    return isMobile || maxWidth < _compactBannerBreakpoint;
  }

  Widget _buildLogo(BuildContext context) {
    return InkWell(
      onTap: () => context.go(AppRoutes.home),
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        AppAssets.login_logo,
        height: 70,
        width: 70,
      ),
    );
  }

  List<_BannerNavigationAction> _buildNavigationActions(
    BuildContext context,
    AuthState authState,
  ) {
    final actions = <_BannerNavigationAction>[
      _BannerNavigationAction(
        text: AppTextsNavigation.homeButton,
        iconData: Icons.home_outlined,
        isCurrent: currentLocation == AppRoutes.home,
        onPressed: () => context.go(AppRoutes.home),
      ),
    ];

    if (authState.user?.role == UserRole.globalAdmin ||
        authState.user?.role == UserRole.elected) {
      actions.add(
        _BannerNavigationAction(
          text: AppTextsNavigation.townHallButton,
          iconData: Icons.account_balance_outlined,
          isCurrent: currentLocation == AppRoutes.townHall,
          onPressed: () => context.go(AppRoutes.townHall),
        ),
      );
    }

    if (authState.user?.role == UserRole.globalAdmin) {
      actions.add(
        _BannerNavigationAction(
          text: AppTextsNavigation.userAccountButton,
          iconData: Icons.group_outlined,
          isCurrent: currentLocation == AppRoutes.userAccounts,
          onPressed: () => context.go(AppRoutes.userAccounts),
        ),
      );
    }

    return actions;
  }

  Widget _buildNavigationButton(_BannerNavigationAction action) {
    if (action.isCurrent) {
      return CustomElevatedFlatButton(
        text: action.text,
        onPressed: () {},
        iconData: action.iconData,
      );
    }

    return CustomElevatedStrokedButton(
      text: action.text,
      onPressed: action.onPressed,
      iconData: action.iconData,
    );
  }

  Widget _buildGuestActions(BuildContext context) {
    return Row(
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
    );
  }

  Widget _buildProfileMenu({
    required BuildContext context,
    required AuthState authState,
    required AuthBloc authBloc,
    required GoRouter router,
  }) {
    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll<Color>(Colors.white),
        surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.white),
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
          onPressed: () {
            authBloc.add(const AuthLogoutRequested());
            context.go(AppRoutes.home);
          },
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
    );
  }

  Widget _buildCompactMenu({
    required BuildContext context,
    required List<_BannerNavigationAction> navigationActions,
    required bool isAuthenticated,
    required AuthState authState,
    required AuthBloc authBloc,
    required GoRouter router,
  }) {
    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll<Color>(Colors.white),
        surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.white),
        shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      menuChildren: [
        ...navigationActions.map(
          (action) => MenuItemButton(
            onPressed: action.isCurrent ? null : action.onPressed,
            leadingIcon: Icon(action.iconData, color: AppColors.primary),
            child: Text(
              action.text,
              style: const TextStyle(color: AppColors.primaryText),
            ),
          ),
        ),
        if (isAuthenticated) ...[
          const Divider(height: 1),
          MenuItemButton(
            onPressed: () => router.go(AppRoutes.myAccount),
            leadingIcon: const Icon(Icons.person, color: AppColors.primary),
            child: const Text(
              AppTextsNavigation.personalInfo,
              style: TextStyle(color: AppColors.primaryText),
            ),
          ),
          MenuItemButton(
            onPressed: () {
              authBloc.add(const AuthLogoutRequested());
              context.go(AppRoutes.home);
            },
            leadingIcon: const Icon(Icons.logout, color: AppColors.error),
            child: const Text(
              AppTextsAuth.logout,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ] else ...[
          const Divider(height: 1),
          MenuItemButton(
            onPressed: () => context.go(AppRoutes.register),
            leadingIcon: const Icon(
              Icons.person_add_alt_1,
              color: AppColors.primary,
            ),
            child: const Text(
              AppTextsAuth.register,
              style: TextStyle(color: AppColors.primaryText),
            ),
          ),
          MenuItemButton(
            onPressed: () => context.go(AppRoutes.login),
            leadingIcon: const Icon(Icons.login, color: AppColors.primary),
            child: const Text(
              AppTextsAuth.login,
              style: TextStyle(color: AppColors.primaryText),
            ),
          ),
        ],
      ],
      builder: (context, controller, child) {
        return IconButton(
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          tooltip: 'Menu',
          icon: const Icon(Icons.menu, color: AppColors.primaryText),
        );
      },
    );
  }
}

class _BannerNavigationAction {
  const _BannerNavigationAction({
    required this.text,
    required this.iconData,
    required this.isCurrent,
    required this.onPressed,
  });

  final String text;
  final IconData iconData;
  final bool isCurrent;
  final VoidCallback onPressed;
}



