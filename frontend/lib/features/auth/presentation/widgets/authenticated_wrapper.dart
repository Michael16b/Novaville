import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';

/// Wrapper qui vérifie que l'utilisateur est authentifié avant d'afficher le contenu.
/// Suit si l'utilisateur a déjà été authentifié pour éviter un flash de loader
/// lors de la redirection (gérée par le BlocListener dans App).
class AuthenticatedWrapper extends StatefulWidget {
  const AuthenticatedWrapper({required this.child, super.key});

  final Widget child;

  @override
  State<AuthenticatedWrapper> createState() => _AuthenticatedWrapperState();
}

class _AuthenticatedWrapperState extends State<AuthenticatedWrapper> {
  /// Indique si l'utilisateur a déjà été authentifié au cours de cette session.
  /// Permet d'éviter un flash de loader si le token expire alors qu'il est sur une page sécurisée :
  /// on continue d'afficher le contenu actuel pendant que l'App gère la redirection.
  bool _hadAuthenticatedSession = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          _hadAuthenticatedSession = true;
          return widget.child;
        }

        // Si l'utilisateur a déjà été authentifié, on garde le contenu pendant
        // que l'App gère la redirection, évitant ainsi un flash de loader.
        if (_hadAuthenticatedSession) {
          return widget.child;
        }

        // Pendant la vérification initiale ou si non authentifié, afficher un loader.
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}


