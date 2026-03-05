/// Enumeration of problem types for reports.
enum ProblemType {
  /// Voirie
  roads('ROADS', 'Voirie'),

  /// Éclairage
  lighting('LIGHTING', 'Éclairage'),

  /// Propreté
  cleanliness('CLEANLINESS', 'Propreté');

  const ProblemType(this.value, this.label);

  /// Backend-side enum value.
  final String value;

  /// Display label.
  final String label;

  /// Creates a [ProblemType] from the backend string value.
  static ProblemType fromString(String value) {
    switch (value) {
      case 'ROADS':
        return ProblemType.roads;
      case 'LIGHTING':
        return ProblemType.lighting;
      case 'CLEANLINESS':
        return ProblemType.cleanliness;
      default:
        throw ArgumentError('Unknown problem type: $value');
    }
  }

  /// Converts the enum to a string for the backend.
  String toJson() => value;
}

