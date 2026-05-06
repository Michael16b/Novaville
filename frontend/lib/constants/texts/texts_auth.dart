/// Text constants related to authentication (login, logout, token errors).
class AppTextsAuth {
  AppTextsAuth._();

  static const String login = 'Se connecter';
  static const String register = "S'inscrire";
  static const String registerDescription =
      "Renseignez vos informations. Votre compte restera bloque tant qu'un administrateur n'aura pas valide la demande.";
  static const String registerInviteDescription =
      'Vos informations sont deja pré-remplies. Choisissez simplement votre mot de passe pour activer votre compte.';
  static const String registerInviteTitle = 'Bienvenue';
  static const String completePasswordSetup = 'Choisir mon mot de passe';
  static const String backToHome = "Retour a l'accueil";
  static const String logout = 'Se déconnecter';
  static const String genericConnectionError = 'Erreur de connexion';
  static const String invalidCredentials =
      "Le nom d'utilisateur ou le mot de passe est incorrect";
  static const String usernameOrEmail = "Email ou nom d'utilisateur";
  static const String pendingApproval =
      "Votre demande d'inscription est en attente de validation par un administrateur.";
  static const String accountDisabled =
      'Votre compte est desactive. Veuillez contacter un administrateur.';
  static const String tokenRefreshFailed = 'Impossible de rafraîchir le token';
  static const String serverInvalidResponse = 'Réponse invalide du serveur';
  static const String emptyEmailOrPassword =
      "L'email ou le mot de passe est vide";
  static const String emptyUsernameOrPassword =
      "Le nom d'utilisateur ou le mot de passe est vide";

  static const String firstConnectionButton =
      '1ère connexion (Activer mon compte)';
  static const String pdfFirstConnectionNote =
      'Important : Votre mot de passe sera à définir lors de votre 1ère connexion.';
  static const String pdfActivationCode =
      'Code d\'activation (mot de passe temporaire) : ';

  static String pdfAlternativeInstructions(String url) =>
      'Allez sur la page :\n$url\n\n--- OU ---\n\nAllez sur l\'application puis le bouton "Se connecter"\npuis "$firstConnectionButton"\net entrez les informations du pdf.';

  // Set Password Screen / Activation
  static const String activationCodeRequired =
      "Le code d'activation ou mot de passe temporaire est requis.";
  static const String invalidOrExpiredLink =
      "Le lien est invalide ou le mot de passe temporaire a expiré.";
  static String passwordChangeError(int code) =>
      "Erreur lors du changement de mot de passe ($code)";
  static const String passwordSetupSuccess =
      "Mot de passe configuré avec succès !";
  static String errorPrefix(String error) => "Erreur : $error";

  static const String fullName = "Nom complet";
  static const String usernameLabel = "Nom d'utilisateur";
  static const String usernameHint = "Saisissez votre identifiant";
  static const String usernameRequired = "L'identifiant est requis";
  static const String emailLabel = "Adresse e-mail";
  static const String activationCodeLabel =
      "Code d'activation (mot de passe reçu)";
  static const String newPasswordLabel = "Nouveau mot de passe";
  static const String passwordTooShort =
      "Le mot de passe doit contenir au moins 8 caractères";
  static const String passwordEntirelyNumeric =
      "Le mot de passe ne peut pas être entièrement numérique";
  static const String confirmPasswordLabel = "Confirmer le mot de passe";
  static const String confirmPasswordRequired =
      "Veuillez confirmer le mot de passe";
  static const String passwordsDoNotMatch =
      "Les mots de passe ne correspondent pas";
  static const String setPasswordTitle = "Configurer mon mot de passe";
  static const String setPasswordDescription =
      "Vérifiez vos informations et choisissez un nouveau mot de passe pour sécuriser votre compte.";
  static const String creationInProgress = "Création en cours...";
  static const String validateAndCreateAccount = "Valider et créer mon compte";

  // Admin Password Reset
  static const String adminResetPasswordTitle = "Réinitialiser le mot de passe";
  static const String adminResetPasswordConfirm =
      "Êtes-vous sûr de vouloir réinitialiser le mot de passe de cet utilisateur ? Un nouveau mot de passe temporaire sera généré et vous pourrez le partager via PDF.";
  static const String adminResetPasswordSuccess =
      "Réinitialisation effectuée avec succès.";
}
