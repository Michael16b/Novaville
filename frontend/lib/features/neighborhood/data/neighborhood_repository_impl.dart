import 'dart:convert';

import 'package:frontend/constants/texts/texts_neighborhood_repository_errors.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/neighborhood/data/neighborhood_repository.dart';
import 'package:frontend/features/reports/data/models/neighborhood.dart';

class NeighborhoodRepositoryImpl implements INeighborhoodRepository {
  NeighborhoodRepositoryImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<void> createNeighborhood(String name, String postalCode) async {
    final response = await _apiClient.post(
      '/api/v1/neighborhoods/',
      body: {'name': name, 'postal_code': postalCode},
    );
    if (response.statusCode != 201) {
      throw Exception(
        '${NeighborhoodTextsErrors.createError}: ${response.statusCode}',
      );
    }
  }

  @override
  Future<void> deleteNeighborhood(int id) async {
    final response = await _apiClient.delete('/api/v1/neighborhoods/$id/');
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(
        '${NeighborhoodTextsErrors.deleteError}: ${response.statusCode}',
      );
    }
  }

  @override
  Future<List<Neighborhood>> listNeighborhoods() async {
    final response = await _apiClient.get('/api/v1/neighborhoods/');
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List<dynamic> results;
      if (json is Map<String, dynamic> && json['results'] != null) {
        results = json['results'] as List<dynamic>;
      } else if (json is List) {
        results = json;
      } else {
        throw Exception(NeighborhoodTextsErrors.invalidResponseFormat);
      }
      return results
          .map((n) => Neighborhood.fromJson(n as Map<String, dynamic>))
          .toList();
    }
    throw Exception(
      '${NeighborhoodTextsErrors.fetchError}: ${response.statusCode}',
    );
  }

  @override
  Future<Neighborhood> updateNeighborhood(
    int id,
    String name,
    String postalCode,
  ) async {
    final response = await _apiClient.patch(
      '/api/v1/neighborhoods/$id/',
      body: {'name': name, 'postal_code': postalCode},
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Neighborhood.fromJson(json);
    }
    throw Exception(
      '${NeighborhoodTextsErrors.updateError}: ${response.statusCode}',
    );
  }
}
