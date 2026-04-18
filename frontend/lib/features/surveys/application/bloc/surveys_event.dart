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
    required this.address,
    required this.options,
    this.citizenTarget,
  });

  /// Survey question.
  final String question;

  /// Survey description.
  final String description;

  /// Exact address.
  final String address;

  /// Survey options.
  final List<String> options;

  /// Target audience.
  final UserRole? citizenTarget;

  @override
  List<Object?> get props => [question, description, address, options, citizenTarget];
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
    required this.address,
    this.citizenTarget,
  });

  /// Survey id.
  final int surveyId;

  /// Survey question.
  final String question;

  /// Survey description.
  final String description;

  /// Exact address.
  final String address;

  /// Target audience.
  final UserRole? citizenTarget;

  @override
  List<Object?> get props => [
        surveyId,
        question,
        description,
        address,
        citizenTarget,
      ];
}

/// Casts or updates vote on one option.
class SurveyVoteRequested extends SurveysEvent {
  /// Creates a [SurveyVoteRequested].
  const SurveyVoteRequested({required this.surveyId, required this.optionId});

  /// Survey id.
  final int surveyId;

  /// Selected option id.
  final int optionId;

  @override
  List<Object?> get props => [surveyId, optionId];
}

