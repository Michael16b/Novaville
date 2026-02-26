import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/ui/widgets/app_banner.dart';

/// Secured layout with a banner displayed on all authenticated screens.
/// Auth protection is handled at the router level — no wrapper needed here.
class SecuredLayout extends StatelessWidget {
  const SecuredLayout({
    required this.child,
    required this.currentLocation,
    super.key,
  });

  final Widget child;
  final String currentLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: Material(
          color: AppColors.page,
          elevation: 6,
          shadowColor: Colors.black54,
          child: AppBanner(currentLocation: currentLocation),
        ),
      ),
      body: child,
    );
  }
}
