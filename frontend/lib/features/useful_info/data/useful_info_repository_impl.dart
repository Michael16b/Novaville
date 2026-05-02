import 'package:frontend/features/useful_info/domain/useful_info.dart';
import 'package:frontend/features/useful_info/data/useful_info_api.dart';
import 'package:frontend/features/useful_info/data/useful_info_repository.dart';

class UsefulInfoRepositoryImpl implements UsefulInfoRepository {
  UsefulInfoRepositoryImpl(this.api);
  final UsefulInfoApi api;

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
