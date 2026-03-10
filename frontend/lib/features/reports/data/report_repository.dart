import 'package:cross_file/cross_file.dart';
import 'package:frontend/features/reports/data/models/neighborhood.dart';
import 'package:frontend/features/reports/data/models/report.dart';

/// Paginated response for reports.
class ReportPage {
  /// Creates a [ReportPage].
  ReportPage({
    required this.count,
    required this.results,
    this.next,
    this.previous,
  });

  /// Creates a [ReportPage] from a JSON map.
  factory ReportPage.fromJson(Map<String, dynamic> json) {
    return ReportPage(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>)
          .map((r) => Report.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Total count of reports.
  final int count;

  /// URL for the next page.
  final String? next;

  /// URL for the previous page.
  final String? previous;

  /// List of reports for the current page.
  final List<Report> results;
}

/// Repository interface for report operations.
abstract class IReportRepository {
  /// Retrieves a paginated list of reports.
  Future<ReportPage> listReports({
    String? ordering,
    String? search,
    int page = 1,
    String? status,
    String? problemType,
    int? neighborhood,
    DateTime? createdAfter,
  });

  /// Retrieves a single report by ID.
  Future<Report> getReport({required int reportId});

  /// Creates a new report.
  Future<Report> createReport({
    required String title,
    required String problemType,
    required String description,
    int? neighborhood,
    double? latitude,
    double? longitude,
    String? address,
  });

  /// Updates an existing report.
  Future<Report> updateReport({
    required int reportId,
    String? title,
    String? description,
    int? neighborhood,
    String? problemType,
    double? latitude,
    double? longitude,
    String? address,
  });

  /// Deletes a report.
  Future<void> deleteReport({required int reportId});

  /// Updates the status of a report (staff only).
  Future<Report> updateReportStatus({
    required int reportId,
    required String status,
  });

  /// Lists all available neighborhoods.
  Future<List<Neighborhood>> listNeighborhoods();

  /// Uploads media to a report.
  Future<void> uploadMedia({
    required int reportId,
    required List<XFile> media,
  });
}
