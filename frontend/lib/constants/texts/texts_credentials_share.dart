class CredentialsShareTexts {
  static const pageTitle = 'Vos accès Novaville';
  static const subtitle =
      'Conservez ces informations de connexion en lieu sûr.';

  static const emailLabel = 'Email';
  static const usernameLabel = 'Nom d\'utilisateur';
  static const passwordLabel = 'Mot de passe';

  static const copyTooltip = 'Copier';
  static const copyAllLabel = 'Copier toutes les informations';
  static const loading = 'Chargement des informations...';
  static const unavailableTitle = 'Informations indisponibles';
  static const unavailableMessage =
      'Ce lien de partage est invalide, expiré ou déjà supprimé.';

  static const emailCopied = 'Email copié.';
  static const usernameCopied = 'Nom d\'utilisateur copié.';
  static const passwordCopied = 'Mot de passe copié.';
  static const allCopied = 'Identifiants complets copiés.';

  static String allCredentialsText({
    required String fullName,
    required String email,
    required String username,
    required String password,
  }) {
    return 'Nom: $fullName\nEmail: $email\nNom d\'utilisateur: $username\nMot de passe: $password';
  }
}
