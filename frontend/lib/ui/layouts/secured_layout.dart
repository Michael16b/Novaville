import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/features/auth/presentation/widgets/authenticated_wrapper.dart';
import 'package:frontend/ui/widgets/app_banner.dart';

/// Secured layout with a banner displayed on all authenticated screens.
class SecuredLayout extends StatelessWidget {
  const SecuredLayout({
    required this.child,
    this.isHomePage = false,
    super.key,
  });

  final Widget child;
  final bool isHomePage;

  @override
  Widget build(BuildContext context) {
    return AuthenticatedWrapper(
      child: Scaffold(
        backgroundColor: AppColors.page,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Material(
            color: AppColors.page,
            elevation: 6,
            shadowColor: Colors.black54,
            child: AppBanner(isHomePage: isHomePage),
          ),
        ),
        body: child,
      ),
    );
  }
}
