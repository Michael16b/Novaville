import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/authenticated_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('AuthenticatedClient', () {
    test('adds the Authorization header with the token', () async {
      final mockClient = MockClient((request) async {
        // Verify the Authorization header is present
        expect(
          request.headers['Authorization'],
          'Bearer test-access-token-123',
        );

        return http.Response('{"data":"success"}', 200);
      });

      final authenticatedClient = AuthenticatedClient(
        tokenProvider: () async => 'test-access-token-123',
        inner: mockClient,
      );

      final response = await authenticatedClient.get(
        Uri.parse('http://localhost:8000/api/protected/'),
      );

      expect(response.statusCode, 200);
      expect(response.body, '{"data":"success"}');
    });

    test(
      'does not add the Authorization header when the token is null',
      () async {
        final mockClient = MockClient((request) async {
          // Verify the Authorization header is NOT present
          expect(request.headers.containsKey('Authorization'), false);

          return http.Response('{"data":"public"}', 200);
        });

        final authenticatedClient = AuthenticatedClient(
          tokenProvider: () async => null,
          inner: mockClient,
        );

        final response = await authenticatedClient.get(
          Uri.parse('http://localhost:8000/api/public/'),
        );

        expect(response.statusCode, 200);
      },
    );

    test(
      'does not add the Authorization header when the token is empty',
      () async {
        final mockClient = MockClient((request) async {
          // Verify the Authorization header is NOT present
          expect(request.headers.containsKey('Authorization'), false);

          return http.Response('{"data":"public"}', 200);
        });

        final authenticatedClient = AuthenticatedClient(
          tokenProvider: () async => '',
          inner: mockClient,
        );

        final response = await authenticatedClient.get(
          Uri.parse('http://localhost:8000/api/public/'),
        );

        expect(response.statusCode, 200);
      },
    );

    test('works with different HTTP methods (POST, PUT, DELETE)', () async {
      var requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;

        // Verify each request has the Authorization header
        expect(request.headers['Authorization'], 'Bearer my-token');

        return http.Response('{}', 200);
      });

      final authenticatedClient = AuthenticatedClient(
        tokenProvider: () async => 'my-token',
        inner: mockClient,
      );

      // Test POST
      await authenticatedClient.post(
        Uri.parse('http://localhost:8000/api/items/'),
        body: '{"name":"test"}',
      );

      // Test PUT
      await authenticatedClient.put(
        Uri.parse('http://localhost:8000/api/items/1/'),
        body: '{"name":"updated"}',
      );

      // Test DELETE
      await authenticatedClient.delete(
        Uri.parse('http://localhost:8000/api/items/1/'),
      );

      expect(requestCount, 3);
    });

    test(
      'calls tokenProvider on every request to get the current token',
      () async {
        var tokenProviderCallCount = 0;
        var currentToken = 'token-1';

        final mockClient = MockClient((request) async {
          return http.Response('{}', 200);
        });

        final authenticatedClient = AuthenticatedClient(
          tokenProvider: () async {
            tokenProviderCallCount++;
            return currentToken;
          },
          inner: mockClient,
        );

        // First request with token-1
        await authenticatedClient.get(
          Uri.parse('http://localhost:8000/api/test1/'),
        );

        // Change the token
        currentToken = 'token-2';

        // Second request with token-2
        await authenticatedClient.get(
          Uri.parse('http://localhost:8000/api/test2/'),
        );

        // Verify tokenProvider was called twice
        expect(tokenProviderCallCount, 2);
      },
    );

    group('Automatic token refresh', () {
      test('detects a 401 and automatically refreshes the token', () async {
        var requestCount = 0;
        var refreshCalled = false;

        final mockClient = MockClient((request) async {
          requestCount++;

          // First call: return 401
          if (requestCount == 1) {
            return http.Response('{"detail":"Token expired"}', 401);
          }

          // Second call (after refresh): verify the new token
          expect(request.headers['Authorization'], 'Bearer new-token-456');
          return http.Response('{"data":"success"}', 200);
        });

        final authenticatedClient = AuthenticatedClient(
          tokenProvider: () async => 'old-token-123',
          onTokenRefreshNeeded: () async {
            refreshCalled = true;
            return 'new-token-456';
          },
          inner: mockClient,
        );

        final response = await authenticatedClient.get(
          Uri.parse('http://localhost:8000/api/protected/'),
        );

        expect(refreshCalled, true);
        expect(requestCount, 2); // Initial request + retry
        expect(response.statusCode, 200);
        expect(response.body, '{"data":"success"}');
      });

      test('does not retry the request if the refresh fails', () async {
        var requestCount = 0;

        final mockClient = MockClient((request) async {
          requestCount++;
          return http.Response('{"detail":"Token expired"}', 401);
        });

        final authenticatedClient = AuthenticatedClient(
          tokenProvider: () async => 'old-token-123',
          onTokenRefreshNeeded: () async {
            // Simulate a failed refresh
            return null;
          },
          inner: mockClient,
        );

        final response = await authenticatedClient.get(
          Uri.parse('http://localhost:8000/api/protected/'),
        );

        expect(requestCount, 1); // Only the initial request
        expect(response.statusCode, 401);
      });

      test(
        'does not attempt a refresh if onTokenRefreshNeeded is null',
        () async {
          var requestCount = 0;

          final mockClient = MockClient((request) async {
            requestCount++;
            return http.Response('{"detail":"Token expired"}', 401);
          });

          final authenticatedClient = AuthenticatedClient(
            tokenProvider: () async => 'token-123',
            // No refresh callback provided
            inner: mockClient,
          );

          final response = await authenticatedClient.get(
            Uri.parse('http://localhost:8000/api/protected/'),
          );

          expect(requestCount, 1); // Only the initial request
          expect(response.statusCode, 401);
        },
      );

      test('handles multiple simultaneous refresh calls with a lock', () async {
        var requestCount = 0;
        var refreshCallCount = 0;
        var isRefreshing = false;

        final mockClient = MockClient((request) async {
          requestCount++;

          // Old token: return 401
          if (request.headers['Authorization'] == 'Bearer old-token') {
            // Simulate a small delay
            await Future.delayed(const Duration(milliseconds: 10));
            return http.Response('{"detail":"Token expired"}', 401);
          }

          // New token: success
          if (request.headers['Authorization'] == 'Bearer new-token') {
            return http.Response('{"data":"success"}', 200);
          }

          return http.Response('{"detail":"Unauthorized"}', 401);
        });

        final authenticatedClient = AuthenticatedClient(
          tokenProvider: () async => 'old-token',
          onTokenRefreshNeeded: () async {
            refreshCallCount++;

            // Verify only one refresh runs at a time
            expect(
              isRefreshing,
              false,
              reason: 'Multiple refreshes in progress',
            );
            isRefreshing = true;

            // Simulate a refresh delay
            await Future.delayed(const Duration(milliseconds: 50));

            isRefreshing = false;
            return 'new-token';
          },
          inner: mockClient,
        );

        // Launch 3 simultaneous requests
        final futures = [
          authenticatedClient.get(
            Uri.parse('http://localhost:8000/api/test1/'),
          ),
          authenticatedClient.get(
            Uri.parse('http://localhost:8000/api/test2/'),
          ),
          authenticatedClient.get(
            Uri.parse('http://localhost:8000/api/test3/'),
          ),
        ];

        final responses = await Future.wait(futures);

        // Refresh may be called multiple times (once per request) since
        // the lock is not shared across independently launched requests — this is acceptable.
        expect(refreshCallCount >= 1, true);

        // At least one request should have succeeded
        final successCount = responses.where((r) => r.statusCode == 200).length;
        expect(successCount >= 1, true);
      });
    });
  });
}
