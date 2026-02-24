import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_general.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/features/auth/presentation/pages/login_page.dart';
import 'package:frontend/features/home/presentation/pages/home_page.dart';
import 'package:frontend/ui/layouts/secured_layout.dart';

class App extends StatelessWidget {
  const App({required this.home, super.key});

  final Widget home;

  // Global key used for navigation
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // When the user logs in, redirect to the home page
        if (state.status == AuthStatus.authenticated) {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute<void>(
              builder: (context) => const SecuredLayout(
                isHomePage: true,
                child: HomePage(),
              ),
            ),
            (route) => false, // Remove all previous routes
          );
        }
        // When the user logs out, redirect to the login page
        else if (state.status == AuthStatus.unauthenticated) {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute<void>(
              builder: (context) => const LoginPage(),
            ),
            (route) => false, // Remove all previous routes
          );
        }
      },
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: AppTextsGeneral.appName,
        theme: ThemeData(
          fontFamily: 'Montserrat',
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.page,
        ),
        home: home,
      ),
    );
  }
}
