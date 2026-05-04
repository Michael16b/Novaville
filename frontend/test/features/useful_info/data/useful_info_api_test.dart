import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/useful_info/data/useful_info_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('UsefulInfoApi', () {
    test('uses the trailing slash expected by the Django route', () async {
      late Uri requestedUrl;
      final api = UsefulInfoApi(
        client: MockClient((request) async {
          requestedUrl = request.url;
          return http.Response(
            '{"city_hall_name":"Mairie","address_line1":"1 rue de la Mairie","postal_code":"75000","city":"Novaville","opening_hours":{}}',
            200,
          );
        }),
        baseUrl: 'http://localhost:8000',
      );

      await api.fetchUsefulInfo();

      expect(requestedUrl.path, '/api/v1/useful-info/');
    });

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
