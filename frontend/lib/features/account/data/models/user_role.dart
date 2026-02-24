/// Enumeration of user roles in the system.
enum UserRole {
  /// Citizen
  citizen('CITIZEN', 'Citizen'),

  /// Elected official
  elected('ELECTED', 'Elected Official'),

  /// Municipal agent
  agent('AGENT', 'Municipal Agent'),

  /// Global administrator
  globalAdmin('GLOBAL_ADMIN', 'Global Administrator');

  const UserRole(this.value, this.label);

  /// Backend-side enum value.
  final String value;

  /// Display label.
  final String label;

  /// Creates a [UserRole] from the backend string value.
  static UserRole fromString(String value) {
    switch (value) {
      case 'CITIZEN':
        return UserRole.citizen;
      case 'ELECTED':
        return UserRole.elected;
      case 'AGENT':
        return UserRole.agent;
      case 'GLOBAL_ADMIN':
        return UserRole.globalAdmin;
      default:
        throw ArgumentError('Unknown role: $value');
    }
  }

  /// Converts the enum to a string for the backend.
  String toJson() => value;
}
