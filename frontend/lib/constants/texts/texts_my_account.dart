/// Text constants related to the user profile page.
class AppTextsProfile {
  AppTextsProfile._();

  static const String myProfile = 'Mon profil';
  static const String personalInformation = 'Informations personnelles';
  static const String connectionInformation = 'Informations de connexion';
  static const String firstName = 'Prénom';
  static const String lastName = 'Nom';
  static const String username = "Nom d'utilisateur";
  static const String email = 'Email';
  static const String profileUpdateSuccess = 'Profil mis à jour avec succès';
  static const String profileUpdateError = 'Erreur lors de la mise à jour du profil';
  static const String loadingProfile = 'Chargement du profil...';
  static const String noUser = 'Aucun utilisateur trouvé';

  // HTTP error messages
  static const String fetchProfileError = 'Erreur lors de la récupération du profil';
  static const String updateProfileError = 'Erreur lors de la mise à jour du profil';
  static const String updatePasswordError = 'Erreur lors de la mise à jour du mot de passe';

  // Validation messages specific to profile fields
  static const String firstNameRequired = 'Le prénom est obligatoire';
  static const String lastNameRequired = 'Le nom est obligatoire';
  static const String usernameRequired = "Le nom d'utilisateur est obligatoire";
  static const String emailRequired = "L'email est obligatoire";
  static const String emailInvalid = 'Email invalide';

// Password change texts
  static const String changePassword = 'Changer le mot de passe';
  static const String currentPassword = 'Mot de passe actuel';
  static const String newPassword = 'Nouveau mot de passe';
  static const String confirmNewPassword = 'Confirmer le nouveau mot de passe';

  static const String passwordUpdateSuccess =
      'Mot de passe mis à jour avec succès.';

  static const String passwordRequired =
      'Le mot de passe est obligatoire.';

  static const String passwordsDoNotMatch =
      'Les mots de passe ne correspondent pas.';

  static const String passwordTooWeak =
      'Le mot de passe doit contenir au moins 8 caractères, une majuscule, une minuscule, un chiffre et un caractère spécial.';

  static const String passwordFieldsRequired =
      'Veuillez remplir tous les champs.';

  static const String passwordIncorrect =
      'Le mot de passe actuel est incorrect.';

  static const String passwordValidationFailed =
      'Le mot de passe ne respecte pas les règles de sécurité.';

  static const String passwordForbidden =
      'Vous n’êtes pas autorisé à modifier ce mot de passe.';

  static const String passwordUpdateError =
      'Une erreur est survenue lors de la mise à jour du mot de passe.';
}
