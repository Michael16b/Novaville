import 'dart:async';

import 'package:http/http.dart' as http;

/// HTTP client that automatically injects an authentication token
/// into the headers of all outgoing requests.
///
/// Also supports automatic token refresh on 401 responses.
class AuthenticatedClient extends http.BaseClient {
  /// Creates an authenticated HTTP client.
  ///
  /// [tokenProvider]: function that returns the current access token
  /// (or null if not authenticated).
  /// [onTokenRefreshNeeded]: optional callback invoked when the token
  /// needs to be refreshed (returns the new token or null on failure).
  /// [inner]: underlying HTTP client to use (defaults to http.Client()).
  AuthenticatedClient({
    required Future<String?> Function() tokenProvider,
    Future<String?> Function()? onTokenRefreshNeeded,
    http.Client? inner,
  }) : _tokenProvider = tokenProvider,
       _onTokenRefreshNeeded = onTokenRefreshNeeded,
       _inner = inner ?? http.Client();

  final http.Client _inner;
  final Future<String?> Function() _tokenProvider;
  final Future<String?> Function()? _onTokenRefreshNeeded;

  // Lock to prevent multiple simultaneous refresh calls
  Completer<String?>? _refreshCompleter;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Retrieve the current token
    final token = await _tokenProvider();

    // Add the Authorization header if a token is available
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Perform the request
    var response = await _inner.send(request);

    // If 401 and a refresh callback is available, attempt a token refresh
    if (response.statusCode == 401 && _onTokenRefreshNeeded != null) {
      // Use a lock to avoid multiple simultaneous refreshes
      if (_refreshCompleter != null) {
        // A refresh is already in progress — wait for it to complete
        await _refreshCompleter!.future;
      } else {
        // Start a new refresh
        _refreshCompleter = Completer<String?>();
        try {
          final newToken = await _onTokenRefreshNeeded();
          _refreshCompleter!.complete(newToken);

          if (newToken != null && newToken.isNotEmpty) {
            // Retry the original request with the new token
            final newRequest = _copyRequest(request);
            newRequest.headers['Authorization'] = 'Bearer $newToken';
            response = await _inner.send(newRequest);
          }
        } catch (e) {
          _refreshCompleter!.completeError(e);
        } finally {
          _refreshCompleter = null;
        }
      }
    }

    return response;
  }

  /// Copies an HTTP request so it can be retried after a token refresh.
  http.BaseRequest _copyRequest(http.BaseRequest request) {
    http.BaseRequest newRequest;

    if (request is http.Request) {
      newRequest = http.Request(request.method, request.url)
        ..bodyBytes = request.bodyBytes;
    } else if (request is http.MultipartRequest) {
      newRequest = http.MultipartRequest(request.method, request.url)
        ..fields.addAll(request.fields)
        ..files.addAll(request.files);
    } else if (request is http.StreamedRequest) {
      throw UnsupportedError(
        'Cannot retry a StreamedRequest after token refresh',
      );
    } else {
      throw UnsupportedError('Unknown request type: ${request.runtimeType}');
    }

    newRequest
      ..persistentConnection = request.persistentConnection
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects
      ..headers.addAll(request.headers);

    return newRequest;
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
