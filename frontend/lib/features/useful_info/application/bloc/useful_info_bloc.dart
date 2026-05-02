import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:frontend/features/useful_info/data/useful_info_repository.dart';
import 'package:frontend/features/useful_info/domain/useful_info.dart';
import 'package:frontend/features/useful_info/application/bloc/useful_info_event.dart';
import 'package:frontend/features/useful_info/application/bloc/useful_info_state.dart';

class UsefulInfoBloc extends Bloc<UsefulInfoEvent, UsefulInfoState> {
  UsefulInfoBloc({required this.repository})
    : super(const UsefulInfoInitial()) {
    on<UsefulInfoRequested>(_onRequested);
    on<UsefulInfoRefreshed>(_onRefreshed);
    on<UsefulInfoSaved>(_onSaved);
  }
  final UsefulInfoRepository repository;

  Future<void> _onRequested(
    UsefulInfoRequested event,
    Emitter<UsefulInfoState> emit,
  ) async {
    if (state is UsefulInfoLoaded) return;

    emit(const UsefulInfoLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _onRefreshed(
    UsefulInfoRefreshed event,
    Emitter<UsefulInfoState> emit,
  ) async {
    // Refresh explicite : on recharge
    emit(const UsefulInfoLoading());
    await _fetchAndEmit(emit);
  }

  Future<void> _fetchAndEmit(Emitter<UsefulInfoState> emit) async {
    try {
      final info = await repository.getUsefulInfo();
      emit(UsefulInfoLoaded(info));
    } catch (e) {
      emit(UsefulInfoFailure(_humanizeError(e)));
    }
  }

  Future<void> _onSaved(
    UsefulInfoSaved event,
    Emitter<UsefulInfoState> emit,
  ) async {
    final previousInfo = switch (state) {
      final UsefulInfoLoaded s => s.info,
      final UsefulInfoSaving s => s.info,
      _ => null,
    };

    emit(UsefulInfoSaving(previousInfo ?? event.info));

    try {
      await repository.saveUsefulInfo(event.info);

      emit(UsefulInfoLoaded(event.info));
    } catch (e) {
      if (previousInfo != null) {
        emit(UsefulInfoLoaded(previousInfo));
      } else {
        emit(UsefulInfoFailure(_humanizeError(e)));
      }
    }
  }

  String _humanizeError(Object e) {
    return e.toString();
  }
}
