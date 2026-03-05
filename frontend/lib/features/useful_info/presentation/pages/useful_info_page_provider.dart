import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:frontend/features/useful_info/application/bloc/useful_info_bloc.dart';
import 'package:frontend/features/useful_info/application/bloc/useful_info_event.dart';
import 'package:frontend/features/useful_info/data/useful_info_repository_factory.dart';

import 'useful_info_page.dart';

class UsefulInfoPageProvider extends StatelessWidget {
  const UsefulInfoPageProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UsefulInfoBloc>(
      create: (context) =>
          UsefulInfoBloc(repository: createUsefulInfoRepository())
            ..add(const UsefulInfoRequested()),
      child: const UsefulInfoPage(),
    );
  }
}
