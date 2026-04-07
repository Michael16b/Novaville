import 'dart:convert';

import 'package:frontend/constants/texts/texts_agenda.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/agenda/data/event_repository.dart';
import 'package:frontend/features/agenda/data/models/community_event.dart';

/// HTTP-based implementation of [IEventRepository].
class EventRepositoryImpl implements IEventRepository {
  /// Creates an [EventRepositoryImpl].
  EventRepositoryImpl({
    required ApiClient publicApiClient,
    required ApiClient authenticatedApiClient,
  })  : _publicApiClient = publicApiClient,
        _authenticatedApiClient = authenticatedApiClient;

  final ApiClient _publicApiClient;
  final ApiClient _authenticatedApiClient;

  @override
  Future<List<ThemeItem>> listThemes() async {
    final response = await _publicApiClient.get('/api/v1/event-themes/');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      // The endpoint may return a paginated response or a raw list.
      final List<dynamic> items;
      if (decoded is List) {
        items = decoded;
      } else if (decoded is Map<String, dynamic> &&
          decoded['results'] != null) {
        items = decoded['results'] as List<dynamic>;
      } else {
        throw Exception(AgendaTexts.invalidResponseFormat);
      }
      return items
          .map((e) => ThemeItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
        '${AgendaTexts.fetchThemesError}: ${response.statusCode}',
      );
    }
  }

  @override
  Future<EventPage> listEvents({
    String? ordering,
    String? search,
    int page = 1,
    int? theme,
    DateTime? startDateGte,
    DateTime? startDateLte,
  }) async {
    var url = '/api/v1/events/?page=$page';
    if (ordering != null && ordering.isNotEmpty) {
      url += '&ordering=$ordering';
    }
    if (search != null && search.trim().isNotEmpty) {
      url += '&search=${Uri.encodeQueryComponent(search.trim())}';
    }
    if (theme != null) {
      url += '&theme=$theme';
    }
    if (startDateGte != null) {
      url += '&start_date__gte=${startDateGte.toUtc().toIso8601String()}';
    }
    if (startDateLte != null) {
      url += '&start_date__lte=${startDateLte.toUtc().toIso8601String()}';
    }

    final response = await _publicApiClient.get(url);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        if (decoded['results'] != null) {
          return EventPage.fromJson(decoded);
        }
        throw Exception(AgendaTexts.invalidResponseFormat);
      }
      // The /events/ API may return a raw array (without pagination)
      // when the queryset is not paginated.
      if (decoded is List) {
        return EventPage(
          count: decoded.length,
          results: decoded
              .map(
                (r) =>
                    CommunityEvent.fromJson(r as Map<String, dynamic>),
              )
              .toList(),
        );
      }
      throw Exception(AgendaTexts.invalidResponseFormat);
    } else {
      throw Exception(
        '${AgendaTexts.fetchEventsError}: ${response.statusCode}',
      );
    }
  }

  @override
  Future<CommunityEvent> getEvent({required int eventId}) async {
    final response = await _publicApiClient.get('/api/v1/events/$eventId/');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return CommunityEvent.fromJson(json);
    } else {
      throw Exception(
        '${AgendaTexts.fetchEventError}: ${response.statusCode}',
      );
    }
  }

  @override
  Future<void> createEvent({
    required String title,
    required String description,
    required DateTime startDate,
    required DateTime endDate,
    int? theme,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'description': description,
      'start_date': startDate.toUtc().toIso8601String(),
      'end_date': endDate.toUtc().toIso8601String(),
    };
    if (theme != null) body['theme'] = theme;

    final response = await _authenticatedApiClient.post(
      '/api/v1/events/',
      body: body,
    );

    if (response.statusCode != 201) {
      throw Exception(
        '${AgendaTexts.createEventError}: ${response.statusCode}',
      );
    }
  }

  @override
  Future<CommunityEvent> updateEvent({
    required int eventId,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    int? theme,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (startDate != null) {
      body['start_date'] = startDate.toUtc().toIso8601String();
    }
    if (endDate != null) {
      body['end_date'] = endDate.toUtc().toIso8601String();
    }
    if (theme != null) body['theme'] = theme;

    final response = await _authenticatedApiClient.patch(
      '/api/v1/events/$eventId/',
      body: body,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return CommunityEvent.fromJson(json);
    } else {
      throw Exception(
        '${AgendaTexts.updateEventError}: ${response.statusCode}',
      );
    }
  }

  @override
  Future<void> deleteEvent({required int eventId}) async {
    final response = await _authenticatedApiClient.delete(
      '/api/v1/events/$eventId/',
    );

    if (response.statusCode != 204) {
      throw Exception(
        '${AgendaTexts.deleteEventError}: ${response.statusCode}',
      );
    }
  }
}
