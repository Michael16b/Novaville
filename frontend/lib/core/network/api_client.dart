import 'dart:convert';

import 'package:http/http.dart' as http;

/// Base class for all API clients.
/// Provides common methods to build URLs and handle HTTP requests.
class ApiClient {
  /// Creates an API client.
  ApiClient({required this.baseUrl, http.Client? client})
    : client = client ?? http.Client();

  /// Base URL of the API (e.g. http://localhost:8000)
  final String baseUrl;

  /// HTTP client used to perform requests.
  final http.Client client;

  /// Builds a full URI from [baseUrl] and a [path].
  /// Automatically handles trailing/leading slashes and query parameters.
  Uri buildUri(String path, [Map<String, String?>? queryParameters]) {
    // Ensure baseUrl does not end with / and path starts with /
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$cleanBase$cleanPath';

    final uri = Uri.parse(fullUrl);

    // Append query parameters if present
    if (queryParameters != null && queryParameters.isNotEmpty) {
      // Filter out null values
      final filteredParams = Map<String, String>.fromEntries(
        queryParameters.entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
      return uri.replace(queryParameters: filteredParams);
    }

    return uri;
  }

  /// Default headers for JSON requests.
  Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Performs a GET request.
  Future<http.Response> get(
    String path, {
    Map<String, String?>? queryParameters,
    Map<String, String>? headers,
  }) {
    final uri = buildUri(path, queryParameters);
    final mergedHeaders = {...defaultHeaders, ...?headers};
    return client.get(uri, headers: mergedHeaders);
  }

  /// Performs a POST request.
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

  /// Performs a PUT request.
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

  /// Performs a DELETE request.
  Future<http.Response> delete(
    String path, {
    Map<String, String?>? queryParameters,
    Map<String, String>? headers,
  }) {
    final uri = buildUri(path, queryParameters);
    final mergedHeaders = {...defaultHeaders, ...?headers};
    return client.delete(uri, headers: mergedHeaders);
  }

  /// Performs a PATCH request.
  Future<http.Response> patch(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String?>? queryParameters,
    Map<String, String>? headers,
  }) {
    final uri = buildUri(path, queryParameters);
    final mergedHeaders = {...defaultHeaders, ...?headers};
    return client.patch(uri, headers: mergedHeaders, body: jsonEncode(body));
  }

  /// Performs a multipart POST request.
  Future<http.StreamedResponse> multipartPost(
    String path, {
    Map<String, String> fields = const {},
    List<http.MultipartFile> files = const [],
    Map<String, String?>? queryParameters,
    Map<String, String>? headers,
  }) {
    final uri = buildUri(path, queryParameters);
    final request = http.MultipartRequest('POST', uri);
    request.fields.addAll(fields);
    request.files.addAll(files);
    if (headers != null) {
      request.headers.addAll(headers);
    }
    return client.send(request);
  }

  /// Closes the HTTP client.
  void close() {
    client.close();
  }
}
