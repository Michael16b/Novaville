/// Text constants for surveys.
class SurveysTexts {
  SurveysTexts._();

  /// Page title.
  static const title = 'Sondages';
  static const titleDescription =
      'Consultez les sondages citoyens, votez en un clic et suivez les résultats.';

  static const createSurvey = 'Créer un sondage';
  static const editSurvey = 'Modifier le sondage';
  static const deleteSurvey = 'Supprimer le sondage';
  static const deleteConfirmTitle = 'Supprimer ce sondage ?';
  static const deleteConfirmBody =
      'Cette action est irréversible. Le sondage et ses votes seront supprimés.';
  static const createSuccess = 'Sondage créé avec succès';
  static const updateSuccess = 'Sondage modifié avec succès';
  static const deleteSuccess = 'Sondage supprimé avec succès';
  static const voteSuccess = 'Vote enregistré';
  static const loginRequiredToVote = 'Connectez-vous pour voter.';
  static const noSurveys = 'Aucun sondage';
  static const noSurveysFound =
      'Aucun sondage ne correspond aux filtres sélectionnés.';
  static const loadError = 'Impossible de charger les sondages.';
  static const genericError = 'Une erreur est survenue avec les sondages.';

  static const searchAddress = 'Filtrer par adresse exacte';
  static const searchAddressHint = 'Ex: 12 Rue de la Paix, Novaville';
  static const applyFilters = 'Filtrer';
  static const clearFilters = 'Réinitialiser les filtres';
  static const advancedFilters = 'Filtres avancés';
  static const filterByCitizenType = 'Type de citoyen';
  static const allCitizenTypes = 'Tous';
  static const cardsPerRow = 'Cartes par ligne';
  static const auto = 'Auto';
  static const sortBy = 'Trier par';
  static const sortByDate = 'Date de création';
  static const ascending = 'Croissant';
  static const descending = 'Décroissant';

  static const questionLabel = 'Question';
  static const questionRequired = 'La question est obligatoire.';
  static const questionHint =
      'Ex: Souhaitez-vous plus de bancs dans ce quartier ?';

  static const addressLabel = 'Adresse exacte';
  static const addressRequired = "L'adresse est obligatoire.";

  static const targetLabel = 'Type de citoyen cible';
  static const targetAll = 'Tous les citoyens';

  static const optionsLabel = 'Réponses possibles';
  static const optionLabel = 'Réponse';
  static const optionRequired = 'La réponse ne peut pas être vide.';
  static const minOptions = 'Ajoutez au moins 2 réponses.';
  static const addOption = 'Ajouter une réponse';

  static const descriptionLabel = 'Description';

  /// Validation message for the survey description field.
  static const descriptionRequired = 'La description est obligatoire.';
  static const vote = 'Voter';
  static const totalVotes = 'votes';
  static const targetedAudience = 'Cible';
  static const createdBy = 'Créé par';
}
