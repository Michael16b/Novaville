import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/authenticated_client_factory.dart';
import 'package:frontend/features/auth/data/auth_repository_impl.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('AuthenticatedClientFactory', () {
    test('creates a client that uses the token from storage', () async {
      final storage = InMemoryTokenStorage();
      await storage.write(key: 'access_token', value: 'test-token-123');

      final mockClient = MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer test-token-123');
        return http.Response('{"data":"success"}', 200);
      });

      final client = AuthenticatedClientFactory.create(
        storage: storage,
        onRefresh: (refreshToken) async => 'new-token',
        inner: mockClient,
      );

      final response = await client.get(
        Uri.parse('http://localhost:8000/api/test/'),
      );

      expect(response.statusCode, 200);
    });

    test('automatically refreshes the token on a 401', () async {
      final storage = InMemoryTokenStorage();
      await storage.write(key: 'access_token', value: 'old-token');
      await storage.write(key: 'refresh_token', value: 'refresh-token-xyz');

      var requestCount = 0;
      var onRefreshCalled = false;
      String? receivedRefreshToken;

      final mockClient = MockClient((request) async {
        requestCount++;

        // First call: 401
        if (requestCount == 1) {
          return http.Response('{"detail":"Token expired"}', 401);
        }

        // Second call: verify the new token
        expect(request.headers['Authorization'], 'Bearer new-access-token');
        return http.Response('{"data":"success"}', 200);
      });

      final client = AuthenticatedClientFactory.create(
        storage: storage,
        onRefresh: (refreshToken) async {
          onRefreshCalled = true;
          receivedRefreshToken = refreshToken;
          return 'new-access-token';
        },
        inner: mockClient,
      );

      final response = await client.get(
        Uri.parse('http://localhost:8000/api/protected/'),
      );

      expect(onRefreshCalled, true);
      expect(receivedRefreshToken, 'refresh-token-xyz');
      expect(requestCount, 2);
      expect(response.statusCode, 200);

      // Verify the new token was saved
      final savedToken = await storage.read(key: 'access_token');
      expect(savedToken, 'new-access-token');
    });

    test('deletes tokens if the refresh fails', () async {
      final storage = InMemoryTokenStorage();
      await storage.write(key: 'access_token', value: 'old-token');
      await storage.write(key: 'refresh_token', value: 'refresh-token-xyz');

      final mockClient = MockClient((request) async {
        return http.Response('{"detail":"Token expired"}', 401);
      });

      final client = AuthenticatedClientFactory.create(
        storage: storage,
        onRefresh: (refreshToken) async {
          // Simulate a failed refresh
          throw Exception('Refresh failed');
        },
        inner: mockClient,
      );

      final response = await client.get(
        Uri.parse('http://localhost:8000/api/protected/'),
      );

      expect(response.statusCode, 401);

      // Verify the tokens were deleted
      final accessToken = await storage.read(key: 'access_token');
      final refreshToken = await storage.read(key: 'refresh_token');
      expect(accessToken, null);
      expect(refreshToken, null);
    });

    test('does not attempt a refresh if the refresh token is missing', () async {
      final storage = InMemoryTokenStorage();
      await storage.write(key: 'access_token', value: 'old-token');
      // No refresh token

      var onRefreshCalled = false;

      final mockClient = MockClient((request) async {
        return http.Response('{"detail":"Token expired"}', 401);
      });

      final client = AuthenticatedClientFactory.create(
        storage: storage,
        onRefresh: (refreshToken) async {
          onRefreshCalled = true;
          return 'new-token';
        },
        inner: mockClient,
      );

      final response = await client.get(
        Uri.parse('http://localhost:8000/api/protected/'),
      );

      expect(onRefreshCalled, false);
      expect(response.statusCode, 401);
    });
  });
}
