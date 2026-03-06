part of 'reports_bloc.dart';

/// Base class for all reports events.
abstract class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load reports.
class ReportsLoadRequested extends ReportsEvent {
  /// Creates a [ReportsLoadRequested].
  const ReportsLoadRequested({this.ordering, this.search});

  /// Ordering field.
  final String? ordering;

  /// Search query.
  final String? search;

  @override
  List<Object?> get props => [ordering, search];
}

/// Event to search reports.
class ReportsSearchRequested extends ReportsEvent {
  /// Creates a [ReportsSearchRequested].
  const ReportsSearchRequested({required this.query, this.ordering});

  /// Search query.
  final String query;

  /// Ordering field.
  final String? ordering;

  @override
  List<Object?> get props => [query, ordering];
}

/// Event to sort reports.
class ReportsSortRequested extends ReportsEvent {
  /// Creates a [ReportsSortRequested].
  const ReportsSortRequested({
    required this.column,
    required this.ascending,
    this.search,
  });

  /// Column key to sort by.
  final String column;

  /// Whether to sort ascending.
  final bool ascending;

  /// Current search query.
  final String? search;

  @override
  List<Object?> get props => [column, ascending, search];
}

/// Event to request a specific page.
class ReportsPageRequested extends ReportsEvent {
  /// Creates a [ReportsPageRequested].
  const ReportsPageRequested({
    required this.page,
    this.ordering,
    this.search,
  });

  /// Page number.
  final int page;

  /// Ordering field.
  final String? ordering;

  /// Current search query.
  final String? search;

  @override
  List<Object?> get props => [page, ordering, search];
}

/// Event to refresh the reports list.
class ReportsRefreshRequested extends ReportsEvent {
  /// Creates a [ReportsRefreshRequested].
  const ReportsRefreshRequested();
}

/// Event to create a new report.
class ReportCreateRequested extends ReportsEvent {
  /// Creates a [ReportCreateRequested].
  const ReportCreateRequested({
    required this.problemType,
    required this.description,
    this.neighborhood,
    this.citizenTarget,
  });

  /// Problem type value.
  final String problemType;

  /// Description of the issue.
  final String description;

  /// Neighborhood ID.
  final int? neighborhood;

  /// Citizen target role.
  final String? citizenTarget;

  @override
  List<Object?> get props => [
        problemType,
        description,
        neighborhood,
        citizenTarget,
      ];
}

/// Event to delete a report.
class ReportDeleteRequested extends ReportsEvent {
  /// Creates a [ReportDeleteRequested].
  const ReportDeleteRequested({required this.reportId});

  /// ID of the report to delete.
  final int reportId;

  @override
  List<Object?> get props => [reportId];
}

/// Event to update the status of a report (staff only).
class ReportStatusUpdateRequested extends ReportsEvent {
  /// Creates a [ReportStatusUpdateRequested].
  const ReportStatusUpdateRequested({
    required this.reportId,
    required this.status,
  });

  /// ID of the report.
  final int reportId;

  /// New status value.
  final String status;

  @override
  List<Object?> get props => [reportId, status];
}

/// Event to update a report.
class ReportUpdateRequested extends ReportsEvent {
  /// Creates a [ReportUpdateRequested].
  const ReportUpdateRequested({
    required this.reportId,
    this.description,
    this.neighborhood,
    this.problemType,
    this.citizenTarget,
  });

  /// ID of the report to update.
  final int reportId;

  /// Updated description.
  final String? description;

  /// Updated neighborhood ID.
  final int? neighborhood;

  /// Updated problem type.
  final String? problemType;

  /// Updated citizen target.
  final String? citizenTarget;

  @override
  List<Object?> get props => [
        reportId,
        description,
        neighborhood,
        problemType,
        citizenTarget,
      ];
}

/// Event to load neighborhoods for the form dropdowns.
class ReportsNeighborhoodsLoadRequested extends ReportsEvent {
  /// Creates a [ReportsNeighborhoodsLoadRequested].
  const ReportsNeighborhoodsLoadRequested();
}

/// Event to apply advanced filters.
class ReportsFilterRequested extends ReportsEvent {
  /// Creates a [ReportsFilterRequested].
  const ReportsFilterRequested({
    this.status,
    this.problemType,
    this.neighborhood,
    this.createdAfter,
    this.ordering,
    this.search,
  });

  /// Filter by status.
  final String? status;

  /// Filter by problem type.
  final String? problemType;

  /// Filter by neighborhood ID.
  final int? neighborhood;

  /// Filter by creation date.
  final DateTime? createdAfter;

  /// Current ordering.
  final String? ordering;

  /// Current search query.
  final String? search;

  @override
  List<Object?> get props => [
        status,
        problemType,
        neighborhood,
        createdAfter,
        ordering,
        search,
      ];
}
