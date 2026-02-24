// filepath: /Users/romain/Flutter/Novaville/frontend/lib/core/api_config.dart

// Exposes a configurable `apiBaseUrl` constant via --dart-define=FLUTTER_BACKEND_API
// Usage (dev): flutter run --dart-define=FLUTTER_BACKEND_API=http://localhost:8000
// Or via docker-compose: FLUTTER_BACKEND_API=http://localhost:8000
const String apiBaseUrl = String.fromEnvironment(
  'FLUTTER_BACKEND_API',
  defaultValue: 'http://localhost:8000',
);
