import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('credentials share payload omits password and remains decodable', () {
    final payload = jsonEncode({
      'v': 1,
      'first_name': 'Jean',
      'last_name': 'Dupont',
      'username': 'jdupont',
      'email': 'jean@example.com',
    });

    final encodedShareRef = base64Url
        .encode(utf8.encode(payload))
        .replaceAll('=', '');
    final normalized = base64Url.normalize(encodedShareRef);
    final decodedJson = utf8.decode(base64Url.decode(normalized));
    final decoded = jsonDecode(decodedJson) as Map<String, dynamic>;

    expect(decoded['first_name'], 'Jean');
    expect(decoded['last_name'], 'Dupont');
    expect(decoded['username'], 'jdupont');
    expect(decoded['email'], 'jean@example.com');
    expect(decoded.containsKey('password'), isFalse);
  });

  test('register uri keeps prefilled identity parameters', () {
    final registerUri = Uri(
      path: '/register',
      queryParameters: {
        'first_name': 'Jean',
        'last_name': 'Dupont',
        'username': 'jdupont',
        'email': 'jean@example.com',
      },
    );

    expect(registerUri.path, '/register');
    expect(registerUri.queryParameters['first_name'], 'Jean');
    expect(registerUri.queryParameters['last_name'], 'Dupont');
    expect(registerUri.queryParameters['username'], 'jdupont');
    expect(registerUri.queryParameters['email'], 'jean@example.com');
  });

  test('hash routing style credentials link keeps share_ref query intact', () {
    const shareRef = 'eyJ2IjoxLCJmaXJzdF9uYW1lIjoiSmVhbiJ9';
    final link = Uri.parse(
      'http://localhost/#/credentials-share?share_ref=$shareRef',
    );
    final queryIndex = link.fragment.indexOf('?');
    final fragmentQuery = link.fragment.substring(queryIndex + 1);
    final parsed = Uri.splitQueryString(fragmentQuery);

    expect(parsed['share_ref'], shareRef);
  });
}
