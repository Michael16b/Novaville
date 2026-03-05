import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/useful_info_repository.dart';
import '../../domain/useful_info.dart';
import 'useful_info_event.dart';
import 'useful_info_state.dart';

class UsefulInfoBloc extends Bloc<UsefulInfoEvent, UsefulInfoState> {
  final UsefulInfoRepository repository;

  UsefulInfoBloc({required this.repository})
    : super(const UsefulInfoInitial()) {
    on<UsefulInfoRequested>(_onRequested);
    on<UsefulInfoRefreshed>(_onRefreshed);
    on<UsefulInfoSaved>(_onSaved);
  }

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
      final UsefulInfo info = await repository.getUsefulInfo();
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
      UsefulInfoLoaded s => s.info,
      UsefulInfoSaving s => s.info,
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
