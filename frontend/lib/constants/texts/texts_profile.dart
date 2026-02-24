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

  // Validation messages specific to profile fields
  static const String firstNameRequired = 'Le prénom est obligatoire';
  static const String lastNameRequired = 'Le nom est obligatoire';
  static const String usernameRequired = "Le nom d'utilisateur est obligatoire";
  static const String emailRequired = "L'email est obligatoire";
  static const String emailInvalid = 'Email invalide';
}
