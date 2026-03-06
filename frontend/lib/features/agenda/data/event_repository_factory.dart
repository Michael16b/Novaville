import 'dart:convert';

import 'package:frontend/config/app_config.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/network/authenticated_client_factory.dart';
import 'package:frontend/features/agenda/data/event_repository.dart';
import 'package:frontend/features/agenda/data/event_repository_impl.dart';
import 'package:frontend/features/auth/data/auth_storage_impl.dart';
import 'package:http/http.dart' as http;

/// Factory for creating an [EventRepositoryImpl] configured with
/// authentication.
IEventRepository createEventRepository({http.Client? client}) {
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
          final decoded =
              jsonDecode(response.body) as Map<String, dynamic>;
          return decoded['access'] as String?;
        }
        return null;
      } catch (e) {
        return null;
      }
    },
    inner: httpClient,
  );

  final apiClient = ApiClient(
    baseUrl: baseUrl,
    client: authenticatedClient,
  );

  return EventRepositoryImpl(apiClient: apiClient);
}
