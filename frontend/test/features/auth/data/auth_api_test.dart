import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/constants/texts/texts_auth.dart';
import 'package:frontend/features/auth/data/auth_api.dart';
import 'package:frontend/features/auth/data/auth_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('AuthApi', () {
    const baseUrl = 'http://localhost:8000';

    test('login sends username and password to the correct endpoint', () async {
      final mockClient = MockClient((request) async {
        // Verify the method and path
        expect(request.method, 'POST');
        expect(request.url.toString(), 'http://localhost:8000/api/auth/token/');

        // Verify the headers
        expect(request.headers['Content-Type'], 'application/json');

        // Verify the body
        expect(request.body, '{"username":"admin","password":"ChangeMe123"}');

        // Return a success response
        return http.Response(
          '{"access":"test-access-token","refresh":"test-refresh-token","user":{"id":1,"username":"admin","email":"admin@example.com"}}',
          200,
        );
      });

      final authApi = AuthApi(baseUrl: baseUrl, client: mockClient);

      final result = await authApi.login(
        username: 'admin',
        password: 'ChangeMe123',
      );

      expect(result['access'], 'test-access-token');
      expect(result['refresh'], 'test-refresh-token');
      expect(result['user']['username'], 'admin');
    });

    test('login throws AuthFailure with message on 401', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"detail":"Invalid credentials"}', 401);
      });

      final authApi = AuthApi(baseUrl: baseUrl, client: mockClient);

      expect(
        () => authApi.login(username: 'wrong', password: 'wrong'),
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
      'login throws AuthFailure with default message on 401 without detail',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response('{}', 401);
        });

        final authApi = AuthApi(baseUrl: baseUrl, client: mockClient);

        expect(
          () => authApi.login(username: 'wrong', password: 'wrong'),
          throwsA(
            isA<AuthFailure>().having(
              (e) => e.message,
              'message',
              AppTextsAuth.invalidCredentials,
            ),
          ),
        );
      },
    );

    test("login throws AuthFailure on 500 server error", () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"detail":"Internal server error"}', 500);
      });

      final authApi = AuthApi(baseUrl: baseUrl, client: mockClient);

      expect(
        () => authApi.login(username: 'admin', password: 'test'),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.message,
            'message',
            'Internal server error',
          ),
        ),
      );
    });

    test('login handles JSON parsing errors', () async {
      final mockClient = MockClient((request) async {
        return http.Response('invalid json', 400);
      });

      final authApi = AuthApi(baseUrl: baseUrl, client: mockClient);

      expect(
        () => authApi.login(username: 'admin', password: 'test'),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.message,
            'message',
            AppTextsAuth.genericConnectionError,
          ),
        ),
      );
    });

    test('refresh sends the refresh token to the correct endpoint', () async {
      final mockClient = MockClient((request) async {
        // Verify the method and path
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'http://localhost:8000/api/auth/token/refresh/',
        );

        // Verify the body
        expect(request.body, '{"refresh":"old-refresh-token"}');

        // Return a new access token
        return http.Response('{"access":"new-access-token"}', 200);
      });

      final authApi = AuthApi(baseUrl: baseUrl, client: mockClient);

      final result = await authApi.refresh(refreshToken: 'old-refresh-token');

      expect(result['access'], 'new-access-token');
    });

    test("refresh throws AuthFailure on error", () async {
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
            AppTextsAuth.tokenRefreshFailed,
          ),
        ),
      );
    });

    test("login extracts the error message from a list field", () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"password":["This field is required"]}', 400);
      });

      final authApi = AuthApi(baseUrl: baseUrl, client: mockClient);

      expect(
        () => authApi.login(username: 'admin', password: ''),
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
