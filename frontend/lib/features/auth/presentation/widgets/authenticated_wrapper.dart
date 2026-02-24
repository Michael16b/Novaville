import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';

/// Wrapper qui vérifie que l'utilisateur est authentifié avant d'afficher le contenu
/// Si l'utilisateur n'est pas authentifié, affiche un loader (la redirection est gérée par le BlocListener dans App)
class AuthenticatedWrapper extends StatelessWidget {
  const AuthenticatedWrapper({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Si l'utilisateur n'est pas authentifié ou en cours de vérification, afficher un loader
        if (state.status == AuthStatus.unauthenticated ||
            state.status == AuthStatus.checking) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Si authentifié, afficher le contenu
        return child;
      },
    );
  }
}


