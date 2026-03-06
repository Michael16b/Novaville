import '../domain/useful_info.dart';

abstract class UsefulInfoRepository {
  Future<UsefulInfo> getUsefulInfo();
  Future<void> saveUsefulInfo(UsefulInfo info);
}
