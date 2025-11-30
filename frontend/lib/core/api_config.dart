// filepath: /Users/romain/Flutter/Novaville/frontend/lib/core/api_config.dart

// Expose une constante `apiBaseUrl` configurable via --dart-define=API_BASE_URL
// Usage (dev) : flutter run --dart-define=API_BASE_URL=http://localhost:8000
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);
