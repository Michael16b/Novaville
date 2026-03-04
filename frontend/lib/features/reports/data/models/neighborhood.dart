import 'package:equatable/equatable.dart';

/// Model representing a neighborhood/district.
class Neighborhood extends Equatable {
  /// Creates a [Neighborhood].
  const Neighborhood({
    required this.id,
    required this.name,
    required this.postalCode,
  });

  /// Creates a [Neighborhood] from a JSON map.
  factory Neighborhood.fromJson(Map<String, dynamic> json) {
    return Neighborhood(
      id: json['id'] as int,
      name: json['name'] as String,
      postalCode: json['postal_code'] as String,
    );
  }

  /// Unique identifier.
  final int id;

  /// Name of the neighborhood.
  final String name;

  /// Postal code.
  final String postalCode;

  @override
  List<Object?> get props => [id, name, postalCode];
}
