import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:frontend/app/app.dart';
import 'package:frontend/core/api_config.dart';
import 'package:frontend/core/bloc/app_bloc_observer.dart';

import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/features/auth/data/auth_repository.dart';
import 'package:frontend/features/auth/data/auth_repository_factory.dart';

import 'package:frontend/features/useful_info/application/bloc/useful_info_bloc.dart';
import 'package:frontend/features/useful_info/data/useful_info_api.dart';
import 'package:frontend/features/useful_info/data/useful_info_repository.dart';
import 'package:frontend/features/useful_info/data/useful_info_repository_impl.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  Bloc.observer = AppBlocObserver();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<IAuthRepository>(
          create: (_) => createRemoteAuthRepository(baseUrl: apiBaseUrl),
        ),
        RepositoryProvider<UsefulInfoRepository>(
          create: (_) =>
              UsefulInfoRepositoryImpl(
                UsefulInfoApi(
                  client: http.Client(),
                  baseUrl: apiBaseUrl,
                ),
              ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) =>
                AuthBloc(repository: context.read<IAuthRepository>())
                  ..add(const AuthStarted()),
          ),
          BlocProvider<UsefulInfoBloc>(
            create: (context) => UsefulInfoBloc(
              repository: context.read<UsefulInfoRepository>(),
            ),
          ),
        ],
        child: const App(),
      ),
    ),
  );
}
