/// Text constants for the town hall neighborhoods management feature.
/// Variable names are in English, values in French.
class TownHallTexts {
  TownHallTexts._();

  /// Page title.
  static const title = 'Ma mairie';

  /// Page subtitle/description.
  static const titleDescription = 'Gérez les quartiers de la commune';

  /// Floating action button tooltip.
  static const createNeighborhood = 'Créer un quartier';

  /// Controls section description.
  static const managementSectionDescription =
      'Ajoutez, modifiez ou supprimez les quartiers de Novaville.';

  /// Dialog title for neighborhood creation.
  static const createDialogTitle = 'Créer un quartier';

  /// Message shown when opening creation dialog.
  static const createDialogMessage = 'Ajoutez les informations du quartier.';

  /// Dialog title for neighborhood edition.
  static const editDialogTitle = 'Modifier le quartier';

  /// Dialog title for neighborhood deletion.
  static const deleteDialogTitle = 'Supprimer le quartier';

  /// Neighborhood name label.
  static const neighborhoodNameLabel = 'Nom';

  /// Search field label.
  static const search = 'Rechercher';

  /// Search field hint.
  static const searchHint = 'Nom du quartier ou code postal';

  /// Cards per row label.
  static const cardsPerRow = 'Quartiers par ligne';

  /// Automatic option label.
  static const auto = 'Auto';

  /// Pagination "on" label.
  static const on = 'sur';

  /// Previous page tooltip.
  static const previousPage = 'Page précédente';

  /// Next page tooltip.
  static const nextPage = 'Page suivante';

  /// Postal code label.
  static const postalCodeLabel = 'Code postal';

  /// Short postal code label.
  static const postalCodeShort = 'CP';

  /// Empty state message.
  static const noNeighborhoods = 'Aucun quartier enregistré pour le moment.';

  /// Empty state for search results.
  static const noNeighborhoodsFound =
      'Aucun quartier ne correspond à votre recherche.';

  /// Generic irreversible action warning.
  static const irreversible = 'Cette action est irréversible.';

  /// Validation error for required fields.
  static const requiredFieldsError =
      'Le nom et le code postal sont obligatoires.';

  /// Load error message.
  static const loadError = 'Erreur lors du chargement des quartiers';

  /// Create success message.
  static const createSuccess = 'Quartier créé avec succès';

  /// Create error message.
  static const createError = 'Erreur lors de la création du quartier';

  /// Update success message.
  static const updateSuccess = 'Quartier modifié avec succès';

  /// Update error message.
  static const updateError = 'Erreur lors de la modification du quartier';

  /// Delete success message.
  static const deleteSuccess = 'Quartier supprimé avec succès';

  /// Delete error message.
  static const deleteError = 'Erreur lors de la suppression du quartier';

  /// Delete confirmation text.
  static String confirmDelete(String neighborhoodName) =>
      'Voulez-vous vraiment supprimer "$neighborhoodName" ?';
}
