import 'package:csv/csv.dart';
import 'package:frontend/features/users/data/models/user_role.dart';
import 'package:frontend/constants/texts/texts_csv_drop.dart';

class UserCsvCompiler {
  const UserCsvCompiler();

  static const Set<String> _requiredHeaders = {
    'first_name',
    'last_name',
    'username',
    'email',
  };
  static const Set<String> _optionalHeaders = {'role'};
  static const Set<String> _allowedRoles = {'citizen', 'elected', 'agent'};

  UserCsvCompilationResult compileFromContent(
    String csvContent, {
    Set<String> existingUsernames = const {},
    Set<String> existingEmails = const {},
  }) {
    final normalizedInput = csvContent.replaceAll('\r\n', '\n').trim();
    if (normalizedInput.isEmpty) {
      return const UserCsvCompilationResult(
        users: <CompiledUser>[],
        errors: <CsvValidationError>[
          CsvValidationError(
            line: 1,
            column: 'file',
            message: CsvDropTexts.csvEmptyFile,
          ),
        ],
      );
    }

    final delimiter = _detectDelimiter(normalizedInput);

    try {
      final rows = CsvToListConverter(
        shouldParseNumbers: false,
        eol: '\n',
        fieldDelimiter: delimiter,
      ).convert(normalizedInput);

      if (rows.isEmpty) {
        return const UserCsvCompilationResult(
          users: <CompiledUser>[],
          errors: <CsvValidationError>[
            CsvValidationError(
              line: 1,
              column: 'file',
              message: CsvDropTexts.csvEmptyFile,
            ),
          ],
        );
      }

      return _compileRows(
        rows,
        existingUsernames: existingUsernames,
        existingEmails: existingEmails,
      );
    } catch (_) {
      return const UserCsvCompilationResult(
        users: <CompiledUser>[],
        errors: <CsvValidationError>[
          CsvValidationError(
            line: 1,
            column: 'file',
            message: CsvDropTexts.invalidOrMalformed,
          ),
        ],
      );
    }
  }

  UserCsvCompilationResult _compileRows(
    List<List<dynamic>> rows, {
    required Set<String> existingUsernames,
    required Set<String> existingEmails,
  }) {
    final errors = <CsvValidationError>[];
    final users = <CompiledUser>[];

    final rawHeaders = rows.first
        .map((cell) => _normalizeHeader(cell.toString()))
        .toList(growable: false);

    final seenHeaders = <String>{};
    for (final header in rawHeaders) {
      if (header.isEmpty) {
        continue;
      }
      if (!seenHeaders.add(header)) {
        errors.add(
          CsvValidationError(
            line: 1,
            column: header,
            message: CsvDropTexts.duplicateColumn,
          ),
        );
      }
    }

    for (final header in rawHeaders) {
      if (header.isEmpty) {
        continue;
      }
      if (!_requiredHeaders.contains(header) &&
          !_optionalHeaders.contains(header)) {
        errors.add(
          CsvValidationError(
            line: 1,
            column: header,
            message: CsvDropTexts.unknownColumn,
          ),
        );
      }
    }

    for (final requiredHeader in _requiredHeaders) {
      if (!rawHeaders.contains(requiredHeader)) {
        errors.add(
          CsvValidationError(
            line: 1,
            column: requiredHeader,
            message: CsvDropTexts.missingRequiredColumn,
          ),
        );
      }
    }

    if (errors.isNotEmpty) {
      return UserCsvCompilationResult(users: users, errors: errors);
    }

    int indexOfHeader(String key) => rawHeaders.indexOf(key);

    final firstNameIndex = indexOfHeader('first_name');
    final lastNameIndex = indexOfHeader('last_name');
    final usernameIndex = indexOfHeader('username');
    final emailIndex = indexOfHeader('email');
    final roleIndex = indexOfHeader('role');

    final usernames = existingUsernames
        .map((value) => value.trim().toLowerCase())
        .toSet();
    final emails = existingEmails
        .map((value) => value.trim().toLowerCase())
        .toSet();

    String cellAt(List<dynamic> row, int index) {
      if (index < 0 || index >= row.length) {
        return '';
      }
      return row[index].toString().trim();
    }

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      final lineNumber = i + 1;

      final firstName = cellAt(row, firstNameIndex);
      final lastName = cellAt(row, lastNameIndex);
      final username = cellAt(row, usernameIndex);
      final email = cellAt(row, emailIndex);
      final roleRaw = roleIndex >= 0 ? cellAt(row, roleIndex) : '';

      final isEmptyLine =
          firstName.isEmpty &&
          lastName.isEmpty &&
          username.isEmpty &&
          email.isEmpty &&
          roleRaw.isEmpty;
      if (isEmptyLine) {
        continue;
      }

      void addError(String column, String message) {
        errors.add(
          CsvValidationError(
            line: lineNumber,
            column: column,
            message: message,
          ),
        );
      }

      if (firstName.isEmpty) {
        addError('first_name', CsvDropTexts.missingRequiredValue);
      }
      if (lastName.isEmpty) {
        addError('last_name', CsvDropTexts.missingRequiredValue);
      }
      if (username.isEmpty) {
        addError('username', CsvDropTexts.missingRequiredValue);
      }
      if (email.isEmpty) {
        addError('email', CsvDropTexts.missingRequiredValue);
      }

      if (username.contains(RegExp(r'\s'))) {
        addError('username', CsvDropTexts.noWhitespaceAllowed);
      }

      if (email.isNotEmpty && !_isValidEmail(email)) {
        addError('email', CsvDropTexts.invalidFormat);
      }

      if (roleRaw.isNotEmpty) {
        if (roleRaw != roleRaw.toLowerCase()) {
          addError(
            'role',
            CsvDropTexts.roleLowercase,
          );
        }
        if (!_allowedRoles.contains(roleRaw.toLowerCase())) {
          addError(
            'role',
            CsvDropTexts.invalidRoleValue,
          );
        }
      }

      final normalizedUsername = username.toLowerCase();
      final normalizedEmail = email.toLowerCase();

      if (username.isNotEmpty && usernames.contains(normalizedUsername)) {
        addError('username', CsvDropTexts.duplicateDetected);
      }
      if (email.isNotEmpty && emails.contains(normalizedEmail)) {
        addError('email', CsvDropTexts.duplicateDetected);
      }

      if (errors.any((error) => error.line == lineNumber)) {
        continue;
      }

      usernames.add(normalizedUsername);
      emails.add(normalizedEmail);

      users.add(
        CompiledUser(
          firstName: firstName,
          lastName: lastName,
          username: username,
          email: email,
          role: _parseRole(roleRaw),
        ),
      );
    }

    return UserCsvCompilationResult(users: users, errors: errors);
  }

  String _detectDelimiter(String csvContent) {
    final firstLine = csvContent
        .split('\n')
        .map((line) => line.trim())
        .firstWhere((line) => line.isNotEmpty, orElse: () => '');

    final commaCount = ','.allMatches(firstLine).length;
    final semicolonCount = ';'.allMatches(firstLine).length;
    final tabCount = '\t'.allMatches(firstLine).length;

    if (semicolonCount > commaCount && semicolonCount >= tabCount) {
      return ';';
    }
    if (tabCount > commaCount && tabCount > semicolonCount) {
      return '\t';
    }
    return ',';
  }

  String _normalizeHeader(String value) {
    final withNoBom = value.replaceFirst('\uFEFF', '');
    return withNoBom.trim().toLowerCase();
  }

  bool _isValidEmail(String value) {
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailPattern.hasMatch(value);
  }

  UserRole _parseRole(String raw) {
    final role = raw.trim().toLowerCase();
    if (role == 'agent') {
      return UserRole.agent;
    }
    if (role == 'elected') {
      return UserRole.elected;
    }
    return UserRole.citizen;
  }
}

class UserCsvCompilationResult {
  const UserCsvCompilationResult({required this.users, required this.errors});

  final List<CompiledUser> users;
  final List<CsvValidationError> errors;
}

class CsvValidationError {
  const CsvValidationError({
    required this.line,
    required this.column,
    required this.message,
  });

  final int line;
  final String column;
  final String message;
}

class CompiledUser {
  const CompiledUser({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.role,
  });

  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final UserRole role;
}
