import 'package:equatable/equatable.dart';
import 'package:frontend/features/account/data/models/user_role.dart';

/// Modèle représentant un utilisateur
class User extends Equatable {
  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.role,
    this.neighborhoodId,
  });

  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final UserRole? role;
  final int? neighborhoodId;

  /// Crée un User à partir d'un JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      role: json['role'] != null
          ? UserRole.fromString(json['role'] as String)
          : null,
      neighborhoodId: json['neighborhood'] as int?,
    );
  }

  /// Convertit le User en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      if (role != null) 'role': role!.toJson(),
      if (neighborhoodId != null) 'neighborhood': neighborhoodId,
    };
  }

  /// Crée une copie du User avec les champs modifiés
  User copyWith({
    int? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    UserRole? role,
    int? neighborhoodId,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      neighborhoodId: neighborhoodId ?? this.neighborhoodId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        firstName,
        lastName,
        role,
        neighborhoodId,
      ];
}

