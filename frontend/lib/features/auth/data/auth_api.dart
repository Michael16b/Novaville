import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthApi {
  // baseUrl example: http://localhost:8000
  final String baseUrl;
  final http.Client _client;

  AuthApi({required this.baseUrl, http.Client? client}) :
    _client = client ?? http.Client();

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    // Backend uses /api/v1/auth/token/ and expects 'username' + 'password'
    final url = Uri.parse('$baseUrl/api/v1/auth/token/');
    final resp = await _client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': email,
        'password': password,
      }),
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }

    // Propager l'erreur avec le corps si possible
    String message = 'Erreur de connexion';
    try {
      final body = jsonDecode(resp.body);
      if (body is Map && body['detail'] != null) {
        message = body['detail'] as String;
      }
    } catch (_) {}

    throw Exception(message);
  }

  Future<Map<String, dynamic>> refresh({required String refreshToken}) async {
    final url = Uri.parse('$baseUrl/api/v1/auth/token/refresh/');
    final resp = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refreshToken}),
    );

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return jsonDecode(resp.body) as Map<String, dynamic>;
    }

    throw Exception('Impossible de rafraîchir le token');
  }
}
