import 'dart:convert';

import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/network/authenticated_client_factory.dart';
import 'package:frontend/features/auth/data/auth_api.dart';
import 'package:frontend/features/auth/data/auth_repository.dart';
import 'package:frontend/features/auth/data/auth_repository_impl.dart';
import 'package:frontend/features/auth/data/auth_storage_impl.dart';
import 'package:frontend/features/users/data/user_repository_impl.dart';
import 'package:http/http.dart' as http;

IAuthRepository createRemoteAuthRepository({required String baseUrl}) {
  final api = AuthApi(baseUrl: baseUrl);
  final storage = SecureTokenStorage();
  final httpClient = http.Client();

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

  final apiClient = ApiClient(baseUrl: baseUrl, client: authenticatedClient);
  final userRepository = UserRepositoryImpl(apiClient: apiClient);

  return AuthRepositoryImpl(
    api: api,
    userRepository: userRepository,
    storage: storage,
  );
}
