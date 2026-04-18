import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/features/surveys/data/models/survey.dart';
import 'package:frontend/features/surveys/data/survey_repository.dart';
import 'package:frontend/features/users/data/models/user_role.dart';

part 'surveys_event.dart';
part 'surveys_state.dart';

/// BLoC managing survey listing, creation, deletion, filtering and voting.
class SurveysBloc extends Bloc<SurveysEvent, SurveysState> {
  /// Creates a [SurveysBloc].
  SurveysBloc({required ISurveyRepository repository})
      : _repository = repository,
        super(const SurveysState.initial()) {
    on<SurveysLoadRequested>(_onLoadRequested);
    on<SurveysFilterChanged>(_onFilterChanged);
    on<SurveysPageRequested>(_onPageRequested);
    on<SurveyCreateRequested>(_onCreateRequested);
    on<SurveyDeleteRequested>(_onDeleteRequested);
    on<SurveyUpdateRequested>(_onUpdateRequested);
    on<SurveyVoteRequested>(_onVoteRequested);
  }

  final ISurveyRepository _repository;

  String _exactAddress = '';
  UserRole? _citizenTarget;
  String _ordering = '-created_at';

  int _extractPageNumber(String? previous) {
    if (previous == null) return 1;
    final uri = Uri.tryParse(previous);
    if (uri == null) return 1;
    final prevPage = int.tryParse(uri.queryParameters['page'] ?? '1') ?? 1;
    return prevPage + 1;
  }

  Future<void> _onLoadRequested(
    SurveysLoadRequested event,
    Emitter<SurveysState> emit,
  ) async {
    if (event.exactAddress != null) {
      _exactAddress = event.exactAddress!.trim();
    }
    if (event.citizenTargetSet) {
      _citizenTarget = event.citizenTarget;
    }
    if (event.ordering != null && event.ordering!.isNotEmpty) {
      _ordering = event.ordering!;
    }

    emit(
      state.copyWith(
        status: SurveysStatus.loading,
        exactAddress: _exactAddress,
        citizenTarget: _citizenTarget,
        ordering: _ordering,
        page: event.page,
      ),
    );

    try {
      final page = await _repository.listSurveys(
        exactAddress: _exactAddress,
        citizenTarget: _citizenTarget,
        ordering: _ordering,
        page: event.page,
      );
      final pageNumber = _extractPageNumber(page.previous);

      emit(
        state.copyWith(
          status: SurveysStatus.loaded,
          surveys: page.results,
          count: page.count,
          page: pageNumber,
          next: page.next,
          previous: page.previous,
          exactAddress: _exactAddress,
          citizenTarget: _citizenTarget,
          ordering: _ordering,
          error: null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: SurveysStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onFilterChanged(
    SurveysFilterChanged event,
    Emitter<SurveysState> emit,
  ) async {
    add(
      SurveysLoadRequested(
        exactAddress: event.exactAddress,
        citizenTarget: event.citizenTarget,
        ordering: event.ordering,
        page: event.page,
        citizenTargetSet: event.citizenTargetSet,
      ),
    );
  }

  Future<void> _onPageRequested(
    SurveysPageRequested event,
    Emitter<SurveysState> emit,
  ) async {
    add(
      SurveysLoadRequested(
        exactAddress: _exactAddress,
        citizenTarget: _citizenTarget,
        ordering: _ordering,
        page: event.page,
        citizenTargetSet: true,
      ),
    );
  }

  Future<void> _onCreateRequested(
    SurveyCreateRequested event,
    Emitter<SurveysState> emit,
  ) async {
    emit(state.copyWith(status: SurveysStatus.creating));
    try {
      await _repository.createSurvey(
        question: event.question,
        description: event.description,
        address: event.address,
        options: event.options,
        citizenTarget: event.citizenTarget,
      );

      emit(state.copyWith(status: SurveysStatus.created, error: null));
      add(
        SurveysLoadRequested(
          exactAddress: _exactAddress,
          citizenTarget: _citizenTarget,
          ordering: _ordering,
          citizenTargetSet: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: SurveysStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onDeleteRequested(
    SurveyDeleteRequested event,
    Emitter<SurveysState> emit,
  ) async {
    emit(state.copyWith(status: SurveysStatus.deleting));
    try {
      await _repository.deleteSurvey(surveyId: event.surveyId);
      emit(state.copyWith(status: SurveysStatus.deleted, error: null));
      add(
        SurveysLoadRequested(
          exactAddress: _exactAddress,
          citizenTarget: _citizenTarget,
          ordering: _ordering,
          citizenTargetSet: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: SurveysStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onUpdateRequested(
    SurveyUpdateRequested event,
    Emitter<SurveysState> emit,
  ) async {
    emit(state.copyWith(status: SurveysStatus.updating));
    try {
      await _repository.updateSurvey(
        surveyId: event.surveyId,
        question: event.question,
        description: event.description,
        address: event.address,
        citizenTarget: event.citizenTarget,
      );
      emit(state.copyWith(status: SurveysStatus.updated, error: null));
      add(
        SurveysLoadRequested(
          exactAddress: _exactAddress,
          citizenTarget: _citizenTarget,
          ordering: _ordering,
          citizenTargetSet: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: SurveysStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onVoteRequested(
    SurveyVoteRequested event,
    Emitter<SurveysState> emit,
  ) async {
    emit(state.copyWith(status: SurveysStatus.voting));
    try {
      await _repository.vote(surveyId: event.surveyId, optionId: event.optionId);
      emit(state.copyWith(status: SurveysStatus.voted, error: null));
      add(
        SurveysLoadRequested(
          exactAddress: _exactAddress,
          citizenTarget: _citizenTarget,
          ordering: _ordering,
          citizenTargetSet: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: SurveysStatus.failure, error: e.toString()));
    }
  }
}

