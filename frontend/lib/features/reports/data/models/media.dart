import 'package:equatable/equatable.dart';

/// Model representing a media file attached to a report.
class Media extends Equatable {
  /// Creates a [Media].
  const Media({
    required this.id,
    required this.fileUrl,
    required this.createdAt,
  });

  /// Creates a [Media] from a JSON map.
  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'] as int,
      fileUrl: json['file_url'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Unique identifier.
  final int id;

  /// URL of the file.
  final String fileUrl;

  /// Creation date.
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, fileUrl, createdAt];
}
