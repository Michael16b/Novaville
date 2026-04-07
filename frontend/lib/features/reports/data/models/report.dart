import 'package:equatable/equatable.dart';
import 'package:frontend/features/reports/data/models/neighborhood.dart';
import 'package:frontend/features/reports/data/models/problem_type.dart';
import 'package:frontend/features/reports/data/models/report_status.dart';
import 'package:frontend/features/users/data/models/user.dart';

/// Model representing a citizen report.
class Report extends Equatable {
  /// Creates a [Report].
  const Report({
    required this.id,
    required this.title,
    required this.problemType,
    required this.description,
    required this.address,
    required this.createdAt,
    required this.status,
    required this.user,
    this.neighborhoodId,
    this.neighborhoodDetail,
  });


  /// Creates a [Report] from a JSON map.
  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] as int,
      title: (json['title'] as String?) ?? '',
      problemType: ProblemType.fromString(json['problem_type'] as String),
      description: json['description'] as String,
      address: (json['address'] as String?) ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      status: ReportStatus.fromString(json['status'] as String),
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      neighborhoodId: json['neighborhood'] as int?,
      neighborhoodDetail: json['neighborhood_detail'] != null
          ? Neighborhood.fromJson(
              json['neighborhood_detail'] as Map<String, dynamic>,
            )
          : null,
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

  /// Exact address of the issue.
  final String address;

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


  /// Converts this [Report] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'problem_type': problemType.toJson(),
      'description': description,
      'address': address,
      'created_at': createdAt.toIso8601String(),
      'status': status.toJson(),
      if (neighborhoodId != null) 'neighborhood': neighborhoodId,
    };
  }

  /// Returns a copy of this [Report] with the given fields replaced.
  Report copyWith({
    int? id,
    String? title,
    ProblemType? problemType,
    String? description,
    String? address,
    DateTime? createdAt,
    ReportStatus? status,
    User? user,
    int? neighborhoodId,
    Neighborhood? neighborhoodDetail,
  }) {
    return Report(
      id: id ?? this.id,
      title: title ?? this.title,
      problemType: problemType ?? this.problemType,
      description: description ?? this.description,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      user: user ?? this.user,
      neighborhoodId: neighborhoodId ?? this.neighborhoodId,
      neighborhoodDetail: neighborhoodDetail ?? this.neighborhoodDetail,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        problemType,
        description,
        address,
        createdAt,
        status,
        user,
        neighborhoodId,
        neighborhoodDetail,
      ];
}
