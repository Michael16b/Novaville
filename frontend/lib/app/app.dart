import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:frontend/config/router.dart';
import 'package:frontend/config/theme.dart';
import 'package:frontend/constants/texts/texts_general.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:go_router/go_router.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  GoRouter? _router;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _router = buildRouter(context.read<AuthBloc>());
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _router?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_router == null) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return MaterialApp.router(
      routerConfig: _router!,
      title: AppTextsGeneral.appName,
      theme: AppTheme.lightTheme,
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [
        Locale('fr', 'FR'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
