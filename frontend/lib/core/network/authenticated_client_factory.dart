import 'package:frontend/core/network/authenticated_client.dart';
import 'package:frontend/features/auth/data/auth_repository_impl.dart';
import 'package:http/http.dart' as http;

/// Factory for creating an [AuthenticatedClient] configured with
/// automatic token refresh support.
class AuthenticatedClientFactory {
  /// Creates an authenticated client with automatic token refresh handling.
  ///
  /// [storage]: the storage holding the tokens.
  /// [onRefresh]: callback invoked to refresh the token
  /// (must return the new access token or null on failure).
  static AuthenticatedClient create({
    required TokenStorage storage,
    required Future<String?> Function(String refreshToken) onRefresh,
    http.Client? inner,
  }) {
    return AuthenticatedClient(
      tokenProvider: () async {
        return storage.read(key: 'access_token');
      },
      onTokenRefreshNeeded: () async {
        // Retrieve the refresh token
        final refreshToken = await storage.read(key: 'refresh_token');
        if (refreshToken == null) return null;

        try {
          // Invoke the refresh callback
          final newAccessToken = await onRefresh(refreshToken);

          if (newAccessToken != null) {
            // Persist the new access token
            await storage.write(key: 'access_token', value: newAccessToken);
          }

          return newAccessToken;
        } catch (e) {
          // On error, delete tokens to force logout
          await storage.delete(key: 'access_token');
          await storage.delete(key: 'refresh_token');
          return null;
        }
      },
      inner: inner,
    );
  }
}
