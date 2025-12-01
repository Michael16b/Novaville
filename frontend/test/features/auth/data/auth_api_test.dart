import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/constants/texts.dart';
import 'package:frontend/features/auth/data/auth_api.dart';
import 'package:frontend/features/auth/data/auth_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('AuthApi', () {
    const baseUrl = 'http://localhost:8000';

    test('login envoie username et password au bon endpoint', () async {
      final mockClient = MockClient((request) async {
        // Vérifier la méthode et le path
        expect(request.method, 'POST');
        expect(request.url.toString(), 'http://localhost:8000/api/auth/token/');

        // Vérifier les headers
        expect(request.headers['Content-Type'], 'application/json');

        // Vérifier le body
        expect(request.body, '{"username":"admin","password":"ChangeMe123"}');

        // Retourner une réponse de succès
        return http.Response(
          '{"access":"test-access-token","refresh":"test-refresh-token","user":{"id":1,"username":"admin","email":"admin@example.com"}}',
          200,
        );
      });

      final authApi = AuthApi(baseUrl: baseUrl, client: mockClient);

      final result = await authApi.login(
        email: 'admin',
        password: 'ChangeMe123',
      );

      expect(result['access'], 'test-access-token');
      expect(result['refresh'], 'test-refresh-token');
      expect(result['user']['username'], 'admin');
    });

    test('login lance AuthFailure avec message en cas de 401', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"detail":"Invalid credentials"}', 401);
      });

      final authApi = AuthApi(baseUrl: baseUrl, client: mockClient);

      expect(
        () => authApi.login(email: 'wrong', password: 'wrong'),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.message,
            'message',
            'Invalid credentials',
          ),
        ),
      );
    });

    test(
      'login lance AuthFailure avec message par défaut si 401 sans detail',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response('{}', 401);
        });

        final authApi = AuthApi(baseUrl: baseUrl, client: mockClient);

        expect(
          () => authApi.login(email: 'wrong', password: 'wrong'),
          throwsA(
            isA<AuthFailure>().having(
              (e) => e.message,
              'message',
              AppTexts.invalidCredentials,
            ),
          ),
        );
      },
    );

    test("login lance AuthFailure en cas d'erreur serveur 500", () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"detail":"Internal server error"}', 500);
      });

      final authApi = AuthApi(baseUrl: baseUrl, client: mockClient);

      expect(
        () => authApi.login(email: 'admin', password: 'test'),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.message,
            'message',
            'Internal server error',
          ),
        ),
      );
    });

    test('login gère les erreurs de parsing JSON', () async {
      final mockClient = MockClient((request) async {
        return http.Response('invalid json', 400);
      });

      final authApi = AuthApi(baseUrl: baseUrl, client: mockClient);

      expect(
        () => authApi.login(email: 'admin', password: 'test'),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.message,
            'message',
            AppTexts.genericConnectionError,
          ),
        ),
      );
    });

    test('refresh envoie le refresh token au bon endpoint', () async {
      final mockClient = MockClient((request) async {
        // Vérifier la méthode et le path
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'http://localhost:8000/api/auth/token/refresh/',
        );

        // Vérifier le body
        expect(request.body, '{"refresh":"old-refresh-token"}');

        // Retourner un nouveau access token
        return http.Response('{"access":"new-access-token"}', 200);
      });

      final authApi = AuthApi(baseUrl: baseUrl, client: mockClient);

      final result = await authApi.refresh(refreshToken: 'old-refresh-token');

      expect(result['access'], 'new-access-token');
    });

    test("refresh lance AuthFailure en cas d'erreur", () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"detail":"Token expired"}', 401);
      });

      final authApi = AuthApi(baseUrl: baseUrl, client: mockClient);

      expect(
        () => authApi.refresh(refreshToken: 'expired-token'),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.message,
            'message',
            AppTexts.tokenRefreshFailed,
          ),
        ),
      );
    });

    test("login extrait le message d'erreur depuis un champ list", () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"password":["This field is required"]}', 400);
      });

      final authApi = AuthApi(baseUrl: baseUrl, client: mockClient);

      expect(
        () => authApi.login(email: 'admin', password: ''),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.message,
            'message',
            'This field is required',
          ),
        ),
      );
    });
  });
}
