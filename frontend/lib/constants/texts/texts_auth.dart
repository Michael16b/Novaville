/// Text constants related to authentication (login, logout, token errors).
class AppTextsAuth {
  AppTextsAuth._();

  static const String login = 'Se connecter';
  static const String register = "S'inscrire";
  static const String registerDescription =
      "Renseignez vos informations. Votre compte restera bloque tant qu'un administrateur n'aura pas valide la demande.";
  static const String registerInviteDescription =
      'Vos informations sont deja pre-remplies. Choisissez simplement votre mot de passe pour activer votre compte.';
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
}
