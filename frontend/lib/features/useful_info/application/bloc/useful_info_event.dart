import 'package:equatable/equatable.dart';
import '../../domain/useful_info.dart';

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
  final UsefulInfo info;

  const UsefulInfoSaved(this.info);

  @override
  List<Object?> get props => [info];
}
