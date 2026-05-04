import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/useful_info/data/useful_info_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('UsefulInfoApi', () {
    test('throws a detailed exception when update returns 400', () async {
      final api = UsefulInfoApi(
        client: MockClient(
          (_) async => http.Response(
            '{"opening_hours":["Hours must be a dictionary"]}',
            400,
          ),
        ),
        baseUrl: 'http://localhost:8000',
      );

      expect(
        () => api.updateUsefulInfo(const {}),
        throwsA(
          isA<UsefulInfoApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having(
                (e) => e.message,
                'message',
                contains('Erreur mise à jour useful info (400)'),
              )
              .having((e) => e.message, 'message', contains('opening_hours')),
        ),
      );
    });
  });
}
