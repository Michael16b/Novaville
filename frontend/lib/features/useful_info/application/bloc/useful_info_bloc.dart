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
    // Si déjà chargé, on évite de recharger inutilement
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
    // On garde l'ancien contenu si on l'a
    final previousInfo = switch (state) {
      UsefulInfoLoaded s => s.info,
      UsefulInfoSaving s => s.info,
      _ => null,
    };

    emit(UsefulInfoSaving(previousInfo ?? event.info));

    try {
      await repository.saveUsefulInfo(event.info);

      // Après save, on affiche l'info sauvegardée.
      // (Option: re-fetch serveur si tu veux être 100% sync)
      emit(UsefulInfoLoaded(event.info));
    } catch (e) {
      // En cas d'erreur on revient à l'écran précédent si possible
      if (previousInfo != null) {
        emit(UsefulInfoLoaded(previousInfo));
      } else {
        emit(UsefulInfoFailure(_humanizeError(e)));
      }
    }
  }

  String _humanizeError(Object e) {
    // Tu peux mapper tes erreurs réseau ici
    return e.toString();
  }
}
