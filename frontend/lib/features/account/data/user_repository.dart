import 'package:frontend/features/account/data/models/user.dart';

/// Interface du repository pour les opérations utilisateur
abstract class IUserRepository {
  /// Récupère les informations de l'utilisateur connecté
  Future<User> getCurrentUser();

  /// Met à jour les informations de l'utilisateur
  Future<User> updateUser({
    required int userId,
    String? firstName,
    String? lastName,
    String? username,
    String? email,
  });
}

