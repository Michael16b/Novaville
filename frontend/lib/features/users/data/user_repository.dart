import 'package:frontend/features/users/data/models/user.dart';

/// Repository interface for user operations.
abstract class IUserRepository {
  /// Retrieves the currently logged-in user's information.
  Future<User> getCurrentUser();

  /// Retrieves a list of all users.
  Future<List<User>> listUsers();

  /// Updates the user's information.
  Future<User> updateUser({
    required int userId,
    String? firstName,
    String? lastName,
    String? username,
    String? email,
  });

  /// Deletes a user.
  Future<void> deleteUser({required int userId});
}
