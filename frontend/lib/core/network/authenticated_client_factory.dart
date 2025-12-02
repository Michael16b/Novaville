import 'package:frontend/core/network/authenticated_client.dart';
import 'package:frontend/features/auth/data/auth_repository_impl.dart';
import 'package:http/http.dart' as http;

/// Factory pour créer un AuthenticatedClient configuré avec
/// la gestion automatique du refresh token
class AuthenticatedClientFactory {
  /// Crée un client authentifié avec gestion automatique du refresh token
  ///
  /// [storage] : le storage contenant les tokens
  /// [onRefresh] : callback appelé pour rafraîchir le token
  /// (doit retourner le nouveau access token ou null si échec)
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
        // Récupérer le refresh token
        final refreshToken = await storage.read(key: 'refresh_token');
        if (refreshToken == null) return null;

        try {
          // Appeler le callback de refresh
          final newAccessToken = await onRefresh(refreshToken);

          if (newAccessToken != null) {
            // Sauvegarder le nouveau token
            await storage.write(key: 'access_token', value: newAccessToken);
          }

          return newAccessToken;
        } catch (e) {
          // En cas d'erreur, supprimer les tokens (déconnexion)
          await storage.delete(key: 'access_token');
          await storage.delete(key: 'refresh_token');
          return null;
        }
      },
      inner: inner,
    );
  }
}
