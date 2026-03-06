import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/features/agenda/data/event_repository.dart';
import 'package:frontend/features/agenda/data/models/community_event.dart';

part 'agenda_event.dart';
part 'agenda_state.dart';

/// BLoC for managing the participatory agenda.
///
/// Handles loading, searching, theme filtering,
/// pagination, creation and deletion of events.
class AgendaBloc extends Bloc<AgendaEvent, AgendaState> {
  /// Creates an [AgendaBloc].
  AgendaBloc({required IEventRepository repository})
      : _repository = repository,
        super(const AgendaState.initial()) {
    on<AgendaLoadRequested>(_onLoadRequested);
    on<AgendaSearchRequested>(_onSearchRequested);
    on<AgendaSortRequested>(_onSortRequested);
    on<AgendaPageRequested>(_onPageRequested);
    on<AgendaRefreshRequested>(_onRefreshRequested);
    on<AgendaFilterRequested>(_onFilterRequested);
    on<AgendaEventCreateRequested>(_onCreateRequested);
    on<AgendaEventDeleteRequested>(_onDeleteRequested);
    on<AgendaEventUpdateRequested>(_onUpdateRequested);
  }

  final IEventRepository _repository;

  // Active filters
  String? _filterThemeTitle;
  DateTime? _filterStartDateGte;

  // Cached theme items from the backend (id ↔ title mapping).
  List<ThemeItem> _cachedThemes = [];

  static const Duration _minimumSkeletonDuration =
      Duration(milliseconds: 300);

  /// Resolves a theme title to its backend ID.
  /// Returns null if not found.
  int? resolveThemeId(String? title) {
    if (title == null) return null;
    final normalized = title.trim().toLowerCase();
    for (final t in _cachedThemes) {
      if (t.title.trim().toLowerCase() == normalized) {
        return t.id;
      }
    }
    return null;
  }

  // ─── Loading ───────────────────────────────────────────────────

  Future<void> _onLoadRequested(
    AgendaLoadRequested event,
    Emitter<AgendaState> emit,
  ) async {
    emit(const AgendaState.loading());
    // Load available themes on first load for ID resolution.
    if (_cachedThemes.isEmpty) {
      try {
        _cachedThemes = await _repository.listThemes();
      } catch (_) {
        // Non-blocking: filters/CRUD will still work if themes
        // can be resolved from loaded events.
      }
    }
    await _loadPage(
      emit: emit,
      page: 1,
      ordering: event.ordering,
      search: event.search ?? '',
    );
  }

  Future<void> _onSearchRequested(
    AgendaSearchRequested event,
    Emitter<AgendaState> emit,
  ) async {
    await _loadPage(
      emit: emit,
      page: 1,
      ordering: event.ordering,
      search: event.query,
    );
  }

  Future<void> _onSortRequested(
    AgendaSortRequested event,
    Emitter<AgendaState> emit,
  ) async {
    final ordering =
        event.ascending ? event.column : '-${event.column}';
    await _loadPage(
      emit: emit,
      page: 1,
      ordering: ordering,
      search: event.search ?? state.search,
    );
  }

  Future<void> _onPageRequested(
    AgendaPageRequested event,
    Emitter<AgendaState> emit,
  ) async {
    emit(state.copyWith(status: AgendaStatus.loading));
    await _loadPage(
      emit: emit,
      page: event.page,
      ordering: event.ordering,
      search: event.search ?? state.search,
    );
  }

  Future<void> _onRefreshRequested(
    AgendaRefreshRequested event,
    Emitter<AgendaState> emit,
  ) async {
    await _loadPage(
      emit: emit,
      page: state.page,
      ordering: null,
      search: state.search,
    );
  }

  Future<void> _onFilterRequested(
    AgendaFilterRequested event,
    Emitter<AgendaState> emit,
  ) async {
    _filterThemeTitle = event.themeTitle;
    _filterStartDateGte = event.startDateGte;
    emit(state.copyWith(status: AgendaStatus.loading));
    await _loadPage(
      emit: emit,
      page: 1,
      ordering: event.ordering,
      search: event.search ?? state.search,
    );
  }

  // ─── CRUD ──────────────────────────────────────────────────────

  Future<void> _onCreateRequested(
    AgendaEventCreateRequested event,
    Emitter<AgendaState> emit,
  ) async {
    emit(state.copyWith(status: AgendaStatus.creating));
    try {
      await _repository.createEvent(
        title: event.title,
        description: event.description,
        startDate: event.startDate,
        endDate: event.endDate,
        theme: event.theme,
      );
      emit(state.copyWith(status: AgendaStatus.created));
      // Reload the list
      await _loadPage(
        emit: emit,
        page: 1,
        ordering: null,
        search: state.search,
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AgendaStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onDeleteRequested(
    AgendaEventDeleteRequested event,
    Emitter<AgendaState> emit,
  ) async {
    emit(state.copyWith(status: AgendaStatus.deleting));
    try {
      await _repository.deleteEvent(eventId: event.eventId);
      final updatedEvents = state.events
          .where((e) => e.id != event.eventId)
          .toList();
      emit(
        state.copyWith(
          status: AgendaStatus.deleted,
          events: updatedEvents,
          count: state.count - 1,
        ),
      );
      // Reload to synchronize
      await _loadPage(
        emit: emit,
        page: state.page,
        ordering: null,
        search: state.search,
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AgendaStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onUpdateRequested(
    AgendaEventUpdateRequested event,
    Emitter<AgendaState> emit,
  ) async {
    emit(state.copyWith(status: AgendaStatus.updating));
    try {
      await _repository.updateEvent(
        eventId: event.eventId,
        title: event.title,
        description: event.description,
        startDate: event.startDate,
        endDate: event.endDate,
        theme: event.theme,
      );
      emit(state.copyWith(status: AgendaStatus.updated));
      await _loadPage(
        emit: emit,
        page: state.page,
        ordering: null,
        search: state.search,
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AgendaStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  // ─── Internal helper ───────────────────────────────────────────

  Future<void> _loadPage({
    required Emitter<AgendaState> emit,
    required int page,
    required String? ordering,
    required String search,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await _repository.listEvents(
        page: page,
        ordering: ordering,
        search: search,
        theme: resolveThemeId(_filterThemeTitle),
        startDateGte: _filterStartDateGte,
      );

      // Minimum skeleton duration to avoid flash
      final elapsed = stopwatch.elapsed;
      if (elapsed < _minimumSkeletonDuration) {
        await Future<void>.delayed(_minimumSkeletonDuration - elapsed);
      }

      emit(
        AgendaState.loaded(
          result.results,
          page: page,
          count: result.count,
          next: result.next,
          previous: result.previous,
          search: search,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AgendaStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }
}

