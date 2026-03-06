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
  /// Matches against the enum key ('SPORT'), the Dart name ('sport'),
  /// and the display label ('Citoyenneté') — all case-insensitive.
  /// Falls back to [EventTheme.other] if no match is found.
  static EventTheme fromString(String value) {
    final normalized = value.trim().toLowerCase();
    for (final theme in EventTheme.values) {
      if (theme.value.toLowerCase() == normalized ||
          theme.label.toLowerCase() == normalized ||
          theme.name.toLowerCase() == normalized) {
        return theme;
      }
    }
    return EventTheme.other;
  }

  /// Converts the enum to a string for the backend.
  String toJson() => value;
}

