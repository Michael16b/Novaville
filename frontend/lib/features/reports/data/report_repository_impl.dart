import 'dart:convert';

import 'package:frontend/constants/texts/texts_reports.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/reports/data/models/neighborhood.dart';
import 'package:frontend/features/reports/data/models/report.dart';
import 'package:frontend/constants/texts/texts_report_repository_errors.dart';
import 'package:frontend/features/reports/data/report_repository.dart';

/// HTTP-based implementation of [IReportRepository].
class ReportRepositoryImpl implements IReportRepository {
  /// Creates a [ReportRepositoryImpl].
  ReportRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<ReportPage> listReports({
    String? ordering,
    String? search,
    int page = 1,
    String? status,
    String? problemType,
    int? neighborhood,
    DateTime? createdAfter,
  }) async {
    var url = '/api/v1/reports/?page=$page';
    if (ordering != null && ordering.isNotEmpty) {
      url += '&ordering=$ordering';
    }
    if (search != null && search.trim().isNotEmpty) {
      url += '&search=${Uri.encodeQueryComponent(search.trim())}';
    }
    if (status != null && status.isNotEmpty) {
      url += '&status=$status';
    }
    if (problemType != null && problemType.isNotEmpty) {
      url += '&problem_type=$problemType';
    }
    if (neighborhood != null) {
      url += '&neighborhood=$neighborhood';
    }
    if (createdAfter != null) {
      url += '&created_after=${createdAfter.toUtc().toIso8601String()}';
    }

    final response = await _apiClient.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['results'] != null) {
        return ReportPage.fromJson(json);
      } else {
        throw Exception(ReportTextsErrors.invalidResponseFormat);
      }
    } else {
      throw Exception(
        '${ReportTextsErrors.fetchError}: ${response.statusCode}',
      );
    }
  }

  @override
  Future<Report> getReport({required int reportId}) async {
    final response = await _apiClient.get('/api/v1/reports/$reportId/');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Report.fromJson(json);
    } else {
      throw Exception(
        '${ReportTextsErrors.fetchError}: ${response.statusCode}',
      );
    }
  }

  @override
  Future<void> createReport({
    required String title,
    required String problemType,
    required String description,
    int? neighborhood,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'problem_type': problemType,
      'description': description,
    };
    if (neighborhood != null) body['neighborhood'] = neighborhood;

    final response = await _apiClient.post(
      '/api/v1/reports/',
      body: body,
    );

    if (response.statusCode != 201) {
      throw Exception(
        '${ReportTextsErrors.createError}: ${response.statusCode}',
      );
    }
  }

  @override
  Future<Report> updateReport({
    required int reportId,
    String? title,
    String? description,
    int? neighborhood,
    String? problemType,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (neighborhood != null) body['neighborhood'] = neighborhood;
    if (problemType != null) body['problem_type'] = problemType;

    final response = await _apiClient.patch(
      '/api/v1/reports/$reportId/',
      body: body,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Report.fromJson(json);
    } else {
      throw Exception(
        '${ReportTextsErrors.updateError}: ${response.statusCode}',
      );
    }
  }

  @override
  Future<void> deleteReport({required int reportId}) async {
    final response = await _apiClient.delete('/api/v1/reports/$reportId/');

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(
        '${ReportTextsErrors.deleteError}: ${response.statusCode}',
      );
    }
  }

  @override
  Future<Report> updateReportStatus({
    required int reportId,
    required String status,
  }) async {
    final response = await _apiClient.post(
      '/api/v1/reports/$reportId/update_status/',
      body: {'status': status},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Report.fromJson(json);
    } else {
      throw Exception(
        '${ReportTexts.statusUpdateError}: ${response.statusCode}',
      );
    }
  }

  @override
  Future<List<Neighborhood>> listNeighborhoods() async {
    final response = await _apiClient.get('/api/v1/neighborhoods/');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      // Handle paginated or direct list response
      final List<dynamic> results;
      if (json is Map<String, dynamic> && json['results'] != null) {
        results = json['results'] as List<dynamic>;
      } else if (json is List) {
        results = json;
      } else {
        throw Exception(ReportTexts.invalidResponseFormat);
      }
      return results
          .map((n) => Neighborhood.fromJson(n as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
        '${ReportTexts.fetchNeighborhoodsError}: ${response.statusCode}',
      );
    }
  }
}
