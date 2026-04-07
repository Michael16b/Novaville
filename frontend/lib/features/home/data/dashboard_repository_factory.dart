import 'package:frontend/config/app_config.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/home/data/dashboard_repository.dart';
import 'package:frontend/features/home/data/dashboard_repository_impl.dart';
import 'package:http/http.dart' as http;

/// Factory for creating a [DashboardRepositoryImpl] configured with
/// the public dashboard endpoint.
DashboardRepository createDashboardRepository({http.Client? client}) {
  final baseUrl = AppConfig.apiBaseUrl;
  final httpClient = client ?? http.Client();
  final apiClient = ApiClient(baseUrl: baseUrl, client: httpClient);

  return DashboardRepositoryImpl(apiClient: apiClient);
}
