import 'dart:convert';

import 'package:frontend/constants/texts/texts_report_repository_errors.dart';
import 'package:frontend/constants/texts/texts_reports.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/reports/data/models/neighborhood.dart';
import 'package:frontend/features/reports/data/models/report.dart';
import 'package:frontend/features/reports/data/report_repository.dart';
import 'package:http/http.dart' as http;

/// HTTP-based implementation of [IReportRepository].
class ReportRepositoryImpl implements IReportRepository {
  /// Creates a [ReportRepositoryImpl].
  ReportRepositoryImpl({
    required ApiClient publicApiClient,
    required ApiClient authenticatedApiClient,
  }) : _publicApiClient = publicApiClient,
       _authenticatedApiClient = authenticatedApiClient;

  final ApiClient _publicApiClient;
  final ApiClient _authenticatedApiClient;

  @override
  Future<ReportPage> listReports({
    String? ordering,
    String? search,
    int page = 1,
    String? status,
    String? problemType,
    String? address,
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
    if (address != null && address.trim().isNotEmpty) {
      url += '&address=${Uri.encodeQueryComponent(address.trim())}';
    }
    if (neighborhood != null) {
      url += '&neighborhood=$neighborhood';
    }
    if (createdAfter != null) {
      url += '&created_after=${createdAfter.toUtc().toIso8601String()}';
    }

    final response = await _publicApiClient.get(url);

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
    final response = await _publicApiClient.get('/api/v1/reports/$reportId/');

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
    required String address,
    int? neighborhood,
    List<ReportPhotoAttachment> photos = const [],
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'problem_type': problemType,
      'description': description,
      'address': address,
    };
    if (neighborhood != null) body['neighborhood'] = neighborhood;

    final response = photos.isEmpty
        ? await _authenticatedApiClient.post('/api/v1/reports/', body: body)
        : await http.Response.fromStream(
            await _authenticatedApiClient.postMultipart(
              '/api/v1/reports/',
              fields: body.map((key, value) => MapEntry(key, value.toString())),
              files: photos,
            ),
          );

    if (response.statusCode != 201) {
      final responseMessage = _extractErrorMessage(response.body);
      throw Exception(
        '${ReportTextsErrors.createError}: ${response.statusCode}'
        '${responseMessage.isEmpty ? '' : ' - $responseMessage'}',
      );
    }
  }

  @override
  Future<Report> updateReport({
    required int reportId,
    String? title,
    String? description,
    String? address,
    int? neighborhood,
    String? problemType,
    List<ReportPhotoAttachment> photos = const [],
    List<int> deletedPhotoIds = const [],
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (address != null) body['address'] = address;
    if (neighborhood != null) body['neighborhood'] = neighborhood;
    if (problemType != null) body['problem_type'] = problemType;
    if (deletedPhotoIds.isNotEmpty) {
      body['deleted_photo_ids'] = deletedPhotoIds;
    }

    final response = photos.isEmpty
        ? await _authenticatedApiClient.patch(
            '/api/v1/reports/$reportId/',
            body: body,
          )
        : await http.Response.fromStream(
            await _authenticatedApiClient.patchMultipart(
              '/api/v1/reports/$reportId/',
              fields: body.map(
                (key, value) => MapEntry(
                  key,
                  value is List ? value.join(',') : value.toString(),
                ),
              ),
              files: photos,
            ),
          );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Report.fromJson(json);
    } else {
      final responseMessage = _extractErrorMessage(response.body);
      throw Exception(
        '${ReportTextsErrors.updateError}: ${response.statusCode}'
        '${responseMessage.isEmpty ? '' : ' - $responseMessage'}',
      );
    }
  }

  @override
  Future<void> deleteReport({required int reportId}) async {
    final response = await _authenticatedApiClient.delete(
      '/api/v1/reports/$reportId/',
    );

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
    final response = await _authenticatedApiClient.post(
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
    final response = await _publicApiClient.get('/api/v1/neighborhoods/');

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

  String _extractErrorMessage(String responseBody) {
    if (responseBody.trim().isEmpty) return '';
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        return decoded.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join(', ');
      }
      return decoded.toString();
    } catch (_) {
      return responseBody;
    }
  }
}
