import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/authenticated_client.dart';
import 'package:frontend/features/auth/data/auth_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('AuthenticatedClient', () {
    test('ajoute Authorization header quand access token présent', () async {
      final repo = FakeAuthRepository();
      await repo.login(email: 'user', password: 'pass');

      final inner = MockClient((request) async {
        expect(request.headers['Authorization'], isNotNull);
        expect(request.headers['Authorization'], contains('fake-token-for'));
        return http.Response('ok', 200);
      });

      final client = AuthenticatedClient(inner: inner, authRepository: repo);
      final resp = await client.get(Uri.parse('https://example.com/test'));
      expect(resp.statusCode, 200);
    });

    test(
      'sur 401 tente refresh et retente la requête quand refresh succeed',
      () async {
        final repo = FakeAuthRepository();
        await repo.login(email: 'user2', password: 'pass2');

        var call = 0;
        final inner = MockClient((request) async {
          call++;
          if (call == 1) {
            // première tentative -> 401
            expect(
              request.headers['Authorization'],
              contains('fake-token-for'),
            );
            return http.Response('unauth', 401);
          }
          // après refresh, le repo fake met _token = 'refreshed-fake-token'
          expect(
            request.headers['Authorization'],
            contains('refreshed-fake-token'),
          );
          return http.Response('ok', 200);
        });

        final client = AuthenticatedClient(inner: inner, authRepository: repo);
        final resp = await client.get(
          Uri.parse('https://example.com/protected'),
        );
        expect(resp.statusCode, 200);
        expect(call, 2);
      },
    );

    test('si refresh échoue renvoie la réponse 401 originale', () async {
      // Créer un repo qui échoue au refresh
      final repo = _FailingRefreshRepo();
      await repo.login(email: 'u', password: 'p');

      final inner = MockClient((request) async {
        return http.Response('unauth', 401);
      });

      final client = AuthenticatedClient(inner: inner, authRepository: repo);
      final resp = await client.get(Uri.parse('https://example.com/protected'));
      expect(resp.statusCode, 401);
    });
  });
}

class _FailingRefreshRepo extends FakeAuthRepository {
  @override
  Future<bool> tryRefresh() async {
    // simulate failed refresh
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return false;
  }
}
