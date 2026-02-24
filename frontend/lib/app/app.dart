import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/features/auth/presentation/pages/login_page.dart';
import 'package:frontend/features/home/presentation/pages/home_page.dart';
import 'package:frontend/ui/layouts/secured_layout.dart';

class App extends StatelessWidget {
  const App({required this.home, super.key});

  final Widget home;

  // Clé globale pour la navigation
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Quand l'utilisateur se connecte, rediriger vers la page d'accueil
        if (state.status == AuthStatus.authenticated) {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute<void>(
              builder: (context) => const SecuredLayout(
                isHomePage: true,
                child: HomePage(),
              ),
            ),
            (route) => false, // Supprimer toutes les routes précédentes
          );
        }
        // Quand l'utilisateur se déconnecte, rediriger vers la page de login
        else if (state.status == AuthStatus.unauthenticated) {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute<void>(
              builder: (context) => const LoginPage(),
            ),
            (route) => false, // Supprimer toutes les routes précédentes
          );
        }
      },
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Novaville',
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
