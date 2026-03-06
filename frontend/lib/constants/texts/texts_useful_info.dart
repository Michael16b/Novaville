/// Text constants for the useful info feature.
/// Variable names are in English, values in French.
class UsefulInfoTexts {
  UsefulInfoTexts._();

  /// Page title.
  static const title = 'Infos utiles';

  /// Page description / subtitle.
  static const description = 'Retrouvez les informations pratiques de la ville';

  /// Sections titles.
  static const cityHallSection = 'Mairie';
  static const openingHoursSection = 'Horaires d’ouverture';
  static const contactSection = 'Contact';

  /// Optional: accessibility / header description (if you want like ReportsPage).
  static const titleDescription =
      'Consultez les informations pratiques de la ville';

  /// Empty state title.
  static const noUsefulInfo = 'Aucune information utile';

  /// Empty state description.
  static const noUsefulInfoFound = 'Aucune donnée disponible pour le moment';

  /// Generic error label (optional, if you want to standardize).
  static const error = 'Erreur';

  /// Loading label (optional if you ever display text instead of spinner).
  static const loading = 'Chargement...';

  /// Admin edit action tooltip/label (optional if you add tooltip later).
  static const edit = 'Modifier';

  static const emailLabel = 'Email :';
  static const phoneLabel = 'Téléphone :';
  static const websiteLabel = 'Site web :';
}
