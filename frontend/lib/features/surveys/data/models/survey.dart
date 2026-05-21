import 'package:equatable/equatable.dart';
import 'package:frontend/features/reports/data/models/neighborhood.dart';
import 'package:frontend/features/users/data/models/user.dart';
import 'package:frontend/features/users/data/models/user_role.dart';

/// Survey option with vote count.
class SurveyOption extends Equatable {
  /// Creates a [SurveyOption].
  const SurveyOption({
    required this.id,
    required this.text,
    required this.voteCount,
  });

  /// Creates a [SurveyOption] from JSON.
  factory SurveyOption.fromJson(Map<String, dynamic> json) {
    return SurveyOption(
      id: json['id'] as int,
      text: json['text'] as String,
      voteCount: (json['vote_count'] as int?) ?? 0,
    );
  }

  /// Option identifier.
  final int id;

  /// Option label.
  final String text;

  /// Number of votes for this option.
  final int voteCount;

  @override
  List<Object?> get props => [id, text, voteCount];
}

/// Survey domain model.
class Survey extends Equatable {
  /// Creates a [Survey].
  const Survey({
    required this.id,
    required this.title,
    required this.description,
    required this.address,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    required this.totalVotes,
    required this.options,
    required this.multipleAnswers,
    this.neighborhoodId,
    this.neighborhood,
    this.citizenTarget,
    this.createdBy,
    this.currentUserVoteId,
    this.currentUserVoteOptionId,
    this.currentUserVoteIds = const <int>[],
    this.currentUserVoteOptionIds = const <int>[],
  });

  /// Creates a [Survey] from JSON.
  factory Survey.fromJson(Map<String, dynamic> json) {
    return Survey(
      id: json['id'] as int,
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      address: (json['address'] as String?) ?? '',
      neighborhoodId: json['neighborhood'] as int?,
      neighborhood: json['neighborhood_detail'] is Map<String, dynamic>
          ? Neighborhood.fromJson(
              json['neighborhood_detail'] as Map<String, dynamic>,
            )
          : null,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      citizenTarget: _roleFromJson(json['citizen_target'] as String?),
      multipleAnswers: (json['multiple_answers'] as bool?) ?? false,
      createdBy: json['created_by'] is Map<String, dynamic>
          ? User.fromJson(json['created_by'] as Map<String, dynamic>)
          : null,
      totalVotes: (json['total_votes'] as int?) ?? 0,
      options: (json['options'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => SurveyOption.fromJson(item as Map<String, dynamic>))
          .toList(),
      currentUserVoteId: json['current_user_vote_id'] as int?,
      currentUserVoteOptionId: json['current_user_vote_option_id'] as int?,
      currentUserVoteIds:
          (json['current_user_vote_ids'] as List<dynamic>? ?? const <dynamic>[])
              .whereType<int>()
              .toList(),
      currentUserVoteOptionIds:
          (json['current_user_vote_option_ids'] as List<dynamic>? ??
                  const <dynamic>[])
              .whereType<int>()
              .toList(),
    );
  }

  /// Survey identifier.
  final int id;

  /// Survey question.
  final String title;

  /// Survey description.
  final String description;

  /// Exact target address.
  final String address;

  /// Target neighborhood id. Null means all neighborhoods.
  final int? neighborhoodId;

  /// Target neighborhood detail when provided by the API.
  final Neighborhood? neighborhood;

  /// Start date.
  final DateTime startDate;

  /// End date.
  final DateTime endDate;

  /// Creation date.
  final DateTime createdAt;

  /// Optional target audience role.
  final UserRole? citizenTarget;

  /// Whether users can select several options.
  final bool multipleAnswers;

  /// Survey author.
  final User? createdBy;

  /// Total votes for this survey.
  final int totalVotes;

  /// Available options.
  final List<SurveyOption> options;

  /// Current user vote identifier.
  final int? currentUserVoteId;

  /// Current user selected option id.
  final int? currentUserVoteOptionId;

  /// Current user vote identifiers.
  final List<int> currentUserVoteIds;

  /// Current user selected option ids.
  final List<int> currentUserVoteOptionIds;

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    address,
    neighborhoodId,
    neighborhood,
    startDate,
    endDate,
    createdAt,
    citizenTarget,
    multipleAnswers,
    createdBy,
    totalVotes,
    options,
    currentUserVoteId,
    currentUserVoteOptionId,
    currentUserVoteIds,
    currentUserVoteOptionIds,
  ];

  static UserRole? _roleFromJson(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return UserRole.fromString(value);
    } catch (_) {
      return null;
    }
  }
}
