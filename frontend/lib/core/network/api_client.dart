import 'dart:convert';

import 'package:http/http.dart' as http;

/// Classe de base pour tous les clients API
/// Fournit des méthodes communes pour construire les URLs
/// et gérer les requêtes HTTP
class ApiClient {
  /// Constructeur du client API
  ApiClient({required this.baseUrl, http.Client? client})
    : client = client ?? http.Client();

  /// URL de base de l'API (ex: http://localhost:8000)
  final String baseUrl;

  /// Client HTTP utilisé pour effectuer les requêtes
  final http.Client client;

  /// Construit une URI complète à partir du baseUrl et d'un path
  /// Gère automatiquement les slashs et les paramètres de requête
  Uri buildUri(String path, [Map<String, String?>? queryParameters]) {
    // Assurer que baseUrl ne se termine pas par /
    // et que path commence par /
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$cleanBase$cleanPath';

    final uri = Uri.parse(fullUrl);

    // Ajouter les paramètres de requête si présents
    if (queryParameters != null && queryParameters.isNotEmpty) {
      // Filtrer les valeurs null
      final filteredParams = Map<String, String>.fromEntries(
        queryParameters.entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
      return uri.replace(queryParameters: filteredParams);
    }

    return uri;
  }

  /// Headers par défaut pour les requêtes JSON
  Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Effectue une requête GET
  Future<http.Response> get(
    String path, {
    Map<String, String?>? queryParameters,
    Map<String, String>? headers,
  }) {
    final uri = buildUri(path, queryParameters);
    final mergedHeaders = {...defaultHeaders, ...?headers};
    return client.get(uri, headers: mergedHeaders);
  }

  /// Effectue une requête POST
  Future<http.Response> post(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String?>? queryParameters,
    Map<String, String>? headers,
  }) {
    final uri = buildUri(path, queryParameters);
    final mergedHeaders = {...defaultHeaders, ...?headers};
    return client.post(uri, headers: mergedHeaders, body: jsonEncode(body));
  }

  /// Effectue une requête PUT
  Future<http.Response> put(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String?>? queryParameters,
    Map<String, String>? headers,
  }) {
    final uri = buildUri(path, queryParameters);
    final mergedHeaders = {...defaultHeaders, ...?headers};
    return client.put(uri, headers: mergedHeaders, body: jsonEncode(body));
  }

  /// Effectue une requête DELETE
  Future<http.Response> delete(
    String path, {
    Map<String, String?>? queryParameters,
    Map<String, String>? headers,
  }) {
    final uri = buildUri(path, queryParameters);
    final mergedHeaders = {...defaultHeaders, ...?headers};
    return client.delete(uri, headers: mergedHeaders);
  }

  /// Ferme le client HTTP
  void close() {
    client.close();
  }
}
