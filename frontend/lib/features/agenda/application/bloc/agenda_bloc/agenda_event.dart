part of 'agenda_bloc.dart';

/// Base class for all agenda BLoC events.
abstract class AgendaEvent extends Equatable {
  const AgendaEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load events initially.
class AgendaLoadRequested extends AgendaEvent {
  /// Creates an [AgendaLoadRequested].
  const AgendaLoadRequested({this.ordering, this.search});

  /// Ordering field.
  final String? ordering;

  /// Search query.
  final String? search;

  @override
  List<Object?> get props => [ordering, search];
}

/// Event to search events.
class AgendaSearchRequested extends AgendaEvent {
  /// Creates an [AgendaSearchRequested].
  const AgendaSearchRequested({required this.query, this.ordering});

  /// Search query.
  final String query;

  /// Ordering field.
  final String? ordering;

  @override
  List<Object?> get props => [query, ordering];
}

/// Event to sort events.
class AgendaSortRequested extends AgendaEvent {
  /// Creates an [AgendaSortRequested].
  const AgendaSortRequested({
    required this.column,
    required this.ascending,
    this.search,
  });

  /// Sort column key.
  final String column;

  /// Whether to sort ascending.
  final bool ascending;

  /// Current search query.
  final String? search;

  @override
  List<Object?> get props => [column, ascending, search];
}

/// Event to request a specific page.
class AgendaPageRequested extends AgendaEvent {
  /// Creates an [AgendaPageRequested].
  const AgendaPageRequested({
    required this.page,
    this.ordering,
    this.search,
  });

  /// Page number.
  final int page;

  /// Ordering field.
  final String? ordering;

  /// Current search query.
  final String? search;

  @override
  List<Object?> get props => [page, ordering, search];
}

/// Event to refresh the events list.
class AgendaRefreshRequested extends AgendaEvent {
  /// Creates an [AgendaRefreshRequested].
  const AgendaRefreshRequested();
}

/// Event to apply filters (theme, date).
class AgendaFilterRequested extends AgendaEvent {
  /// Creates an [AgendaFilterRequested].
  const AgendaFilterRequested({
    this.themeTitle,
    this.startDateGte,
    this.ordering,
    this.search,
  });

  /// Filter by theme title (e.g. 'Sport', 'Culture').
  final String? themeTitle;

  /// Filter by minimum start date.
  final DateTime? startDateGte;

  /// Ordering field.
  final String? ordering;

  /// Search query.
  final String? search;

  @override
  List<Object?> get props => [themeTitle, startDateGte, ordering, search];
}

/// Event to create a new community event.
class AgendaEventCreateRequested extends AgendaEvent {
  /// Creates an [AgendaEventCreateRequested].
  const AgendaEventCreateRequested({
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    this.theme,
  });

  /// Event title.
  final String title;

  /// Event description.
  final String description;

  /// Start date.
  final DateTime startDate;

  /// End date.
  final DateTime endDate;

  /// Theme ID.
  final int? theme;

  @override
  List<Object?> get props => [title, description, startDate, endDate, theme];
}

/// Event to delete a community event.
class AgendaEventDeleteRequested extends AgendaEvent {
  /// Creates an [AgendaEventDeleteRequested].
  const AgendaEventDeleteRequested({required this.eventId});

  /// ID of the event to delete.
  final int eventId;

  @override
  List<Object?> get props => [eventId];
}

/// Event to update a community event.
class AgendaEventUpdateRequested extends AgendaEvent {
  /// Creates an [AgendaEventUpdateRequested].
  const AgendaEventUpdateRequested({
    required this.eventId,
    this.title,
    this.description,
    this.startDate,
    this.endDate,
    this.theme,
  });

  /// Event ID.
  final int eventId;

  /// New title.
  final String? title;

  /// New description.
  final String? description;

  /// New start date.
  final DateTime? startDate;

  /// New end date.
  final DateTime? endDate;

  /// New theme.
  final int? theme;

  @override
  List<Object?> get props =>
      [eventId, title, description, startDate, endDate, theme];
}

