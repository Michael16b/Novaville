import 'package:frontend/constants/texts/texts_general.dart';

/// Text constants for the participatory agenda feature.
/// Variable names are in English, values in French.
class AgendaTexts {
  AgendaTexts._();

  /// Page title.
  static const title = 'Agenda participatif';

  /// Page description.
  static String get titleDescription =>
      'Découvrez et participez aux événements de '
      '${AppTextsGeneral.appName}';

  /// Create event action label.
  static const createEvent = 'Créer un événement';

  /// Edit event action label.
  static const editEvent = 'Modifier l\'événement';

  /// Delete event action label.
  static const deleteEvent = 'Supprimer l\'événement';

  /// Title form field label.
  static const titleLabel = 'Titre';

  /// Description form field label.
  static const descriptionLabel = 'Description';

  /// Start date form field label.
  static const startDateLabel = 'Date de début';

  /// End date form field label.
  static const endDateLabel = 'Date de fin';

  /// Theme form field label.
  static const themeLabel = 'Thématique';

  /// Theme placeholder.
  static const selectTheme = 'Sélectionnez une thématique';

  /// Description hint.
  static const descriptionHint = 'Décrivez l\'événement...';

  /// Title hint.
  static const titleHint = 'Nom de l\'événement';

  /// Search field label.
  static const search = 'Rechercher';

  /// Search field hint.
  static const searchHint = 'Titre, description...';

  /// Sort by label.
  static const sortBy = 'Trier par';

  /// Sort by date label.
  static const sortByDate = 'Date';

  /// Ascending order label.
  static const ascending = 'Croissant';

  /// Descending order label.
  static const descending = 'Décroissant';

  /// Cards per row label.
  static const cardsPerRow = 'Cartes par ligne';

  /// Automatic option.
  static const auto = 'Automatique';

  /// Advanced filters label.
  static const advancedFilters = 'Filtres';

  /// Clear filters label.
  static const clearFilters = 'Réinitialiser';

  /// Filter by theme label.
  static const filterByTheme = 'Thématique';

  /// Filter by date label.
  static const filterByDate = 'Période';

  /// All themes label.
  static const allThemes = 'Toutes';

  /// All dates label.
  static const allDates = 'Toutes les dates';

  /// Today label.
  static const today = 'Aujourd\'hui';

  /// Next 7 days label.
  static const next7Days = '7 prochains jours';

  /// Next 30 days label.
  static const next30Days = '30 prochains jours';

  /// Pagination "of" label.
  static const on = 'sur';

  /// Generic error message.
  static const error = 'Une erreur est survenue';

  /// Create success message.
  static const createSuccess = 'Événement créé avec succès';

  /// Delete success message.
  static const deleteSuccess = 'Événement supprimé avec succès';

  /// Update success message.
  static const updateSuccess = 'Événement mis à jour avec succès';

  /// Delete confirmation dialog title.
  static const confirmDeleteTitle = 'Supprimer l\'événement';

  /// Delete confirmation dialog content.
  static const confirmDelete =
      'Êtes-vous sûr de vouloir supprimer cet événement ?';

  /// Irreversible action warning.
  static const irreversible = 'Cette action est irréversible.';

  /// Cancel button label.
  static const cancel = 'Annuler';

  /// Delete button label.
  static const delete = 'Supprimer';

  /// Edit button label.
  static const edit = 'Modifier';

  /// Retry button label.
  static const retry = 'Réessayer';

  /// No events message.
  static const noEvents = 'Aucun événement à afficher';

  /// No events description.
  static const noEventsDescription =
      'Il n\'y a pas encore d\'événement prévu.';

  /// Add to calendar button label.
  static const addToCalendar = 'Ajouter à mon calendrier';

  /// Created by label.
  static const createdBy = 'Par';

  /// Event date label.
  static const eventDate = 'Le';

  /// Validate button label.
  static const validate = 'Valider';

  /// Save button label.
  static const save = 'Enregistrer';

  /// Required field error.
  static const requiredField = 'Ce champ est obligatoire';

  /// Invalid date error.
  static const invalidDate =
      'La date de fin doit être après la date de début';

  /// Add actions tooltip.
  static const addActionsTooltip = 'Actions';

  /// Calendar view: no events on selected day.
  static const noEventsOnDay = 'Aucun événement ce jour';

  /// Calendar view: events count for selected day.
  static const eventsOnDay = 'événement(s) le';

  /// Calendar format: month.
  static const formatMonth = 'Mois';

  /// Calendar format: 2 weeks.
  static const format2Weeks = '2 semaines';

  /// Calendar format: week.
  static const formatWeek = 'Semaine';

  /// Upcoming events section title.
  static const upcomingEvents = 'Événements à venir';

  /// Upcoming events section description.
  static String get upcomingEventsDescription =>
      'Les prochains événements de ${AppTextsGeneral.appName}';

  /// No upcoming events message.
  static const noUpcomingEvents = 'Aucun événement à venir';

  /// Day events modal title prefix.
  static const eventsOf = 'Événements du';

  /// Close button label.
  static const close = 'Fermer';

  /// Previous page tooltip.
  static const previousPage = 'Page précédente';

  /// Next page tooltip.
  static const nextPage = 'Page suivante';

  // ─── Repository error messages ─────────────────────────────────

  /// Invalid API response format.
  static const invalidResponseFormat = 'Format de réponse invalide';

  /// Error loading themes.
  static const fetchThemesError =
      'Erreur lors du chargement des thématiques';

  /// Error loading events.
  static const fetchEventsError =
      'Erreur lors du chargement des événements';

  /// Error loading event detail.
  static const fetchEventError =
      "Erreur lors du chargement de l'événement";

  /// Error creating an event.
  static const createEventError =
      "Erreur lors de la création de l'événement";

  /// Error updating an event.
  static const updateEventError =
      "Erreur lors de la mise à jour de l'événement";

  /// Error deleting an event.
  static const deleteEventError =
      "Erreur lors de la suppression de l'événement";
}
