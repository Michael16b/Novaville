import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/config/router.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_general.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:go_router/go_router.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // AuthBloc is available via context.read because App is a child of BlocProvider
    final authBloc = context.read<AuthBloc>();
    _router = buildRouter(authBloc);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      title: AppTextsGeneral.appName,
      theme: ThemeData(
        fontFamily: 'Montserrat',
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.page,
      ),
    );
  }
}
