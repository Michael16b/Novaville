import 'package:frontend/features/surveys/data/models/survey.dart';
import 'package:frontend/features/users/data/models/user_role.dart';

/// Paginated response for surveys.
class SurveyPage {
  /// Creates a [SurveyPage].
  const SurveyPage({
    required this.count,
    required this.results,
    this.next,
    this.previous,
  });

  /// Builds a [SurveyPage] from API JSON payload.
  factory SurveyPage.fromJson(Map<String, dynamic> json) {
    return SurveyPage(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>)
          .map((item) => Survey.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Total number of surveys.
  final int count;

  /// Next page URL.
  final String? next;

  /// Previous page URL.
  final String? previous;

  /// Current page surveys.
  final List<Survey> results;
}

/// Repository contract for surveys.
abstract class ISurveyRepository {
  /// Lists surveys with optional exact address and target filters.
  Future<SurveyPage> listSurveys({
    String? exactAddress,
    UserRole? citizenTarget,
    String? ordering,
    int page = 1,
  });

  /// Creates a survey (staff only).
  Future<void> createSurvey({
    required String question,
    required String description,
    required String address,
    required List<String> options,
    UserRole? citizenTarget,
  });

  /// Updates a survey (staff only).
  Future<void> updateSurvey({
    required int surveyId,
    required String question,
    required String description,
    required String address,
    UserRole? citizenTarget,
  });

  /// Deletes a survey (staff only).
  Future<void> deleteSurvey({required int surveyId});

  /// Casts or updates a vote for the current user.
  Future<void> vote({required int surveyId, required int optionId});
}

