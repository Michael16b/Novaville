import 'dart:convert';
import 'package:http/http.dart' as http;

class UsefulInfoApiException implements Exception {
  final int statusCode;
  final String message;

  const UsefulInfoApiException({
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() => message;
}

class UsefulInfoApi {
  final http.Client client;
  final String baseUrl;

  UsefulInfoApi({required this.client, required this.baseUrl});

  /// GET /useful-info
  Future<Map<String, dynamic>> fetchUsefulInfo() async {
    final response = await client.get(
      Uri.parse('$baseUrl/api/v1/useful-info/'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw UsefulInfoApiException(
        statusCode: response.statusCode,
        message: _buildErrorMessage(
          response,
          fallback: 'Erreur récupération useful info',
        ),
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// PUT /useful-info (admin only)
  Future<void> updateUsefulInfo(Map<String, dynamic> payload) async {
    final response = await client.put(
      Uri.parse('$baseUrl/api/v1/useful-info/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw UsefulInfoApiException(
        statusCode: response.statusCode,
        message: _buildErrorMessage(
          response,
          fallback: 'Erreur mise à jour useful info',
        ),
      );
    }
  }

  String _buildErrorMessage(
    http.Response response, {
    required String fallback,
  }) {
    final body = response.body.trim();
    if (body.isEmpty) return '$fallback (${response.statusCode})';

    try {
      final decoded = jsonDecode(body);
      return '$fallback (${response.statusCode}) : $decoded';
    } catch (_) {
      return '$fallback (${response.statusCode}) : $body';
    }
  }
}
