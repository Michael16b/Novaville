import 'dart:convert';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/account/data/models/user.dart';
import 'package:frontend/features/account/data/user_repository.dart';

/// Implémentation du repository utilisateur utilisant l'API HTTP
class UserRepositoryImpl implements IUserRepository {
  UserRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<User> getCurrentUser() async {
    final response = await _apiClient.get('/api/v1/users/me/');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return User.fromJson(json);
    } else {
      throw Exception(
        'Erreur lors de la récupération du profil: ${response.statusCode}',
      );
    }
  }

  @override
  Future<User> updateUser({
    required int userId,
    String? firstName,
    String? lastName,
    String? username,
    String? email,
  }) async {
    final body = <String, dynamic>{};
    if (firstName != null) body['first_name'] = firstName;
    if (lastName != null) body['last_name'] = lastName;
    if (username != null) body['username'] = username;
    if (email != null) body['email'] = email;

    final response = await _apiClient.client.patch(
      _apiClient.buildUri('/api/v1/users/$userId/'),
      headers: _apiClient.defaultHeaders,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return User.fromJson(json);
    } else {
      throw Exception(
        'Erreur lors de la mise à jour du profil: ${response.statusCode}',
      );
    }
  }
}

