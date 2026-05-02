/// Centralized error messages for CSV and file drop operations
class CsvDropTexts {
  static const onlyCsvDrop = 'Déposez un fichier .csv uniquement.';
  static const unreadableFile = 'Le fichier CSV est illisible.';
  static const dropReadFailed = 'Lecture du fichier déposé impossible.';
  static const invalidOrMalformed =
      'Le fichier CSV est invalide ou mal formaté.';
  static const csvEmptyFile = 'Le fichier CSV est vide.';
  static const duplicateColumn = 'Colonne dupliquée';
  static const unknownColumn = 'Colonne non reconnue';
  static const missingRequiredColumn = 'Colonne obligatoire manquante';
  static const missingRequiredValue = 'Valeur obligatoire manquante';
  static const noWhitespaceAllowed = "Ne doit pas contenir d'espace";
  static const invalidFormat = 'Format invalide';
  static const roleLowercase =
      'Le rôle doit être en minuscule (ex: citizen, elected, agent)';
  static const invalidRoleValue =
      'Valeur invalide. Valeurs autorisées: citizen, elected, agent';
  static const duplicateDetected = 'Doublon détecté (liste actuelle/fichier)';
}
