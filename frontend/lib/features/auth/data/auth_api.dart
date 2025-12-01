import 'dart:convert';

import 'package:frontend/constants/api_routes.dart';
import 'package:frontend/constants/texts.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/auth/data/auth_repository.dart';

/// Client API pour les opérations d'authentification
class AuthApi extends ApiClient {
  /// Constructeur du client d'authentification
  AuthApi({required super.baseUrl, super.client});

  /// Authentifie un utilisateur avec son email et mot de passe
  ///
  /// Retourne un Map contenant les tokens et les infos utilisateur
  /// Lance [AuthFailure] en cas d'erreur
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    // Backend uses /api/auth/token/ and expects 'username' + 'password'
    final resp = await post(
      ApiRoutes.authToken,
      body: {'username': email, 'password': password},
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }

    // Propager l'erreur avec un message utilisateur clair si possible
    var message = AppTexts.genericConnectionError;
    try {
      final body = jsonDecode(resp.body);
      if (resp.statusCode == 401) {
        // 401 -> identifiants invalides
        if (body is Map && body['detail'] != null) {
          message = body['detail'] as String;
        } else {
          message = AppTexts.invalidCredentials;
        }
      } else {
        if (body is Map && body['detail'] != null) {
          message = body['detail'] as String;
        } else if (body is Map && body.values.isNotEmpty) {
          // essayer d'extraire un message depuis le premier champ
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

  /// Rafraîchit le token d'accès avec un refresh token
  ///
  /// Retourne un Map contenant le nouveau token d'accès
  /// Lance [AuthFailure] en cas d'erreur
  Future<Map<String, dynamic>> refresh({required String refreshToken}) async {
    final resp = await post(
      ApiRoutes.authTokenRefresh,
      body: {'refresh': refreshToken},
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }

    throw AuthFailure(AppTexts.tokenRefreshFailed);
  }
}
