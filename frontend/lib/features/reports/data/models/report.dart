import 'package:equatable/equatable.dart';
import 'package:frontend/features/reports/data/models/neighborhood.dart';
import 'package:frontend/features/reports/data/models/problem_type.dart';
import 'package:frontend/features/reports/data/models/report_status.dart';
import 'package:frontend/features/users/data/models/user.dart';
import 'package:frontend/features/reports/data/models/media.dart';

/// Model representing a citizen report.
class Report extends Equatable {
  /// Creates a [Report].
  const Report({
    required this.id,
    required this.title,
    required this.problemType,
    required this.description,
    required this.createdAt,
    required this.status,
    required this.user,
    this.neighborhoodId,
    this.neighborhoodDetail,
    this.latitude,
    this.longitude,
    this.address,
    this.media = const [],
  });

  /// Creates a [Report] from a JSON map.
  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as int,
      title: (json['title'] as String?) ?? '',
      problemType: ProblemType.fromString(json['problem_type'] as String),
      description: json['description'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      status: ReportStatus.fromString(json['status'] as String),
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      neighborhoodId: json['neighborhood'] as int?,
      neighborhoodDetail: json['neighborhood_detail'] != null
          ? Neighborhood.fromJson(
              json['neighborhood_detail'] as Map<String, dynamic>,
            )
          : null,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address'] as String?,
      media: (json['media'] as List<dynamic>?)
              ?.map((e) => Media.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  /// Unique identifier.
  final int id;

  /// Title of the report.
  final String title;

  /// Type of problem reported.
  final ProblemType problemType;

  /// Description of the issue.
  final String description;

  /// Creation date.
  final DateTime createdAt;

  /// Current status of the report.
  final ReportStatus status;

  /// User who created the report.
  final User user;

  /// Neighborhood ID.
  final int? neighborhoodId;

  /// Neighborhood details.
  final Neighborhood? neighborhoodDetail;

  /// Latitude of the report location.
  final double? latitude;

  /// Longitude of the report location.
  final double? longitude;

  /// Address of the report location.
  final String? address;

  /// Media attached to the report.
  final List<Media> media;

  /// Converts this [Report] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'problem_type': problemType.toJson(),
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'status': status.toJson(),
      if (neighborhoodId != null) 'neighborhood': neighborhoodId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (address != null) 'address': address,
    };
  }

  /// Returns a copy of this [Report] with the given fields replaced.
  Report copyWith({
    int? id,
    String? title,
    ProblemType? problemType,
    String? description,
    DateTime? createdAt,
    ReportStatus? status,
    User? user,
    int? neighborhoodId,
    Neighborhood? neighborhoodDetail,
    double? latitude,
    double? longitude,
    String? address,
    List<Media>? media,
  }) {
    return Report(
      id: id ?? this.id,
      title: title ?? this.title,
      problemType: problemType ?? this.problemType,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      user: user ?? this.user,
      neighborhoodId: neighborhoodId ?? this.neighborhoodId,
      neighborhoodDetail: neighborhoodDetail ?? this.neighborhoodDetail,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      media: media ?? this.media,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        problemType,
        description,
        createdAt,
        status,
        user,
        neighborhoodId,
        neighborhoodDetail,
        latitude,
        longitude,
        address,
        media,
      ];
}
