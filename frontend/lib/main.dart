import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/app/app.dart';
import 'package:frontend/config/app_config.dart';
import 'package:frontend/core/bloc/app_bloc_observer.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/features/auth/data/auth_repository.dart';
import 'package:frontend/features/auth/data/auth_repository_factory.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  // Initialize French locale for table_calendar day/month names.
  await initializeDateFormatting('fr_FR');

  Bloc.observer = AppBlocObserver();
  runApp(
    RepositoryProvider<IAuthRepository>(
      create: (_) => createRemoteAuthRepository(baseUrl: AppConfig.apiBaseUrl),
      child: BlocProvider<AuthBloc>(
        create: (context) =>
            AuthBloc(repository: context.read<IAuthRepository>())
              ..add(const AuthStarted()),
        child: const App(),
      ),
    ),
  );
}
