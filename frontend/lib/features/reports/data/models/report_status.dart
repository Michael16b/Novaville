/// Enumeration of report statuses.
enum ReportStatus {
  /// Enregistré
  recorded('RECORDED', 'Enregistré'),

  /// En cours
  inProgress('IN_PROGRESS', 'En cours'),

  /// Résolu
  resolved('RESOLVED', 'Résolu');

  const ReportStatus(this.value, this.label);

  /// Backend-side enum value.
  final String value;

  /// Display label.
  final String label;

  /// Creates a [ReportStatus] from the backend string value.
  static ReportStatus fromString(String value) {
    switch (value) {
      case 'RECORDED':
        return ReportStatus.recorded;
      case 'IN_PROGRESS':
        return ReportStatus.inProgress;
      case 'RESOLVED':
        return ReportStatus.resolved;
      default:
        throw ArgumentError('Unknown report status: $value');
    }
  }

  /// Converts the enum to a string for the backend.
  String toJson() => value;
}

