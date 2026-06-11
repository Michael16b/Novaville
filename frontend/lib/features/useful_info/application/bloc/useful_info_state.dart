import 'package:equatable/equatable.dart';

import '../../domain/useful_info.dart';

/// Represents the current status of the useful info feature.
///
/// This file contains the various states that the [UsefulInfoBloc]
/// can emit while loading, saving or reporting errors.
sealed class UsefulInfoState extends Equatable {
  const UsefulInfoState();

  @override
  List<Object?> get props => [];
}

/// No action has been taken yet. The bloc will normally dispatch a
/// [UsefulInfoRequested] event when this state is seen for the first time.
class UsefulInfoInitial extends UsefulInfoState {
  const UsefulInfoInitial();
}

/// Data is currently being fetched from the backend.
class UsefulInfoLoading extends UsefulInfoState {
  const UsefulInfoLoading();
}

/// An error occurred while talking to the API.
class UsefulInfoFailure extends UsefulInfoState {
  final String message;
  const UsefulInfoFailure(this.message);

  @override
  List<Object?> get props => [message];
}

/// The useful info is available and stored in [info].
class UsefulInfoLoaded extends UsefulInfoState {
  final UsefulInfo info;
  const UsefulInfoLoaded(this.info);

  @override
  List<Object?> get props => [info];
}

/// A save operation is in progress. [info] contains the value that will be
/// persisted (or the previous value while the request is ongoing).
class UsefulInfoSaving extends UsefulInfoState {
  final UsefulInfo info;
  const UsefulInfoSaving(this.info);

  @override
  List<Object?> get props => [info];
}

/// A save operation failed, but the previous useful info remains available.
class UsefulInfoSaveFailure extends UsefulInfoState {
  final UsefulInfo info;
  final String message;

  const UsefulInfoSaveFailure({required this.info, required this.message});

  @override
  List<Object?> get props => [info, message];
}
