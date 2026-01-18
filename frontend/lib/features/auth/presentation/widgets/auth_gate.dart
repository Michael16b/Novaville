import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/features/auth/presentation/pages/login_page.dart';
import 'package:frontend/features/home/presentation/pages/home_page.dart';
import 'package:frontend/ui/layouts/secured_layout.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        switch (state.status) {
          case AuthStatus.checking:
          case AuthStatus.authenticating:
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          case AuthStatus.authenticated:
            return const SecuredLayout(isHomePage: true, child: HomePage());
          case AuthStatus.failure:
          case AuthStatus.unauthenticated:
            return const LoginPage();
        }
      },
    );
  }
}
