import 'package:frontend/features/account/data/models/user.dart';

/// Repository interface for user operations.
abstract class IUserRepository {
  /// Retrieves the currently logged-in user's information.
  Future<User> getCurrentUser();

  /// Updates the user's information.
  Future<User> updateUser({
    required int userId,
    String? firstName,
    String? lastName,
    String? username,
    String? email,
  });
}
