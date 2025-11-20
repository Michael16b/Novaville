import 'package:flutter/material.dart';
import 'package:frontend/constantes/_colors.dart';

class App extends StatelessWidget {
  const App({required this.home, super.key});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Novaville',
      theme: ThemeData(
        fontFamily: 'Montserrat',
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.page,
      ),
      home: home,
    );
  }
}
