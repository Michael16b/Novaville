import 'dart:convert';
import 'package:frontend/constants/texts/texts_my_account.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/users/data/models/user.dart';
import 'package:frontend/features/users/data/models/user_role.dart';
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
  Future<UserPage> listUsers({
    String? ordering,
    String? search,
    int page = 1,
  }) async {
    String url = '/api/v1/users/?page=$page';
    if (ordering != null && ordering.isNotEmpty) {
      url += '&ordering=$ordering';
    }
    if (search != null && search.trim().isNotEmpty) {
      url += '&search=${Uri.encodeQueryComponent(search.trim())}';
    }
    final response = await _apiClient.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['results'] != null) {
        return UserPage.fromJson(json);
      } else {
        throw Exception('Invalid response format');
      }
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
      throw Exception('Erreur lors de la suppression: ${response.statusCode}');
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

  @override
  Future<User> createUser({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String password,
    UserRole role = UserRole.citizen,
    int? neighborhoodId,
  }) async {
    final response = await _apiClient.post(
      '/api/v1/users/',
      body: {
        'username': username,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'password': password,
        'role': role.toJson(),
        if (neighborhoodId != null) 'neighborhood': neighborhoodId,
      },
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return User.fromJson(json);
    }

    throw Exception('Erreur lors de la création: ${response.body}');
  }
}
