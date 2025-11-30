import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:frontend/features/auth/data/auth_repository.dart';

/// Client HTTP qui ajoute automatiquement le header Authorization
/// et tente un refresh du token si la réponse est 401.
class AuthenticatedClient extends http.BaseClient {
  AuthenticatedClient({required http.Client inner, required IAuthRepository authRepository})
    : _inner = inner,
      _authRepository = authRepository;

  final http.Client _inner;
  final IAuthRepository _authRepository;

  // Un seul refresh à la fois : autres requêtes attendent sa complétion
  Future<bool>? _refreshInProgress;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Cloner les headers car BaseRequest.headers peut être immuable selon l'implémentation
    request.headers.addAll(Map<String, String>.from(request.headers));

    final access = await _authRepository.getAccessToken();
    if (access != null && access.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $access';
    }

    http.StreamedResponse response;
    response = await _inner.send(request);

    if (response.statusCode != 401) return response;

    // 401 -> tenter un refresh (si un refresh est en cours, attendre)
    if (_refreshInProgress == null) {
      final completer = Completer<bool>();
      _refreshInProgress = completer.future;
      try {
        final ok = await _authRepository.tryRefresh();
        completer.complete(ok);
      } catch (e) {
        completer.complete(false);
      } finally {
        // Reset after small delay to avoid race where future still referenced
        Future<void>.delayed(Duration.zero, () => _refreshInProgress = null);
      }
    }

    final refreshed = await _refreshInProgress;
    if (refreshed == true) {
      // Reprendre le corps de la requête si possible. Pour simplicity, on re-crée
      // une nouvelle requête de même type sans body si body non-replayable.
      final newRequest = _rebuildRequest(request);
      final newAccess = await _authRepository.getAccessToken();
      if (newAccess != null && newAccess.isNotEmpty) {
        newRequest.headers['Authorization'] = 'Bearer $newAccess';
      }
      return _inner.send(newRequest);
    }

    return response;
  }

  http.BaseRequest _rebuildRequest(http.BaseRequest request) {
    // Limitation : si la requête contenait un non-replayable body (Stream), il ne sera pas re-sent.
    final newReq = http.Request(request.method, request.url);
    newReq.headers.addAll(request.headers);
    if (request is http.Request) {
      newReq.bodyBytes = request.bodyBytes;
    }
    return newReq;
  }

  @override
  void close() => _inner.close();
}

