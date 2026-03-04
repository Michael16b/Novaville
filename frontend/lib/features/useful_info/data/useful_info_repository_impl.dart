import '../domain/useful_info.dart';
import 'useful_info_api.dart';
import 'useful_info_repository.dart';

class UsefulInfoRepositoryImpl implements UsefulInfoRepository {
  final UsefulInfoApi api;

  UsefulInfoRepositoryImpl(this.api);

  @override
  Future<UsefulInfo> getUsefulInfo() async {
    final json = await api.fetchUsefulInfo();
    return UsefulInfo.fromJson(json);
  }

  @override
  Future<void> saveUsefulInfo(UsefulInfo info) async {
    await api.updateUsefulInfo(info.toJson());
  }
}
