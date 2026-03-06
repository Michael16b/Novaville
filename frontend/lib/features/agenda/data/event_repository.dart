import 'package:frontend/features/agenda/data/models/community_event.dart';

/// A theme item returned by the backend.
class ThemeItem {
  /// Creates a [ThemeItem].
  const ThemeItem({required this.id, required this.title});

  /// Creates a [ThemeItem] from a JSON map.
  factory ThemeItem.fromJson(Map<String, dynamic> json) {
    return ThemeItem(
      id: json['id'] as int,
      title: json['title'] as String,
    );
  }

  /// Backend primary key.
  final int id;

  /// Theme title as stored in the database.
  final String title;
}

/// Paginated response for events.
class EventPage {
  /// Creates an [EventPage].
  EventPage({
    required this.count,
    required this.results,
    this.next,
    this.previous,
  });

  /// Creates an [EventPage] from a JSON map.
  factory EventPage.fromJson(Map<String, dynamic> json) {
    return EventPage(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>)
          .map((r) => CommunityEvent.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Total count of events.
  final int count;

  /// URL for the next page.
  final String? next;

  /// URL for the previous page.
  final String? previous;

  /// List of events for the current page.
  final List<CommunityEvent> results;
}

/// Repository interface for event operations.
abstract class IEventRepository {
  /// Retrieves all available event themes.
  Future<List<ThemeItem>> listThemes();

  /// Retrieves a paginated list of events.
  Future<EventPage> listEvents({
    String? ordering,
    String? search,
    int page = 1,
    int? theme,
    DateTime? startDateGte,
  });

  /// Retrieves a single event by ID.
  Future<CommunityEvent> getEvent({required int eventId});

  /// Creates a new event.
  Future<void> createEvent({
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    int? theme,
  });

  /// Updates an existing event.
  Future<CommunityEvent> updateEvent({
    required int eventId,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    int? theme,
  });

  /// Deletes an event.
  Future<void> deleteEvent({required int eventId});
}
