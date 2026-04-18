import 'dart:convert';

import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/surveys/data/survey_repository.dart';
import 'package:frontend/features/users/data/models/user_role.dart';

/// HTTP implementation of [ISurveyRepository].
class SurveyRepositoryImpl implements ISurveyRepository {
  /// Creates a [SurveyRepositoryImpl].
  SurveyRepositoryImpl({
    required ApiClient authenticatedApiClient,
  }) : _authenticatedApiClient = authenticatedApiClient;

  final ApiClient _authenticatedApiClient;

  @override
  Future<SurveyPage> listSurveys({
    String? exactAddress,
    UserRole? citizenTarget,
    String? ordering,
    int page = 1,
  }) async {
    final query = <String, String?>{
      'page': '$page',
      if (exactAddress != null && exactAddress.trim().isNotEmpty)
        'address': exactAddress.trim(),
      if (citizenTarget != null) 'citizen_target': citizenTarget.value,
      'ordering': ordering ?? '-created_at',
    };

    final response = await _authenticatedApiClient.get(
      '/api/v1/surveys/',
      queryParameters: query,
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur chargement sondages: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['results'] == null) {
      throw Exception('Format de reponse invalide pour les sondages.');
    }
    return SurveyPage.fromJson(json);
  }

  @override
  Future<void> createSurvey({
    required String question,
    required String description,
    required String address,
    required List<String> options,
    UserRole? citizenTarget,
  }) async {
    final startDate = DateTime.now().toUtc();
    final endDate = startDate.add(const Duration(days: 30));

    final response = await _authenticatedApiClient.post(
      '/api/v1/surveys/',
      body: {
        'title': question,
        'description': description,
        'address': address,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        if (citizenTarget != null) 'citizen_target': citizenTarget.value,
        'options': options,
      },
    );

    if (response.statusCode != 201) {
      throw Exception('Erreur creation sondage: ${response.statusCode}');
    }
  }

  @override
  Future<void> updateSurvey({
    required int surveyId,
    required String question,
    required String description,
    required String address,
    UserRole? citizenTarget,
  }) async {
    final response = await _authenticatedApiClient.patch(
      '/api/v1/surveys/$surveyId/',
      body: {
        'title': question,
        'description': description,
        'address': address,
        if (citizenTarget != null) 'citizen_target': citizenTarget.value,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur modification sondage: ${response.statusCode}');
    }
  }

  @override
  Future<void> deleteSurvey({required int surveyId}) async {
    final response = await _authenticatedApiClient.delete('/api/v1/surveys/$surveyId/');
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Erreur suppression sondage: ${response.statusCode}');
    }
  }

  @override
  Future<void> vote({required int surveyId, required int optionId}) async {
    final response = await _authenticatedApiClient.post(
      '/api/v1/votes/',
      body: {'survey': surveyId, 'option': optionId},
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Erreur vote: ${response.statusCode}');
    }
  }
}

