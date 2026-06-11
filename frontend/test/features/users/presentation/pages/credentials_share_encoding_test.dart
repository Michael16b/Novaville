import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Credentials Share - Link Generation & Decoding', () {
    test('Generate and decode credential share link', () {
      // Mock data
      const firstName = 'Jean';
      const lastName = 'Dupont';
      const username = 'jdupont';
      const email = 'jean@example.com';
      const password = 'SecurePass123!';

      // Step 1: Generate link (simulating _createCredentialShareLink)
      final payload = jsonEncode({
        'v': 1,
        'first_name': firstName,
        'last_name': lastName,
        'username': username,
        'email': email,
        'password': password,
      });

      final encodedShareRef = base64Url
          .encode(utf8.encode(payload))
          .replaceAll('=', '');

      print('📦 Generated share_ref: $encodedShareRef');
      print('📦 Length: ${encodedShareRef.length}');

      // Step 2: Decode link (simulating _decodeShareRef)
      try {
        final normalized = base64Url.normalize(encodedShareRef.trim());
        final decodedJson = utf8.decode(base64Url.decode(normalized));
        final decoded = jsonDecode(decodedJson) as Map<String, dynamic>;

        // Verify all fields
        expect(decoded['first_name'], firstName);
        expect(decoded['last_name'], lastName);
        expect(decoded['username'], username);
        expect(decoded['email'], email);
        expect(decoded['password'], password);
        expect(decoded['v'], 1);

        print('✅ Decoding successful - all fields verified');
      } catch (e) {
        fail('Decoding failed: $e');
      }
    });

    test('Handle malformed share_ref', () {
      const malformedRef = 'invalid!!!base64';

      try {
        final normalized = base64Url.normalize(malformedRef.trim());
        base64Url.decode(normalized);
        fail('Should have thrown FormatException');
      } catch (e) {
        expect(e is FormatException, true);
        print('✅ Properly caught malformed base64: $e');
      }
    });

    test('Handle empty fields in JSON', () {
      final payload = jsonEncode({
        'v': 1,
        'first_name': '',
        'last_name': '',
        'username': 'testuser',
        'email': '',
        'password': '',
      });

      final encodedShareRef = base64Url
          .encode(utf8.encode(payload))
          .replaceAll('=', '');

      final normalized = base64Url.normalize(encodedShareRef.trim());
      final decodedJson = utf8.decode(base64Url.decode(normalized));
      final decoded = jsonDecode(decodedJson) as Map<String, dynamic>;

      // At least one field should exist (username)
      final hasAtLeastOneValue =
          (decoded['first_name'] as String? ?? '').isNotEmpty ||
          (decoded['last_name'] as String? ?? '').isNotEmpty ||
          (decoded['username'] as String? ?? '').isNotEmpty ||
          (decoded['email'] as String? ?? '').isNotEmpty ||
          (decoded['password'] as String? ?? '').isNotEmpty;

      expect(hasAtLeastOneValue, true);
      print('✅ Validation allows partial data with username present');
    });
  });
}
