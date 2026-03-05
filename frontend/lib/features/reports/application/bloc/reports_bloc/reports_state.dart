part of 'reports_bloc.dart';

/// Status enum for the reports BLoC.
enum ReportsStatus {
  /// Initial state.
  initial,

  /// Loading reports.
  loading,

  /// Reports loaded successfully.
  loaded,

  /// An error occurred.
  failure,

  /// Creating a report.
  creating,

  /// Report created successfully.
  created,

  /// Deleting a report.
  deleting,

  /// Report deleted successfully.
  deleted,

  /// Updating a report.
  updating,

  /// Report updated successfully.
  updated,
}

/// State for the reports BLoC.
class ReportsState extends Equatable {
  /// Creates a [ReportsState].
  const ReportsState({
    required this.status,
    this.reports = const <Report>[],
    this.error,
    this.page = 1,
    this.count = 0,
    this.next,
    this.previous,
    this.pageSize = 20,
    this.search = '',
    this.neighborhoods = const <Neighborhood>[],
    this.neighborhoodsLoaded = false,
  });

  /// Initial state.
  const ReportsState.initial()
      : status = ReportsStatus.initial,
        reports = const <Report>[],
        error = null,
        page = 1,
        count = 0,
        next = null,
        previous = null,
        pageSize = 20,
        search = '',
        neighborhoods = const <Neighborhood>[],
        neighborhoodsLoaded = false;

  /// Loading state.
  const ReportsState.loading()
      : status = ReportsStatus.loading,
        reports = const <Report>[],
        error = null,
        page = 1,
        count = 0,
        next = null,
        previous = null,
        pageSize = 20,
        search = '',
        neighborhoods = const <Neighborhood>[],
        neighborhoodsLoaded = false;

  /// Loaded state.
  const ReportsState.loaded(
    this.reports, {
    required this.page,
    required this.count,
    this.next,
    this.previous,
    this.pageSize = 20,
    this.search = '',
    this.neighborhoods = const <Neighborhood>[],
    this.neighborhoodsLoaded = false,
  })  : status = ReportsStatus.loaded,
        error = null;

  /// Failure state.
  const ReportsState.failure(String message)
      : status = ReportsStatus.failure,
        reports = const <Report>[],
        error = message,
        page = 1,
        count = 0,
        next = null,
        previous = null,
        pageSize = 20,
        search = '',
        neighborhoods = const <Neighborhood>[],
        neighborhoodsLoaded = false;

  /// Current status.
  final ReportsStatus status;

  /// List of reports.
  final List<Report> reports;

  /// Error message.
  final String? error;

  /// Current page number.
  final int page;

  /// Total count of reports.
  final int count;

  /// Next page URL.
  final String? next;

  /// Previous page URL.
  final String? previous;

  /// Number of items per page.
  final int pageSize;

  /// Current search query.
  final String search;

  /// Available neighborhoods for form dropdowns.
  final List<Neighborhood> neighborhoods;

  /// Whether neighborhoods have been loaded (even if the list is empty).
  final bool neighborhoodsLoaded;

  /// Returns a copy of this state with the given fields replaced.
  ReportsState copyWith({
    ReportsStatus? status,
    List<Report>? reports,
    String? error,
    int? page,
    int? count,
    String? next,
    String? previous,
    int? pageSize,
    String? search,
    List<Neighborhood>? neighborhoods,
    bool? neighborhoodsLoaded,
  }) {
    return ReportsState(
      status: status ?? this.status,
      reports: reports ?? this.reports,
      error: error ?? this.error,
      page: page ?? this.page,
      count: count ?? this.count,
      next: next ?? this.next,
      previous: previous ?? this.previous,
      pageSize: pageSize ?? this.pageSize,
      search: search ?? this.search,
      neighborhoods: neighborhoods ?? this.neighborhoods,
      neighborhoodsLoaded: neighborhoodsLoaded ?? this.neighborhoodsLoaded,
    );
  }

  @override
  List<Object?> get props => [
        status,
        reports,
        error,
        page,
        count,
        next,
        previous,
        pageSize,
        search,
        neighborhoods,
        neighborhoodsLoaded,
      ];
}

