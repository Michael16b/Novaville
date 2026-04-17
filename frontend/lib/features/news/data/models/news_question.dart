// ignore_for_file: public_member_api_docs, sort_constructors_first, always_put_required_named_parameters_first, lines_longer_than_80_chars

import 'package:equatable/equatable.dart';

class NewsQuestionAuthor extends Equatable {
  const NewsQuestionAuthor({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.role,
  });

  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String? role;

  factory NewsQuestionAuthor.fromJson(Map<String, dynamic> json) {
    return NewsQuestionAuthor(
      id: json['id'] as int,
      username: (json['username'] as String?) ?? '',
      firstName: (json['first_name'] as String?) ?? '',
      lastName: (json['last_name'] as String?) ?? '',
      role: json['role'] as String?,
    );
  }

  String get displayName {
    final fullName = '$firstName $lastName'.trim();
    return fullName.isEmpty ? username : fullName;
  }

  @override
  List<Object?> get props => [id, username, firstName, lastName, role];
}

class NewsQuestion extends Equatable {
  const NewsQuestion({
    required this.id,
    required this.subject,
    required this.message,
    required this.response,
    required this.status,
    required this.createdAt,
    this.answeredAt,
    required this.citizen,
    this.answeredBy,
  });

  final int id;
  final String subject;
  final String message;
  final String response;
  final String status;
  final DateTime createdAt;
  final DateTime? answeredAt;
  final NewsQuestionAuthor citizen;
  final NewsQuestionAuthor? answeredBy;

  factory NewsQuestion.fromJson(Map<String, dynamic> json) {
    return NewsQuestion(
      id: json['id'] as int,
      subject: (json['subject'] as String?) ?? '',
      message: (json['message'] as String?) ?? '',
      response: (json['response'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'PENDING',
      createdAt: DateTime.parse(json['created_at'] as String),
      answeredAt: json['answered_at'] != null
          ? DateTime.parse(json['answered_at'] as String)
          : null,
      citizen: NewsQuestionAuthor.fromJson(
        json['citizen'] as Map<String, dynamic>,
      ),
      answeredBy: json['answered_by'] != null
          ? NewsQuestionAuthor.fromJson(
              json['answered_by'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  bool get isAnswered => status == 'ANSWERED';

  @override
  List<Object?> get props => [
    id,
    subject,
    message,
    response,
    status,
    createdAt,
    answeredAt,
    citizen,
    answeredBy,
  ];
}
