import '../domain/useful_info.dart';

abstract class UsefulInfoRepository {
  /// Récupère les informations utiles (GET)
  Future<UsefulInfo> getUsefulInfo();

  /// Sauvegarde les informations utiles (PUT)
  /// ⚠️ Doit être protégé côté backend (admin only)
  Future<void> saveUsefulInfo(UsefulInfo info);
}
