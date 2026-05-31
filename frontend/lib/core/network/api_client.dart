import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:frontend/config/router.dart';
import 'package:go_router/go_router.dart';

/// Binary file attached to a multipart API request.
class MultipartApiFile {
  /// Creates a multipart file payload.
  const MultipartApiFile({
    required this.field,
    required this.filename,
    required this.bytes,
  });

  /// Multipart field name.
  final String field;

  /// Original file name.
  final String filename;

  /// File bytes.
  final Uint8List bytes;
}

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

  /// Checks if the server is in maintenance (502 or 503)
  /// and redirects to the maintenance screen if needed.
  void _checkMaintenance(int statusCode) {
    if (statusCode == 502 || statusCode == 503) {
      rootNavigatorKey.currentContext?.go('/maintenance');
    }
  }

  /// Performs a GET request.
  Future<http.Response> get(
    String path, {
    Map<String, String?>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = buildUri(path, queryParameters);
    final mergedHeaders = {...defaultHeaders, ...?headers};
    final response = await client.get(uri, headers: mergedHeaders);
    _checkMaintenance(response.statusCode);
    return response;
  }

  /// Performs a POST request.
  Future<http.Response> post(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String?>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = buildUri(path, queryParameters);
    final mergedHeaders = {...defaultHeaders, ...?headers};
    final response = await client.post(
      uri,
      headers: mergedHeaders,
      body: jsonEncode(body),
    );
    _checkMaintenance(response.statusCode);
    return response;
  }

  /// Performs a multipart POST request.
  Future<http.StreamedResponse> postMultipart(
    String path, {
    required Map<String, String> fields,
    required List<MultipartApiFile> files,
    Map<String, String?>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = buildUri(path, queryParameters);
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll({'Accept': 'application/json', ...?headers})
      ..fields.addAll(fields)
      ..files.addAll(
        files.map(
          (file) => http.MultipartFile.fromBytes(
            file.field,
            file.bytes,
            filename: file.filename,
          ),
        ),
      );

    final response = await client.send(request);
    _checkMaintenance(response.statusCode);
    return response;
  }

  /// Performs a multipart PATCH request.
  Future<http.StreamedResponse> patchMultipart(
    String path, {
    required Map<String, String> fields,
    required List<MultipartApiFile> files,
    Map<String, String?>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = buildUri(path, queryParameters);
    final request = http.MultipartRequest('PATCH', uri)
      ..headers.addAll({'Accept': 'application/json', ...?headers})
      ..fields.addAll(fields)
      ..files.addAll(
        files.map(
          (file) => http.MultipartFile.fromBytes(
            file.field,
            file.bytes,
            filename: file.filename,
          ),
        ),
      );

    final response = await client.send(request);
    _checkMaintenance(response.statusCode);
    return response;
  }

  /// Performs a PUT request.
  Future<http.Response> put(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String?>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = buildUri(path, queryParameters);
    final mergedHeaders = {...defaultHeaders, ...?headers};
    final response = await client.put(
      uri,
      headers: mergedHeaders,
      body: jsonEncode(body),
    );
    _checkMaintenance(response.statusCode);
    return response;
  }

  /// Performs a DELETE request.
  Future<http.Response> delete(
    String path, {
    Map<String, String?>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = buildUri(path, queryParameters);
    final mergedHeaders = {...defaultHeaders, ...?headers};
    final response = await client.delete(uri, headers: mergedHeaders);
    _checkMaintenance(response.statusCode);
    return response;
  }

  /// Performs a PATCH request.
  Future<http.Response> patch(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String?>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = buildUri(path, queryParameters);
    final mergedHeaders = {...defaultHeaders, ...?headers};
    final response = await client.patch(
      uri,
      headers: mergedHeaders,
      body: jsonEncode(body),
    );
    _checkMaintenance(response.statusCode);
    return response;
  }

  /// Closes the HTTP client.
  void close() {
    client.close();
  }
}
