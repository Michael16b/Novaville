import 'package:frontend/features/reports/data/models/neighborhood.dart';
import 'package:frontend/features/users/data/models/user.dart';
import 'package:frontend/features/users/data/models/user_role.dart';

class UserPage {
  final int count;
  final String? next;
  final String? previous;
  final List<User> results;

  UserPage({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory UserPage.fromJson(Map<String, dynamic> json) {
    return UserPage(
      count: json['count'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results: (json['results'] as List<dynamic>)
          .map((u) => User.fromJson(u as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Repository interface for user operations.
abstract class IUserRepository {
  /// Retrieves the currently logged-in user's information.
  Future<User> getCurrentUser();

  /// Retrieves a paginated list of users.
  Future<UserPage> listUsers({
    String? ordering,
    String? search,
    int page = 1,
    String? role,
    String? address,
    int? neighborhood,
  });

  /// Updates the user's information.
  Future<User> updateUser({
    required int userId,
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    String? address,
    UserRole? role,
    int? neighborhoodId,
  });

  /// Updates the user's password.
  Future<void> updatePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  });

  /// Resets the user's password (admin action).
  Future<void> resetPassword({
    required int userId,
    required String newPassword,
  });

  /// Deletes a user.
  Future<void> deleteUser({required int userId});

  /// Creates a new user account.
  Future<User> createUser({
    required String username,
    String email = '',
    required String firstName,
    required String lastName,
    required String password,
    String address = '',
    UserRole role = UserRole.citizen,
    int? neighborhoodId,
  });

  Future<List<User>> listPendingUsers();

  Future<User> approveUser({required int userId});

  Future<void> rejectUser({required int userId});

  /// Lists all available neighborhoods.
  Future<List<Neighborhood>> listNeighborhoods();
}
