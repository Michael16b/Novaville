/// Énumération des rôles utilisateur dans le système
enum UserRole {
  /// Citoyen
  citizen('CITIZEN', 'Citizen'),

  /// Élu
  elected('ELECTED', 'Elected Official'),

  /// Agent municipal
  agent('AGENT', 'Municipal Agent'),

  /// Administrateur global
  globalAdmin('GLOBAL_ADMIN', 'Global Administrator');

  const UserRole(this.value, this.label);

  /// Valeur de l'enum côté backend
  final String value;

  /// Label d'affichage
  final String label;

  /// Crée un UserRole à partir de la valeur string du backend
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

  /// Convertit l'enum en string pour le backend
  String toJson() => value;
}

