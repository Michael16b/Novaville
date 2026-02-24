import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/account/data/user_repository_impl.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('UserRepositoryImpl', () {
    const baseUrl = 'http://localhost:8000';

    const userJson = '''
{
  "id": 1,
  "username": "jdoe",
  "email": "john.doe@example.com",
  "first_name": "John",
  "last_name": "Doe"
}
''';

    test('getCurrentUser retourne un User en cas de succès (200)', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/users/me/');
        return http.Response(userJson, 200);
      });

      final repo = UserRepositoryImpl(
        apiClient: ApiClient(baseUrl: baseUrl, client: mockClient),
      );

      final user = await repo.getCurrentUser();

      expect(user.id, 1);
      expect(user.username, 'jdoe');
      expect(user.email, 'john.doe@example.com');
      expect(user.firstName, 'John');
      expect(user.lastName, 'Doe');
    });

    test('getCurrentUser lance une exception en cas d\'erreur (401)', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"detail":"Non authentifié"}', 401);
      });

      final repo = UserRepositoryImpl(
        apiClient: ApiClient(baseUrl: baseUrl, client: mockClient),
      );

      expect(
        () => repo.getCurrentUser(),
        throwsA(isA<Exception>()),
      );
    });

    test('updateUser envoie PATCH avec les bons champs et retourne l\'utilisateur mis à jour', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/api/v1/users/1/');
        expect(request.headers['Content-Type'], contains('application/json'));

        // Vérifier que le body contient les bons champs
        expect(request.body, contains('"first_name":"Jane"'));
        expect(request.body, contains('"email":"jane.doe@example.com"'));

        const updatedJson = '''
{
  "id": 1,
  "username": "jdoe",
  "email": "jane.doe@example.com",
  "first_name": "Jane",
  "last_name": "Doe"
}
''';
        return http.Response(updatedJson, 200);
      });

      final repo = UserRepositoryImpl(
        apiClient: ApiClient(baseUrl: baseUrl, client: mockClient),
      );

      final user = await repo.updateUser(
        userId: 1,
        firstName: 'Jane',
        email: 'jane.doe@example.com',
      );

      expect(user.id, 1);
      expect(user.firstName, 'Jane');
      expect(user.email, 'jane.doe@example.com');
    });

    test('updateUser n\'envoie que les champs non nuls', () async {
      final mockClient = MockClient((request) async {
        // Seul le username doit être dans le body
        expect(request.body, contains('"username":"newuser"'));
        expect(request.body, isNot(contains('first_name')));
        expect(request.body, isNot(contains('last_name')));
        expect(request.body, isNot(contains('email')));

        return http.Response(userJson, 200);
      });

      final repo = UserRepositoryImpl(
        apiClient: ApiClient(baseUrl: baseUrl, client: mockClient),
      );

      await repo.updateUser(userId: 1, username: 'newuser');
    });

    test('updateUser lance une exception en cas d\'erreur (400)', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"email":["Ce champ est invalide."]}', 400);
      });

      final repo = UserRepositoryImpl(
        apiClient: ApiClient(baseUrl: baseUrl, client: mockClient),
      );

      expect(
        () => repo.updateUser(userId: 1, email: 'invalid'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
