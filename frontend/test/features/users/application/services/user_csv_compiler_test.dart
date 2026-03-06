import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/users/application/services/user_csv_compiler.dart';
import 'package:frontend/features/users/data/models/user_role.dart';

void main() {
  const compiler = UserCsvCompiler();

  group('UserCsvCompiler', () {
    test('returns error when required header is missing', () {
      const content =
          'first_name,last_name,username,role\n'
          'Jean,Dupont,jdupont,citizen\n';

      final result = compiler.compileFromContent(content);

      expect(result.users, isEmpty);
      expect(
        result.errors.any(
          (error) =>
              error.line == 1 &&
              error.column == 'email' &&
              error.message == 'Colonne obligatoire manquante',
        ),
        isTrue,
      );
    });

    test('returns errors when first line is data and not headers', () {
      const content =
          'Jean,Dupont,jdupont,jean.dupont@novaville.fr,citizen\n'
          'Alice,Martin,amartin,alice.martin@novaville.fr,agent\n';

      final result = compiler.compileFromContent(content);

      expect(result.users, isEmpty);
      expect(
        result.errors.any(
          (error) =>
              error.line == 1 &&
              error.column == 'first_name' &&
              error.message == 'Colonne obligatoire manquante',
        ),
        isTrue,
      );
      expect(
        result.errors.any(
          (error) =>
              error.line == 1 &&
              error.column == 'jean' &&
              error.message == 'Colonne non reconnue',
        ),
        isTrue,
      );
    });

    test('supports semicolon-separated CSV', () {
      const content =
          'first_name;last_name;username;email;role\n'
          'Jean;Dupont;jdupont;jean.dupont@novaville.fr;agent\n';

      final result = compiler.compileFromContent(content);

      expect(result.errors, isEmpty);
      expect(result.users, hasLength(1));
      expect(result.users.first.username, 'jdupont');
      expect(result.users.first.role, UserRole.agent);
    });

    test('rejects uppercase role values', () {
      const content =
          'first_name,last_name,username,email,role\n'
          'Jean,Dupont,jdupont,jean.dupont@novaville.fr,Agent\n';

      final result = compiler.compileFromContent(content);

      expect(result.users, isEmpty);
      expect(
        result.errors.any(
          (error) =>
              error.line == 2 &&
              error.column == 'role' &&
              error.message.contains('minuscule'),
        ),
        isTrue,
      );
    });

    test('rejects invalid role values', () {
      const content =
          'first_name,last_name,username,email,role\n'
          'Jean,Dupont,jdupont,jean.dupont@novaville.fr,global_admin\n';

      final result = compiler.compileFromContent(content);

      expect(result.users, isEmpty);
      expect(
        result.errors.any(
          (error) =>
              error.line == 2 &&
              error.column == 'role' &&
              error.message.contains('Valeur invalide'),
        ),
        isTrue,
      );
    });

    test('rejects duplicates against existing users', () {
      const content =
          'first_name,last_name,username,email,role\n'
          'Jean,Dupont,jdupont,jean.dupont@novaville.fr,citizen\n';

      final result = compiler.compileFromContent(
        content,
        existingUsernames: {'jdupont'},
        existingEmails: {'jean.dupont@novaville.fr'},
      );

      expect(result.users, isEmpty);
      expect(result.errors.where((error) => error.line == 2), hasLength(2));
    });

    test('rejects duplicates inside the same file', () {
      const content =
          'first_name,last_name,username,email,role\n'
          'Jean,Dupont,jdupont,jean.dupont@novaville.fr,citizen\n'
          'Alice,Martin,jdupont,alice.martin@novaville.fr,agent\n'
          'Paul,Durand,pdurand,jean.dupont@novaville.fr,elected\n';

      final result = compiler.compileFromContent(content);

      expect(result.users, hasLength(1));
      expect(
        result.errors.any(
          (error) => error.line == 3 && error.column == 'username',
        ),
        isTrue,
      );
      expect(
        result.errors.any(
          (error) => error.line == 4 && error.column == 'email',
        ),
        isTrue,
      );
    });

    test('supports UTF-8 BOM in header row', () {
      const content =
          '\uFEFFfirst_name,last_name,username,email,role\n'
          'Jean,Dupont,jdupont,jean.dupont@novaville.fr,citizen\n';

      final result = compiler.compileFromContent(content);

      expect(result.errors, isEmpty);
      expect(result.users, hasLength(1));
    });

    test('returns empty-file error', () {
      const content = '   \n  \n';

      final result = compiler.compileFromContent(content);

      expect(result.users, isEmpty);
      expect(result.errors, hasLength(1));
      expect(result.errors.first.column, 'file');
    });
  });
}
