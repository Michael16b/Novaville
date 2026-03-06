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
class AgendaState extends Equatable {
  /// Creates an [AgendaState].
  const AgendaState({
    required this.status,
    this.events = const <CommunityEvent>[],
    this.error,
    this.page = 1,
    this.count = 0,
    this.next,
    this.previous,
    this.pageSize = 20,
    this.search = '',
  });

  /// Initial state.
  const AgendaState.initial()
      : status = AgendaStatus.initial,
        events = const <CommunityEvent>[],
        error = null,
        page = 1,
        count = 0,
        next = null,
        previous = null,
        pageSize = 20,
        search = '';

  /// Loading state.
  const AgendaState.loading()
      : status = AgendaStatus.loading,
        events = const <CommunityEvent>[],
        error = null,
        page = 1,
        count = 0,
        next = null,
        previous = null,
        pageSize = 20,
        search = '';

  /// Loaded state.
  const AgendaState.loaded(
    this.events, {
    required this.page,
    required this.count,
    this.next,
    this.previous,
    this.pageSize = 20,
    this.search = '',
  })  : status = AgendaStatus.loaded,
        error = null;

  /// Failure state.
  const AgendaState.failure(String message)
      : status = AgendaStatus.failure,
        events = const <CommunityEvent>[],
        error = message,
        page = 1,
        count = 0,
        next = null,
        previous = null,
        pageSize = 20,
        search = '';

  /// Current status.
  final AgendaStatus status;

  /// List of events.
  final List<CommunityEvent> events;

  /// Optional error message.
  final String? error;

  /// Current page.
  final int page;

  /// Total event count.
  final int count;

  /// Next page URL.
  final String? next;

  /// Previous page URL.
  final String? previous;

  /// Page size.
  final int pageSize;

  /// Current search query.
  final String search;

  /// Returns a copy with the specified fields replaced.
  AgendaState copyWith({
    AgendaStatus? status,
    List<CommunityEvent>? events,
    String? error,
    int? page,
    int? count,
    String? next,
    String? previous,
    int? pageSize,
    String? search,
  }) {
    return AgendaState(
      status: status ?? this.status,
      events: events ?? this.events,
      error: error ?? this.error,
      page: page ?? this.page,
      count: count ?? this.count,
      next: next ?? this.next,
      previous: previous ?? this.previous,
      pageSize: pageSize ?? this.pageSize,
      search: search ?? this.search,
    );
  }

  @override
  List<Object?> get props => [
        status,
        events,
        error,
        page,
        count,
        next,
        previous,
        pageSize,
        search,
      ];
}

