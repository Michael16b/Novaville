import 'dart:convert';

import 'package:frontend/constants/texts.dart';
import 'package:frontend/features/auth/data/auth_repository.dart';
import 'package:http/http.dart' as http;

class AuthApi {
  AuthApi({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();
  // baseUrl example: http://localhost:8000
  final String baseUrl;
  final http.Client _client;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    // Backend uses /api/v1/auth/token/ and expects 'username' + 'password'
    final url = Uri.parse('$baseUrl/api/auth/token/');
    final resp = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': email, 'password': password}),
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

  Future<Map<String, dynamic>> refresh({required String refreshToken}) async {
    final url = Uri.parse('$baseUrl/api/auth/token/refresh');
    final resp = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refreshToken}),
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }

    throw AuthFailure(AppTexts.tokenRefreshFailed);
  }
}
