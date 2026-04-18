part of 'surveys_bloc.dart';

/// Surveys BLoC status.
enum SurveysStatus {
  /// Initial state.
  initial,

  /// Loading surveys.
  loading,

  /// Surveys loaded.
  loaded,

  /// Generic failure.
  failure,

  /// Creating survey.
  creating,

  /// Survey created.
  created,

  /// Deleting survey.
  deleting,

  /// Survey deleted.
  deleted,

  /// Updating survey.
  updating,

  /// Survey updated.
  updated,

  /// Voting in progress.
  voting,

  /// Vote saved.
  voted,
}

/// State for surveys page.
class SurveysState extends Equatable {
  /// Creates a [SurveysState].
  const SurveysState({
    required this.status,
    this.surveys = const <Survey>[],
    this.error,
    this.count = 0,
    this.page = 1,
    this.next,
    this.previous,
    this.pageSize = 20,
    this.exactAddress = '',
    this.citizenTarget,
    this.ordering = '-created_at',
  });

  /// Initial state.
  const SurveysState.initial()
      : status = SurveysStatus.initial,
        surveys = const <Survey>[],
        error = null,
        count = 0,
        page = 1,
        next = null,
        previous = null,
        pageSize = 20,
        exactAddress = '',
        citizenTarget = null,
        ordering = '-created_at';

  /// Current page status.
  final SurveysStatus status;

  /// Loaded surveys.
  final List<Survey> surveys;

  /// Optional error message.
  final String? error;

  /// Total available surveys count.
  final int count;

  /// Current page number.
  final int page;

  /// Next page URL.
  final String? next;

  /// Previous page URL.
  final String? previous;

  /// Number of items per page.
  final int pageSize;

  /// Current exact address filter.
  final String exactAddress;

  /// Current target filter.
  final UserRole? citizenTarget;

  /// Current ordering.
  final String ordering;

  /// Clones state with modified fields.
  SurveysState copyWith({
    SurveysStatus? status,
    List<Survey>? surveys,
    String? error,
    int? count,
    int? page,
    String? next,
    String? previous,
    int? pageSize,
    String? exactAddress,
    UserRole? citizenTarget,
    String? ordering,
    bool clearCitizenTarget = false,
  }) {
    return SurveysState(
      status: status ?? this.status,
      surveys: surveys ?? this.surveys,
      error: error,
      count: count ?? this.count,
      page: page ?? this.page,
      next: next ?? this.next,
      previous: previous ?? this.previous,
      pageSize: pageSize ?? this.pageSize,
      exactAddress: exactAddress ?? this.exactAddress,
      citizenTarget: clearCitizenTarget ? null : (citizenTarget ?? this.citizenTarget),
      ordering: ordering ?? this.ordering,
    );
  }

  @override
  List<Object?> get props => [
        status,
        surveys,
        error,
        count,
        page,
        next,
        previous,
        pageSize,
        exactAddress,
        citizenTarget,
        ordering,
      ];
}

