import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/users/data/user_repository_impl.dart';
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

    test('getCurrentUser returns a User on success (200)', () async {
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

    test('getCurrentUser throws an exception on error (401)', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"detail":"Unauthorized"}', 401);
      });

      final repo = UserRepositoryImpl(
        apiClient: ApiClient(baseUrl: baseUrl, client: mockClient),
      );

      expect(
        () => repo.getCurrentUser(),
        throwsA(isA<Exception>()),
      );
    });

    test('updateUser sends PATCH with the correct fields and returns the updated user', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/api/v1/users/1/');
        expect(request.headers['Content-Type'], contains('application/json'));

        // Verify the body contains the correct fields
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

    test('updateUser only sends non-null fields', () async {
      final mockClient = MockClient((request) async {
        // Only username should be in the body
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

    test('updateUser throws an exception on error (400)', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"email":["This field is invalid."]}', 400);
      });

      final repo = UserRepositoryImpl(
        apiClient: ApiClient(baseUrl: baseUrl, client: mockClient),
      );

      expect(
        () => repo.updateUser(userId: 1, email: 'invalid'),
        throwsA(isA<Exception>()),
      );
    });

    test('updatePassword envoie les bons paramètres et réussit (200)', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, anyOf(['POST', 'PATCH', 'PUT']));
        expect(request.url.path, '/api/v1/users/1/change_password/');
        expect(request.headers['Content-Type'], contains('application/json'));
        expect(request.body, contains('"current_password":"oldpass"'));
        expect(request.body, contains('"new_password":"newpass"'));
        return http.Response('{}', 200);
      });

      final repo = UserRepositoryImpl(
        apiClient: ApiClient(baseUrl: baseUrl, client: mockClient),
      );

      await repo.updatePassword(
        userId: 1,
        currentPassword: 'oldpass',
        newPassword: 'newpass',
      );
    });

    test('updatePassword échoue si le mot de passe actuel est incorrect (400)', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"current_password":["Incorrect password."]}', 400);
      });

      final repo = UserRepositoryImpl(
        apiClient: ApiClient(baseUrl: baseUrl, client: mockClient),
      );

      expect(
        () => repo.updatePassword(
          userId: 1,
          currentPassword: 'wrongpass',
          newPassword: 'newpass',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
