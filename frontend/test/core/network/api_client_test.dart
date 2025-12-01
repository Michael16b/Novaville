import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ApiClient', () {
    test('buildUri construit correctement une URI avec baseUrl et path', () {
      final client = ApiClient(baseUrl: 'http://localhost:8000');

      final uri = client.buildUri('/api/auth/token/');

      expect(uri.toString(), 'http://localhost:8000/api/auth/token/');
    });

    test('buildUri gère les slashs correctement', () {
      final client = ApiClient(baseUrl: 'http://localhost:8000/');

      final uri = client.buildUri('api/auth/token/');

      expect(uri.toString(), 'http://localhost:8000/api/auth/token/');
    });

    test('buildUri ajoute les paramètres de requête', () {
      final client = ApiClient(baseUrl: 'http://localhost:8000');

      final uri = client.buildUri('/api/items/', {'page': '1', 'limit': '10'});

      expect(
        uri.toString(),
        'http://localhost:8000/api/items/?page=1&limit=10',
      );
    });

    test('buildUri filtre les paramètres null', () {
      final client = ApiClient(baseUrl: 'http://localhost:8000');

      final uri = client.buildUri('/api/items/', {'page': '1', 'limit': null});

      expect(uri.toString(), 'http://localhost:8000/api/items/?page=1');
    });

    test('post envoie une requête POST avec body JSON', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/auth/token/');
        expect(request.headers['Content-Type'], 'application/json');
        expect(request.body, '{"username":"admin","password":"test123"}');

        return http.Response('{"token":"abc123"}', 200);
      });

      final client = ApiClient(
        baseUrl: 'http://localhost:8000',
        client: mockClient,
      );

      final response = await client.post(
        '/api/auth/token/',
        body: {'username': 'admin', 'password': 'test123'},
      );

      expect(response.statusCode, 200);
      expect(response.body, '{"token":"abc123"}');
    });

    test('get envoie une requête GET avec headers par défaut', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/items/');
        expect(request.headers['Accept'], 'application/json');

        return http.Response('[]', 200);
      });

      final client = ApiClient(
        baseUrl: 'http://localhost:8000',
        client: mockClient,
      );

      final response = await client.get('/api/items/');

      expect(response.statusCode, 200);
      expect(response.body, '[]');
    });

    test('put envoie une requête PUT avec body JSON', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/items/1/');
        expect(request.body, '{"name":"Updated Item"}');

        return http.Response('{"id":1,"name":"Updated Item"}', 200);
      });

      final client = ApiClient(
        baseUrl: 'http://localhost:8000',
        client: mockClient,
      );

      final response = await client.put(
        '/api/items/1/',
        body: {'name': 'Updated Item'},
      );

      expect(response.statusCode, 200);
    });

    test('delete envoie une requête DELETE', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/items/1/');

        return http.Response('', 204);
      });

      final client = ApiClient(
        baseUrl: 'http://localhost:8000',
        client: mockClient,
      );

      final response = await client.delete('/api/items/1/');

      expect(response.statusCode, 204);
    });
  });
}
