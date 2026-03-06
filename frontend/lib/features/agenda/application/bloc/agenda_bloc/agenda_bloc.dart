import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/features/agenda/data/event_repository.dart';
import 'package:frontend/features/agenda/data/models/community_event.dart';

part 'agenda_event.dart';
part 'agenda_state.dart';

/// BLoC for managing the participatory agenda.
///
/// Handles loading, searching, theme filtering,
/// creation, update and deletion of events.
/// For the calendar view, all pages are fetched in a loop
/// (the Django backend returns a fixed page size of 20).
class AgendaBloc extends Bloc<AgendaEvent, AgendaState> {
  /// Creates an [AgendaBloc].
  AgendaBloc({required IEventRepository repository})
      : _repository = repository,
        super(const AgendaState.initial()) {
    on<AgendaLoadRequested>(_onLoadRequested);
    on<AgendaSearchRequested>(_onSearchRequested);
    on<AgendaSortRequested>(_onSortRequested);
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

  // Last ordering used for reload after CRUD
  String? _lastOrdering;

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
    _lastOrdering = event.ordering;
    await _loadAllEvents(
      emit: emit,
      ordering: event.ordering,
      search: event.search ?? '',
    );
  }

  Future<void> _onSearchRequested(
    AgendaSearchRequested event,
    Emitter<AgendaState> emit,
  ) async {
    emit(state.copyWith(status: AgendaStatus.loading));
    _lastOrdering = event.ordering;
    await _loadAllEvents(
      emit: emit,
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
    emit(state.copyWith(status: AgendaStatus.loading));
    _lastOrdering = ordering;
    await _loadAllEvents(
      emit: emit,
      ordering: ordering,
      search: event.search ?? state.search,
    );
  }

  Future<void> _onRefreshRequested(
    AgendaRefreshRequested event,
    Emitter<AgendaState> emit,
  ) async {
    emit(state.copyWith(status: AgendaStatus.loading));
    await _loadAllEvents(
      emit: emit,
      ordering: _lastOrdering,
      search: state.search,
    );
  }

  Future<void> _onFilterRequested(
    AgendaFilterRequested event,
    Emitter<AgendaState> emit,
  ) async {
    _filterThemeTitle = event.themeTitle;
    _filterStartDateGte = event.startDateGte;
    _lastOrdering = event.ordering;
    emit(state.copyWith(status: AgendaStatus.loading));
    await _loadAllEvents(
      emit: emit,
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
      // Reload all events
      await _loadAllEvents(
        emit: emit,
        ordering: _lastOrdering,
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
      await _loadAllEvents(
        emit: emit,
        ordering: _lastOrdering,
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
      await _loadAllEvents(
        emit: emit,
        ordering: _lastOrdering,
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

  /// Loads ALL events by iterating through every page of the
  /// Django paginated API (fixed page size of 20).
  /// This is required for the calendar view to display markers
  /// on every day that has events.
  Future<void> _loadAllEvents({
    required Emitter<AgendaState> emit,
    required String? ordering,
    required String search,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final allEvents = <CommunityEvent>[];
      var page = 1;
      var hasMore = true;

      while (hasMore) {
        final result = await _repository.listEvents(
          page: page,
          ordering: ordering,
          search: search,
          theme: resolveThemeId(_filterThemeTitle),
          startDateGte: _filterStartDateGte,
        );
        allEvents.addAll(result.results);

        // If there is no next page URL, we have loaded everything.
        hasMore = result.next != null;
        page++;
      }

      // Minimum skeleton duration to avoid flash
      final elapsed = stopwatch.elapsed;
      if (elapsed < _minimumSkeletonDuration) {
        await Future<void>.delayed(_minimumSkeletonDuration - elapsed);
      }

      emit(
        AgendaState.loaded(
          allEvents,
          count: allEvents.length,
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

