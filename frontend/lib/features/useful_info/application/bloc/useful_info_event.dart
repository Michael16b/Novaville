import 'package:equatable/equatable.dart';
import 'package:frontend/features/useful_info/domain/useful_info.dart';

sealed class UsefulInfoEvent extends Equatable {
  const UsefulInfoEvent();

  @override
  List<Object?> get props => [];
}

class UsefulInfoRequested extends UsefulInfoEvent {
  const UsefulInfoRequested();
}

class UsefulInfoRefreshed extends UsefulInfoEvent {
  const UsefulInfoRefreshed();
}

class UsefulInfoSaved extends UsefulInfoEvent {
  const UsefulInfoSaved(this.info);
  final UsefulInfo info;

  @override
  List<Object?> get props => [info];
}
