import 'dart:convert';
import 'package:frontend/constants/texts/texts_profile.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/users/data/models/user.dart';
import 'package:frontend/features/users/data/user_repository.dart';

/// HTTP-based implementation of [IUserRepository].
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
        '${AppTextsProfile.fetchProfileError}: ${response.statusCode}',
      );
    }
  }

  @override
  Future<List<User>> listUsers() async {
    final response = await _apiClient.get('/api/v1/users/');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      // Handle both list and paginated response
      List<dynamic> usersList;
      if (json is List) {
        usersList = json;
      } else if (json is Map && json['results'] != null) {
        usersList = json['results'] as List<dynamic>;
      } else {
        throw Exception('Invalid response format');
      }

      return usersList
          .map((user) => User.fromJson(user as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
        '${AppTextsProfile.fetchProfileError}: ${response.statusCode}',
      );
    }
  }

  @override
  Future<void> deleteUser({required int userId}) async {
    final response = await _apiClient.delete('/api/v1/users/$userId/');

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(
        'Erreur lors de la suppression: ${response.statusCode}',
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

    final response = await _apiClient.patch(
      '/api/v1/users/$userId/',
      body: body,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return User.fromJson(json);
    } else {
      throw Exception(
        '${AppTextsProfile.updateProfileError}: ${response.statusCode}',
      );
    }
  }
}
