import 'dart:convert';

import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/home/data/dashboard_repository.dart';
import 'package:frontend/features/home/domain/dashboard_stats.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({required ApiClient apiClient})
    : _apiClient = apiClient;
  final ApiClient _apiClient;

  @override
  Future<DashboardStats> getDashboardStats() async {
    final response = await _apiClient.get('/api/v1/dashboard/stats/');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return DashboardStats.fromJson(data);
    } else {
      throw Exception('Failed to load dashboard stats');
    }
  }
}
