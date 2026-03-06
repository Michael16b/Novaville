part of 'agenda_bloc.dart';

/// Possible statuses for the AgendaBloc.
enum AgendaStatus {
  /// Initial state.
  initial,

  /// Loading in progress.
  loading,

  /// Events loaded successfully.
  loaded,

  /// An error occurred.
  failure,

  /// Creating an event.
  creating,

  /// Event created successfully.
  created,

  /// Deleting an event.
  deleting,

  /// Event deleted successfully.
  deleted,

  /// Updating an event.
  updating,

  /// Event updated successfully.
  updated,
}

/// State for the AgendaBloc.
///
/// All events are loaded at once (all pages fetched in a loop)
/// so pagination fields (page, next, previous, pageSize) are no
/// longer needed for the calendar view.
class AgendaState extends Equatable {
  /// Creates an [AgendaState].
  const AgendaState({
    required this.status,
    this.events = const <CommunityEvent>[],
    this.error,
    this.count = 0,
    this.search = '',
  });

  /// Initial state.
  const AgendaState.initial()
      : status = AgendaStatus.initial,
        events = const <CommunityEvent>[],
        error = null,
        count = 0,
        search = '';

  /// Loading state.
  const AgendaState.loading()
      : status = AgendaStatus.loading,
        events = const <CommunityEvent>[],
        error = null,
        count = 0,
        search = '';

  /// Loaded state with all events.
  const AgendaState.loaded(
    this.events, {
    required this.count,
    this.search = '',
  })  : status = AgendaStatus.loaded,
        error = null;

  /// Failure state.
  const AgendaState.failure(String message)
      : status = AgendaStatus.failure,
        events = const <CommunityEvent>[],
        error = message,
        count = 0,
        search = '';

  /// Current status.
  final AgendaStatus status;

  /// List of ALL events (loaded across all pages).
  final List<CommunityEvent> events;

  /// Optional error message.
  final String? error;

  /// Total event count.
  final int count;

  /// Current search query.
  final String search;

  /// Returns a copy with the specified fields replaced.
  AgendaState copyWith({
    AgendaStatus? status,
    List<CommunityEvent>? events,
    String? error,
    int? count,
    String? search,
  }) {
    return AgendaState(
      status: status ?? this.status,
      events: events ?? this.events,
      error: error ?? this.error,
      count: count ?? this.count,
      search: search ?? this.search,
    );
  }

  @override
  List<Object?> get props => [
        status,
        events,
        error,
        count,
        search,
      ];
}

