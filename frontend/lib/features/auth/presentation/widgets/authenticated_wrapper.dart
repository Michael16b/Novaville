import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';

/// Wrapper that verifies the user is authenticated before displaying content.
/// Tracks whether the user has already been authenticated to avoid a loader
/// flash during navigation (handled by the BlocListener in App).
class AuthenticatedWrapper extends StatefulWidget {
  const AuthenticatedWrapper({required this.child, super.key});

  final Widget child;

  @override
  State<AuthenticatedWrapper> createState() => _AuthenticatedWrapperState();
}

class _AuthenticatedWrapperState extends State<AuthenticatedWrapper> {
  /// Whether the user has already been authenticated during this session.
  /// Prevents a loader flash if the token expires while on a secured page:
  /// the current content stays visible while App handles the redirect.
  bool _hadAuthenticatedSession = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          _hadAuthenticatedSession = true;
          return widget.child;
        }

        // If the user was previously authenticated, keep the content visible
        // while App handles the redirect, avoiding a loader flash.
        if (_hadAuthenticatedSession) {
          return widget.child;
        }

        // Show a loader during the initial check or when unauthenticated.
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
