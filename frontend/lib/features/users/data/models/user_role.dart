/// Enumeration of user roles in the system.
enum UserRole {
  /// Citoyen
  citizen('CITIZEN', 'Citoyen'),

  /// Élu
  elected('ELECTED', 'Élu'),

  /// Agent municipal
  agent('AGENT', 'Agent municipal'),

  /// Administrateur global
  globalAdmin('GLOBAL_ADMIN', 'Administrateur global');

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
