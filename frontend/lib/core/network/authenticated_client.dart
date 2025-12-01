import 'dart:async';

import 'package:http/http.dart' as http;

/// Client HTTP qui ajoute automatiquement un token d'authentification
/// dans les headers de toutes les requêtes sortantes.
///
/// Supporte également le refresh automatique du token en cas de 401.
class AuthenticatedClient extends http.BaseClient {
  /// Constructeur du client authentifié
  ///
  /// [tokenProvider] : fonction qui retourne le token d'accès actuel
  /// (ou null si non connecté)
  /// [onTokenRefreshNeeded] : callback optionnel appelé quand le token
  /// doit être rafraîchi (retourne le nouveau token ou null si échec)
  /// [inner] : client HTTP interne à utiliser (par défaut http.Client())
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

  // Verrou pour éviter les appels multiples simultanés au refresh
  Completer<String?>? _refreshCompleter;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Récupérer le token actuel
    final token = await _tokenProvider();

    // Ajouter le header Authorization si un token est disponible
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Effectuer la requête
    var response = await _inner.send(request);

    // Si 401 et qu'un callback de refresh est disponible, tenter le refresh
    if (response.statusCode == 401 && _onTokenRefreshNeeded != null) {
      // Utiliser un verrou pour éviter plusieurs refresh simultanés
      if (_refreshCompleter != null) {
        // Un refresh est déjà en cours, attendre sa fin
        await _refreshCompleter!.future;
      } else {
        // Démarrer un nouveau refresh
        _refreshCompleter = Completer<String?>();
        try {
          final newToken = await _onTokenRefreshNeeded();
          _refreshCompleter!.complete(newToken);

          if (newToken != null && newToken.isNotEmpty) {
            // Réessayer la requête originale avec le nouveau token
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

  /// Copie une requête HTTP pour pouvoir la réessayer
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
