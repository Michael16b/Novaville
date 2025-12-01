import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/app/app.dart';
import 'package:frontend/core/api_config.dart';
import 'package:frontend/core/bloc/app_bloc_observer.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/features/auth/data/auth_repository.dart';
import 'package:frontend/features/auth/data/auth_repository_factory.dart';
import 'package:frontend/features/auth/presentation/widgets/auth_gate.dart';
import 'package:frontend/features/items/application/bloc/item_bloc.dart';
import 'package:frontend/features/items/data/item_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  Bloc.observer = AppBlocObserver();
  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<IItemRepository>(
          create: (_) => FakeItemRepository(),
        ),
        RepositoryProvider<IAuthRepository>(
          create: (_) => createRemoteAuthRepository(baseUrl: apiBaseUrl),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ItemBloc>(
            create: (context) =>
                ItemBloc(repository: context.read<IItemRepository>()),
          ),
          BlocProvider<AuthBloc>(
            create: (context) =>
                AuthBloc(repository: context.read<IAuthRepository>())
                  ..add(const AuthStarted()),
          ),
        ],
        child: const App(home: AuthGate()),
      ),
    ),
  );
}
