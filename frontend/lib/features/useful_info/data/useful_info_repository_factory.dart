import 'dart:convert';

import 'package:frontend/config/app_config.dart';
import 'package:frontend/core/network/authenticated_client_factory.dart';
import 'package:frontend/features/auth/data/auth_storage_impl.dart';
import 'package:http/http.dart' as http;

import 'useful_info_api.dart';
import 'useful_info_repository.dart';
import 'useful_info_repository_impl.dart';

/// Factory for creating a [UsefulInfoRepositoryImpl] configured with
/// authentication.
UsefulInfoRepository createUsefulInfoRepository({http.Client? client}) {
  final storage = SecureTokenStorage();
  final baseUrl = AppConfig.apiBaseUrl;
  final httpClient = client ?? http.Client();

  final authenticatedClient = AuthenticatedClientFactory.create(
    storage: storage,
    onRefresh: (refreshToken) async {
      try {
        final url = Uri.parse('$baseUrl/api/v1/auth/token/refresh/');
        final response = await httpClient.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh': refreshToken}),
        );

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          return decoded['access'] as String?;
        }
        return null;
      } catch (e) {
        return null;
      }
    },
    inner: httpClient,
  );

  final api = UsefulInfoApi(client: authenticatedClient, baseUrl: baseUrl);
  return UsefulInfoRepositoryImpl(api);
}
