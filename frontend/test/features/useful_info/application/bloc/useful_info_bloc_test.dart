import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/useful_info/application/bloc/useful_info_bloc.dart';
import 'package:frontend/features/useful_info/application/bloc/useful_info_event.dart';
import 'package:frontend/features/useful_info/application/bloc/useful_info_state.dart';
import 'package:frontend/features/useful_info/data/useful_info_api.dart';
import 'package:frontend/features/useful_info/data/useful_info_repository.dart';
import 'package:frontend/features/useful_info/domain/useful_info.dart';

void main() {
  group('UsefulInfoBloc', () {
    test('emits save failure with previous info when save fails', () async {
      const info = UsefulInfo(
        cityHallName: 'Mairie de Novaville',
        addressLine1: '1 place de la Mairie',
        postalCode: '75000',
        city: 'Novaville',
        openingHours: {},
      );

      final repository = _FailingSaveUsefulInfoRepository(info);
      final bloc = UsefulInfoBloc(repository: repository);

      final states = <UsefulInfoState>[];
      final subscription = bloc.stream.listen(states.add);

      bloc.add(const UsefulInfoRequested());
      await Future<void>.delayed(Duration.zero);

      bloc.add(const UsefulInfoSaved(info));
      await Future<void>.delayed(Duration.zero);

      expect(
        states,
        contains(
          const UsefulInfoSaveFailure(
            info: info,
            message: 'Impossible de modifier les infos utiles.',
          ),
        ),
      );

      await subscription.cancel();
      await bloc.close();
    });
  });
}

class _FailingSaveUsefulInfoRepository implements UsefulInfoRepository {
  final UsefulInfo info;

  const _FailingSaveUsefulInfoRepository(this.info);

  @override
  Future<UsefulInfo> getUsefulInfo() async => info;

  @override
  Future<void> saveUsefulInfo(UsefulInfo info) async {
    throw const UsefulInfoApiException(
      statusCode: 400,
      message: 'Erreur mise à jour useful info (400)',
    );
  }
}
