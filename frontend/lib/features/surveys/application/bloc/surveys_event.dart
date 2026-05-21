part of 'surveys_bloc.dart';

/// Base class for surveys events.
abstract class SurveysEvent extends Equatable {
  /// Creates a [SurveysEvent].
  const SurveysEvent();

  @override
  List<Object?> get props => [];
}

/// Loads surveys with optional filters.
class SurveysLoadRequested extends SurveysEvent {
  /// Creates a [SurveysLoadRequested].
  const SurveysLoadRequested({
    this.exactAddress,
    this.citizenTarget,
    this.ordering,
    this.page = 1,
    this.citizenTargetSet = false,
  });

  /// Exact address filter.
  final String? exactAddress;

  /// Citizen target filter.
  final UserRole? citizenTarget;

  /// Ordering field, e.g. -created_at.
  final String? ordering;

  /// Page number.
  final int page;

  /// Whether [citizenTarget] should override current filter.
  final bool citizenTargetSet;

  @override
  List<Object?> get props => [
    exactAddress,
    citizenTarget,
    ordering,
    page,
    citizenTargetSet,
  ];
}

/// Updates filters then reloads surveys.
class SurveysFilterChanged extends SurveysEvent {
  /// Creates a [SurveysFilterChanged].
  const SurveysFilterChanged({
    this.exactAddress,
    this.citizenTarget,
    this.ordering,
    this.page = 1,
    this.citizenTargetSet = false,
  });

  /// Exact address filter.
  final String? exactAddress;

  /// Citizen target filter.
  final UserRole? citizenTarget;

  /// Ordering field, e.g. -created_at.
  final String? ordering;

  /// Page number.
  final int page;

  /// Whether [citizenTarget] should override current filter.
  final bool citizenTargetSet;

  @override
  List<Object?> get props => [
    exactAddress,
    citizenTarget,
    ordering,
    page,
    citizenTargetSet,
  ];
}

/// Requests a specific surveys page.
class SurveysPageRequested extends SurveysEvent {
  /// Creates a [SurveysPageRequested].
  const SurveysPageRequested({required this.page});

  /// Page number.
  final int page;

  @override
  List<Object?> get props => [page];
}

/// Creates a survey.
class SurveyCreateRequested extends SurveysEvent {
  /// Creates a [SurveyCreateRequested].
  const SurveyCreateRequested({
    required this.question,
    required this.description,
    required this.neighborhoodId,
    required this.options,
    required this.multipleAnswers,
    this.citizenTarget,
  });

  /// Survey question.
  final String question;

  /// Survey description.
  final String description;

  /// Target neighborhood id. Null means all neighborhoods.
  final int? neighborhoodId;

  /// Survey options.
  final List<String> options;

  /// Whether several answers are allowed.
  final bool multipleAnswers;

  /// Target audience.
  final UserRole? citizenTarget;

  @override
  List<Object?> get props => [
    question,
    description,
    neighborhoodId,
    options,
    multipleAnswers,
    citizenTarget,
  ];
}

/// Deletes a survey.
class SurveyDeleteRequested extends SurveysEvent {
  /// Creates a [SurveyDeleteRequested].
  const SurveyDeleteRequested({required this.surveyId});

  /// Survey id.
  final int surveyId;

  @override
  List<Object?> get props => [surveyId];
}

/// Updates an existing survey (staff only).
class SurveyUpdateRequested extends SurveysEvent {
  /// Creates a [SurveyUpdateRequested].
  const SurveyUpdateRequested({
    required this.surveyId,
    required this.question,
    required this.description,
    required this.neighborhoodId,
    required this.multipleAnswers,
    this.citizenTarget,
  });

  /// Survey id.
  final int surveyId;

  /// Survey question.
  final String question;

  /// Survey description.
  final String description;

  /// Target neighborhood id. Null means all neighborhoods.
  final int? neighborhoodId;

  /// Whether several answers are allowed.
  final bool multipleAnswers;

  /// Target audience.
  final UserRole? citizenTarget;

  @override
  List<Object?> get props => [
    surveyId,
    question,
    description,
    neighborhoodId,
    multipleAnswers,
    citizenTarget,
  ];
}

/// Casts or updates votes.
class SurveyVoteRequested extends SurveysEvent {
  /// Creates a [SurveyVoteRequested].
  const SurveyVoteRequested({required this.surveyId, required this.optionIds});

  /// Survey id.
  final int surveyId;

  /// Selected option ids.
  final List<int> optionIds;

  @override
  List<Object?> get props => [surveyId, optionIds];
}
