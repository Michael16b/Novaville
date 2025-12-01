import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();
  static const _defaultBaseUrl = 'http://localhost:8000';

  static String get apiBaseUrl {
    return dotenv.env['API_BASE_URL'] ?? _defaultBaseUrl;
  }

  static bool get isDebugMode {
    final debug = dotenv.env['DEBUG'];
    return debug?.toLowerCase() == 'true';
  }
}
