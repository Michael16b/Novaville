import 'package:equatable/equatable.dart';
import '../../domain/useful_info.dart';

sealed class UsefulInfoEvent extends Equatable {
  const UsefulInfoEvent();

  @override
  List<Object?> get props => [];
}

/// Charge les infos utiles (GET)
class UsefulInfoRequested extends UsefulInfoEvent {
  const UsefulInfoRequested();
}

/// Force un refresh (peut être identique à Requested, mais pratique)
class UsefulInfoRefreshed extends UsefulInfoEvent {
  const UsefulInfoRefreshed();
}

/// Sauvegarde les infos utiles (PUT) -> réservé admin côté backend
class UsefulInfoSaved extends UsefulInfoEvent {
  final UsefulInfo info;

  const UsefulInfoSaved(this.info);

  @override
  List<Object?> get props => [info];
}
