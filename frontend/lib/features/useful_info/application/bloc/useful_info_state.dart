import 'package:equatable/equatable.dart';
import 'package:frontend/features/useful_info/application/bloc/useful_info.dart'
    show UsefulInfoBloc, UsefulInfoRequested;
import 'package:frontend/features/useful_info/application/bloc/useful_info_bloc.dart'
    show UsefulInfoBloc;
import 'package:frontend/features/useful_info/application/bloc/useful_info_event.dart'
    show UsefulInfoRequested;

import 'package:frontend/features/useful_info/domain/useful_info.dart';

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
  const UsefulInfoFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

/// The useful info is available and stored in [info].
class UsefulInfoLoaded extends UsefulInfoState {
  const UsefulInfoLoaded(this.info);
  final UsefulInfo info;

  @override
  List<Object?> get props => [info];
}

/// A save operation is in progress. [info] contains the value that will be
/// persisted (or the previous value while the request is ongoing).
class UsefulInfoSaving extends UsefulInfoState {
  const UsefulInfoSaving(this.info);
  final UsefulInfo info;

  @override
  List<Object?> get props => [info];
}
