/// Validation error messages shown below form fields.
class AppValidatorMessages {
  AppValidatorMessages._();

  static const String firstNameRequired = 'Le prenom est obligatoire';
  static const String lastNameRequired = 'Le nom est obligatoire';
  static const String addressRequired = "L'adresse est obligatoire";
  static const String emailRequired = "L'email est obligatoire";
  static const String emailInvalid = "L'email est invalide";
  static const String loginRequired = 'Le login est obligatoire';
  static const String loginInvalidWhitespace =
      'Le login ne doit pas contenir d espace';
  static const String confirmPasswordRequired =
      'La confirmation est obligatoire';
  static const String passwordMismatch =
      'Les mots de passe ne correspondent pas';
  static const String passwordMinLength =
      'Le mot de passe doit contenir au moins 8 caracteres';
  static const String usernameRequired = "Le nom d'utilisateur est obligatoire";
  static const String passwordRequired = 'Le mot de passe est obligatoire';
}
