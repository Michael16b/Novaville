import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend/core/api_config.dart' as api_config;

class AppConfig {
  AppConfig._();

  static String get apiBaseUrl {
    // Prefer an explicit value from the .env file, then fall back to the
    // compile-time constant injected via --dart-define=FLUTTER_BACKEND_API
    // (set to '/api' in the Docker build so that Nginx proxies to the backend).
    return dotenv.env['API_BASE_URL'] ?? api_config.apiBaseUrl;
  }

  static bool get isDebugMode {
    final debug = dotenv.env['DEBUG'];
    return debug?.toLowerCase() == 'true';
  }
}
