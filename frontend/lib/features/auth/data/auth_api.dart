import 'dart:convert';

import 'package:frontend/constants/api_routes.dart';
import 'package:frontend/constants/texts/texts_auth.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/auth/data/auth_repository.dart';

/// API client for authentication operations.
class AuthApi extends ApiClient {
  /// Creates an authentication API client.
  AuthApi({required super.baseUrl, super.client});

  /// Authenticates a user with their username and password.
  ///
  /// Returns a [Map] containing the tokens and user information.
  /// Throws [AuthFailure] on error.
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    // Backend uses /api/auth/token/ and expects 'username' + 'password'
    final resp = await post(
      ApiRoutes.authToken,
      body: {'username': username, 'password': password},
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }

    // Propagate the error with a user-friendly message when possible
    var message = AppTextsAuth.genericConnectionError;
    try {
      final body = jsonDecode(resp.body);
      if (resp.statusCode == 401) {
        // 401 -> always display generic message to avoid exposing details
        message = AppTextsAuth.invalidCredentials;
      } else {
        if (body is Map && body['detail'] != null) {
          message = body['detail'] as String;
        } else if (body is Map && body.values.isNotEmpty) {
          // Try to extract a message from the first field
          final first = body.values.first;
          if (first is List && first.isNotEmpty) {
            message = first.first.toString();
          } else if (first != null) {
            message = first.toString();
          }
        }
      }
    } catch (_) {}

    throw AuthFailure(message);
  }

  /// Refreshes the access token using a refresh token.
  ///
  /// Returns a [Map] containing the new access token.
  /// Throws [AuthFailure] on error.
  Future<Map<String, dynamic>> refresh({required String refreshToken}) async {
    final resp = await post(
      ApiRoutes.authTokenRefresh,
      body: {'refresh': refreshToken},
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }

    throw AuthFailure(AppTextsAuth.tokenRefreshFailed);
  }
}
