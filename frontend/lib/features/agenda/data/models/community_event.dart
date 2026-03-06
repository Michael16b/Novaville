import 'package:equatable/equatable.dart';
import 'package:frontend/features/agenda/data/models/event_theme.dart';
import 'package:frontend/features/users/data/models/user.dart';

/// Model representing a community event.
///
/// Named [CommunityEvent] (not "Event") to avoid naming conflicts
/// with BLoC event classes.
class CommunityEvent extends Equatable {
  /// Creates a [CommunityEvent].
  const CommunityEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.createdBy,
    this.themeId,
    this.theme,
  });

  /// Creates a [CommunityEvent] from a JSON map.
  factory CommunityEvent.fromJson(Map<String, dynamic> json) {
    return CommunityEvent(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      startDate: DateTime.parse(json['start_date'] as String).toLocal(),
      endDate: DateTime.parse(json['end_date'] as String).toLocal(),
      createdBy: User.fromJson(json['created_by'] as Map<String, dynamic>),
      themeId: json['theme'] as int?,
      theme: json['theme_detail'] != null
          ? EventTheme.fromString(
              (json['theme_detail'] as Map<String, dynamic>)['title']
                  as String,
            )
          : null,
    );
  }

  /// Unique identifier.
  final int id;

  /// Event title.
  final String title;

  /// Detailed description.
  final String description;

  /// Start date and time.
  final DateTime startDate;

  /// End date and time.
  final DateTime endDate;

  /// User who created the event.
  final User createdBy;

  /// Theme ID (foreign key).
  final int? themeId;

  /// Resolved theme (from theme_detail).
  final EventTheme? theme;

  /// Converts this [CommunityEvent] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      if (themeId != null) 'theme': themeId,
    };
  }

  /// Returns a copy with the specified fields replaced.
  CommunityEvent copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    User? createdBy,
    int? themeId,
    EventTheme? theme,
  }) {
    return CommunityEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdBy: createdBy ?? this.createdBy,
      themeId: themeId ?? this.themeId,
      theme: theme ?? this.theme,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        startDate,
        endDate,
        createdBy,
        themeId,
        theme,
      ];
}

