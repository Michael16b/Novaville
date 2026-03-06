import 'package:flutter/material.dart';

/// Enhanced enum for event themes.
///
/// Each value associates:
/// - [value]: the backend key (e.g. 'SPORT'),
/// - [label]: the user-facing display label,
/// - [icon]: a descriptive icon (accessibility: never rely on color alone
///   — the label + icon together identify the theme).
enum EventTheme {
  /// Sport
  sport('SPORT', 'Sport', Icons.sports_soccer),

  /// Culture
  culture('CULTURE', 'Culture', Icons.theater_comedy),

  /// Citizenship
  citizenship('CITIZENSHIP', 'Citoyenneté', Icons.how_to_vote),

  /// Environment
  environment('ENVIRONMENT', 'Environnement', Icons.eco),

  /// Other
  other('OTHER', 'Autre', Icons.category);

  const EventTheme(this.value, this.label, this.icon);

  /// Backend-side enum value.
  final String value;

  /// Display label.
  final String label;

  /// Associated icon (color-blind accessibility: identifies the theme
  /// without relying on color alone).
  final IconData icon;

  /// Creates an [EventTheme] from a backend string value.
  ///
  /// Supports the enum key ('SPORT'), the French display label
  /// ('Citoyenneté') and the English label ('Citizenship')
  /// returned by the backend in `theme_detail.title`.
  static EventTheme fromString(String value) {
    final normalized = value.trim().toLowerCase();
    const lookup = <String, EventTheme>{
      // Keys
      'sport': EventTheme.sport,
      'culture': EventTheme.culture,
      'citizenship': EventTheme.citizenship,
      'environment': EventTheme.environment,
      'other': EventTheme.other,
      // French labels
      'citoyenneté': EventTheme.citizenship,
      'environnement': EventTheme.environment,
      'autre': EventTheme.other,
    };
    return lookup[normalized] ?? EventTheme.other;
  }

  /// Converts the enum to a string for the backend.
  String toJson() => value;
}

