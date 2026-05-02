import 'package:equatable/equatable.dart';
import 'package:frontend/features/users/data/models/user_role.dart';

/// Model representing a user.
class User extends Equatable {
  /// Creates a [User] from a JSON map.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      email: (json['email'] as String?) ?? '',
      firstName: (json['first_name'] as String?) ?? '',
      lastName: (json['last_name'] as String?) ?? '',
      address: (json['address'] as String?) ?? '',
      approvalStatus: (json['approval_status'] as String?) ?? 'APPROVED',
      isActive: (json['is_active'] as bool?) ?? true,
      role: json['role'] != null
          ? UserRole.fromString(json['role'] as String)
          : null,
      neighborhoodId: json['neighborhood'] as int?,
    );
  }
  const User({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.email = '',
    this.address = '',
    this.approvalStatus = 'APPROVED',
    this.isActive = true,
    this.role,
    this.neighborhoodId,
  });

  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String address;
  final String approvalStatus;
  final bool isActive;
  final UserRole? role;
  final int? neighborhoodId;

  /// Converts this [User] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'address': address,
      'approval_status': approvalStatus,
      'is_active': isActive,
      if (role != null) 'role': role!.toJson(),
      if (neighborhoodId != null) 'neighborhood': neighborhoodId,
    };
  }

  /// Returns a copy of this [User] with the given fields replaced.
  User copyWith({
    int? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? address,
    String? approvalStatus,
    bool? isActive,
    UserRole? role,
    int? neighborhoodId,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      address: address ?? this.address,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      isActive: isActive ?? this.isActive,
      role: role ?? this.role,
      neighborhoodId: neighborhoodId ?? this.neighborhoodId,
    );
  }

  /// Helper methods to check user roles
  bool get isGlobalAdmin => role == UserRole.globalAdmin;
  bool get isElected => role == UserRole.elected;
  bool get isAgent => role == UserRole.agent;
  bool get isCitizen => role == UserRole.citizen;

  /// Check if user has staff privileges (elected, agent, or admin)
  bool get isStaff =>
      role != null &&
      (role == UserRole.elected ||
          role == UserRole.agent ||
          role == UserRole.globalAdmin);

  @override
  List<Object?> get props => [
    id,
    username,
    email,
    firstName,
    lastName,
    address,
    approvalStatus,
    isActive,
    role,
    neighborhoodId,
  ];
}
