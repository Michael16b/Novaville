class BulkUserCreationTexts {
  static String restoredFromCache(int count) =>
      '$count utilisateur(s) restauré(s) depuis le cache local.';

  static const clearPendingTitle = 'Supprimer la liste en attente';
  static const clearPendingMessage =
      'Voulez-vous supprimer tous les utilisateurs en attente de création ?';

  static const userAddedToList = 'Utilisateur ajouté à la liste.';
  static const userUpdated = 'Utilisateur modifié.';
  static const firstNameMissing = 'first_name manquant';
  static const lastNameMissing = 'last_name manquant';
  static const usernameMissing = 'username manquant';
  static const emailMissing = 'email manquant';
  static const emailInvalid = 'Email invalide';
  static const usernameInvalidWhitespace =
      'username invalide (espaces interdits)';
  static const usernameAlreadyUsed = 'username déjà utilisé';
  static const emailAlreadyUsed = 'email déjà utilisé';

  static const unreadableCsvFile = 'Fichier CSV illisible';
  static String csvCompilationFailed(int count) =>
      'Compilation CSV échouée ($count erreur(s)).';
  static String csvImported(String sourceLabel, int count) =>
      '$sourceLabel: $count utilisateur(s) importé(s).';
  static const csvOnlyDrop = 'Déposez un fichier .csv uniquement.';
  static const csvEmptyFile = 'Le fichier CSV est vide.';
  static const csvDropReadFailed = 'Lecture du fichier déposé impossible.';
  static String csvCompilationDialogTitle(int count) =>
      'Compilation CSV échouée ($count)';
  static const csvCompilationDialogMessage =
      'Le fichier contient des erreurs. Corrigez-les puis relancez l\'import.';
  static String csvLineAndColumn(int line, String column) =>
      'Ligne $line • Colonne $column';

  static const addAtLeastOneUser = 'Ajoutez au moins un utilisateur.';
  static const finalValidationTitle = 'Validation finale';
  static String finalValidationMessage(int count) =>
      'Créer définitivement $count utilisateur(s) ? Cette action enverra la liste au serveur.';
  static const create = 'Créer';
  static String createdWithSuccess(int count) =>
      '$count utilisateur(s) créé(s) avec succès.';
  static String creationFailures(int count) =>
      '$count échec(s). Consultez le détail.';
  static const creationErrorsTitle = 'Erreurs de création';

  static const backTooltip = 'Retour';
  static const pageTitle = 'Création multiple d\'utilisateurs';
  static const pageSubtitle =
      'Préparez vos utilisateurs en saisie manuelle ou via CSV, puis validez la création finale.';
  static String pendingListCount(int count) =>
      'Liste en attente: $count utilisateur(s)';
  static const reset = 'Réinitialiser';
  static const manualInput = 'Saisie manuelle';
  static const csvImport = 'Import CSV';
  static const creatingInProgress = 'Création en cours...';
  static String validateAndCreate(int count) =>
      'Valider et créer $count utilisateur(s)';

  static const manualSectionTitle = 'Saisie manuelle';
  static const newUserTitle = 'Nouvel utilisateur';
  static const addCard = 'Ajouter la carte';
  static const roleLabel = 'Rôle';
  static const firstNameLabel = 'Prénom';
  static const lastNameLabel = 'Nom';
  static const usernameLabel = 'Nom d\'utilisateur';
  static const emailLabel = 'Email';
  static const randomUsernameTooltip = 'Proposer un identifiant aléatoire';

  static const csvDropHere = 'Glissez-déposez votre fichier CSV ici';
  static const or = 'ou';
  static const selectFile = 'Sélectionner un fichier';
  static const importCsvTitle = 'Importer un fichier CSV';
  static const downloadCsvExample = 'TÉLÉCHARGER UN FICHIER D\'EXEMPLE';
  static const pendingUsersTitle = 'Utilisateurs en attente';
  static const noPendingUsers = 'Aucun utilisateur en attente.';
  static String editUserTitle(int number) => 'Modification utilisateur $number';
  static const noCreatedUsersToExport = 'Aucun utilisateur créé à exporter.';
  static const linkCopied = 'Lien copié dans le presse-papiers.';
  static const linkGenerationFailed = 'Génération du lien impossible.';
  static const shareUnavailable =
      'Informations de partage introuvables pour ce lien.';

  static const pdfDownloaded = 'PDF téléchargé.';
  static const pdfDownloadError = 'Téléchargement du PDF impossible.';

  static const pdfFileBaseName = 'NovavilleIdentifiant';
  static const groupedPdfSuffix = '_Groupe';
  static const individualPdfSuffix = '_Individuel';
  static const oneUserPdfSuffix = '_Utilisateur';

  static const groupedPdfTitle = 'Novaville - Identifiants groupés';
  static const groupedPdfSubtitle =
      'Document confidentiel - diffusion contrôlée';
  static const includeIndividualPdfOption =
      'Inclure aussi le PDF 1 utilisateur/page';
  static const gridModeLabel = 'Grille';
  static const gridModeAuto = 'Auto';
  static const gridModeManual = 'Manuel';
  static const oneUserPageButton = 'PDF 1 utilisateur/page';
  static const groupedPdfButton = 'PDF groupé';
  static const userPdfButton = 'PDF utilisateur';
  static const copyLinkTooltip = 'Copier le lien';
  static const downloadUserPdfTooltip = 'Télécharger le PDF utilisateur';
  static const shareReferenceKey = 'share_ref';
  static const credentialsSectionTitle =
      'Comptes créés et diffusion des identifiants';
  static const columnsLabel = 'Colonnes';
  static const rowsLabel = 'Lignes';

  static const pdfBrand = 'Novaville';
  static const pdfEmailLabel = 'Email';
  static const pdfUsernameLabel = 'Nom d\'utilisateur';
  static const pdfPasswordLabel = 'Mot de passe';

  static const shareTokenPrefix = 'bulk_share_credential_';
}
