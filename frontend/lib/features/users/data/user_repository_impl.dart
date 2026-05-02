import 'dart:convert';

import 'package:frontend/constants/texts/texts_auth.dart';
import 'package:frontend/constants/texts/texts_my_account.dart';
import 'package:frontend/constants/texts/texts_user_repository_errors.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/reports/data/models/neighborhood.dart';
import 'package:frontend/features/users/data/models/user.dart';
import 'package:frontend/features/users/data/models/user_role.dart';
import 'package:frontend/features/users/data/user_repository.dart';

/// HTTP-based implementation of [IUserRepository].
class UserRepositoryImpl implements IUserRepository {
  UserRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  String _extractErrorMessage(String responseBody, String fallbackMessage) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final usernameError = decoded['username'];
        if (usernameError is List && usernameError.isNotEmpty) {
          return _localizeErrorMessage(usernameError.first.toString());
        }
        if (usernameError is String && usernameError.isNotEmpty) {
          return _localizeErrorMessage(usernameError);
        }

        final detail = decoded['detail'];
        if (detail is String && detail.isNotEmpty) {
          return _localizeErrorMessage(detail);
        }

        for (final value in decoded.values) {
          if (value is List && value.isNotEmpty) {
            return _localizeErrorMessage(value.first.toString());
          }
          if (value is String && value.isNotEmpty) {
            return _localizeErrorMessage(value);
          }
        }
      }
    } catch (_) {}

    return fallbackMessage;
  }

  String _localizeErrorMessage(String message) {
    final normalized = message.trim().toLowerCase();

    if (normalized.contains('username_already_exists')) {
      return AppTextsUserRepositoryErrors.usernameAlreadyExists;
    }
    if (normalized.contains('a user with that username already exists')) {
      return AppTextsUserRepositoryErrors.usernameAlreadyExists;
    }
    if (normalized.contains('pending_approval')) {
      return AppTextsAuth.pendingApproval;
    }
    if (normalized.contains('account_disabled')) {
      return AppTextsAuth.accountDisabled;
    }

    return message;
  }

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
    String? role,
    String? address,
    int? neighborhood,
  }) async {
    String url = '/api/v1/users/?page=$page';
    if (ordering != null && ordering.isNotEmpty) {
      url += '&ordering=$ordering';
    }
    if (search != null && search.trim().isNotEmpty) {
      url += '&search=${Uri.encodeQueryComponent(search.trim())}';
    }
    if (role != null && role.isNotEmpty) {
      url += '&role=$role';
    }
    if (address != null && address.trim().isNotEmpty) {
      url += '&address=${Uri.encodeQueryComponent(address.trim())}';
    }
    if (neighborhood != null) {
      url += '&neighborhood=$neighborhood';
    }
    final response = await _apiClient.get(url);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['results'] != null) {
        return UserPage.fromJson(json);
      } else {
        throw Exception(AppTextsUserRepositoryErrors.invalidResponseFormat);
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
      throw Exception(
        '${AppTextsUserRepositoryErrors.deleteUserError}: ${response.statusCode}',
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
    String? address,
    UserRole? role,
    int? neighborhoodId,
  }) async {
    final body = <String, dynamic>{};
    if (firstName != null) body['first_name'] = firstName;
    if (lastName != null) body['last_name'] = lastName;
    if (username != null) body['username'] = username;
    if (email != null) body['email'] = email;
    if (address != null) body['address'] = address;
    if (role != null) body['role'] = role.toJson();
    if (neighborhoodId != null) body['neighborhood'] = neighborhoodId;

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
  Future<void> updatePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _apiClient.post(
      '/api/v1/users/$userId/change_password/',
      body: {'current_password': currentPassword, 'new_password': newPassword},
    );

    if (response.statusCode == 400 || response.statusCode == 403) {
      final errorBody = jsonDecode(response.body) as Map<String, dynamic>;

      if (errorBody.containsKey('code')) {
        throw Exception(errorBody['code']);
      }
      if (errorBody.containsKey('current_password')) {
        throw Exception(errorBody['current_password'][0]);
      }
      if (errorBody.containsKey('new_password')) {
        throw Exception(errorBody['new_password'][0]);
      }
      if (errorBody.containsKey('detail')) {
        throw Exception(errorBody['detail']);
      }

      throw Exception(AppTextsProfile.updatePasswordError);
    }

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(AppTextsProfile.updatePasswordError);
    }
  }

  @override
  Future<void> resetPassword({
    required int userId,
    required String newPassword,
  }) async {
    final response = await _apiClient.post(
      '/api/v1/users/$userId/reset_password/',
      body: {'new_password': newPassword},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(AppTextsProfile.updatePasswordError);
    }
  }

  @override
  Future<User> createUser({
    required String username,
    String email = '',
    required String firstName,
    required String lastName,
    required String password,
    String address = '',
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
        'address': address,
        'role': role.toJson(),
        if (neighborhoodId != null) 'neighborhood': neighborhoodId,
      },
    );

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return User.fromJson(json);
    }

    throw Exception(
      _extractErrorMessage(
        response.body,
        AppTextsUserRepositoryErrors.unknownRegistrationError,
      ),
    );
  }

  @override
  Future<List<User>> listPendingUsers() async {
    final response = await _apiClient.get('/api/v1/users/pending/');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final results = json is Map<String, dynamic>
          ? (json['results'] as List<dynamic>? ?? const [])
          : (json as List<dynamic>);
      return results
          .map((item) => User.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    throw Exception(
      '${AppTextsUserRepositoryErrors.fetchUsersError}: ${response.statusCode}',
    );
  }

  @override
  Future<User> approveUser({required int userId}) async {
    final response = await _apiClient.post(
      '/api/v1/users/$userId/approve/',
      body: const {},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return User.fromJson(json);
    }

    throw Exception(
      '${AppTextsUserRepositoryErrors.updateUserError}: ${response.statusCode}',
    );
  }

  @override
  Future<void> rejectUser({required int userId}) async {
    final response = await _apiClient.post(
      '/api/v1/users/$userId/reject/',
      body: const {},
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(
        '${AppTextsUserRepositoryErrors.deleteUserError}: ${response.statusCode}',
      );
    }
  }

  @override
  Future<List<Neighborhood>> listNeighborhoods() async {
    final response = await _apiClient.get('/api/v1/neighborhoods/');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data is List
          ? data
          : (data as Map<String, dynamic>)['results'] as List? ?? [];
      return results
          .map((json) => Neighborhood.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
        '${AppTextsUserRepositoryErrors.fetchNeighborhoodsError}: ${response.statusCode}',
      );
    }
  }
}
