// ignore_for_file: public_member_api_docs

import 'dart:convert';

import 'package:frontend/constants/texts/texts_news.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/news/data/models/news_question.dart';
import 'package:frontend/features/news/data/news_repository.dart';

class NewsRepositoryImpl implements NewsRepository {
  NewsRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<NewsQuestion>> listQuestions() async {
    final response = await _apiClient.get('/api/v1/news-questions/');

    if (response.statusCode != 200) {
      throw Exception(
        '${AppTextsNews.loadQuestionsError}: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);
    final List<dynamic> results;
    if (data is Map<String, dynamic> && data['results'] != null) {
      results = data['results'] as List<dynamic>;
    } else if (data is List<dynamic>) {
      results = data;
    } else {
      throw Exception(AppTextsNews.invalidQuestionsResponseFormat);
    }

    return results
        .map((item) => NewsQuestion.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> createQuestion({
    required String subject,
    required String message,
  }) async {
    final response = await _apiClient.post(
      '/api/v1/news-questions/',
      body: {'subject': subject, 'message': message},
    );

    if (response.statusCode != 201) {
      throw Exception(
        '${AppTextsNews.createQuestionError}: ${response.statusCode}',
      );
    }
  }

  @override
  Future<NewsQuestion> replyToQuestion({
    required int questionId,
    required String response,
  }) async {
    final httpResponse = await _apiClient.post(
      '/api/v1/news-questions/$questionId/reply/',
      body: {'response': response},
    );

    if (httpResponse.statusCode != 200) {
      throw Exception(
        '${AppTextsNews.replyQuestionError}: ${httpResponse.statusCode}',
      );
    }

    return NewsQuestion.fromJson(
      jsonDecode(httpResponse.body) as Map<String, dynamic>,
    );
  }
}
