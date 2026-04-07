// ignore_for_file: public_member_api_docs

import 'package:frontend/features/news/data/models/news_question.dart';

abstract class NewsRepository {
  Future<List<NewsQuestion>> listQuestions();

  Future<void> createQuestion({
    required String subject,
    required String message,
  });

  Future<NewsQuestion> replyToQuestion({
    required int questionId,
    required String response,
  });
}
