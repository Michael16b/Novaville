part of 'user_profile_bloc.dart';

/// États du UserProfileBloc
enum UserProfileStatus {
  initial,
  loading,
  loaded,
  updating,
  failure,
}

class UserProfileState extends Equatable {
  const UserProfileState({
    required this.status,
    this.user,
    this.error,
    this.isUpdate = false,
  });

  const UserProfileState.initial()
      : status = UserProfileStatus.initial,
        user = null,
        error = null,
        isUpdate = false;

  const UserProfileState.loading()
      : status = UserProfileStatus.loading,
        user = null,
        error = null,
        isUpdate = false;

  const UserProfileState.loaded(User loadedUser, {bool isUpdate = false})
      : status = UserProfileStatus.loaded,
        user = loadedUser,
        error = null,
        isUpdate = isUpdate;

  const UserProfileState.updating(User currentUser)
      : status = UserProfileStatus.updating,
        user = currentUser,
        error = null,
        isUpdate = false;

  const UserProfileState.failure(String message)
      : status = UserProfileStatus.failure,
        user = null,
        error = message,
        isUpdate = false;

  final UserProfileStatus status;
  final User? user;
  final String? error;
  final bool isUpdate;

  @override
  List<Object?> get props => [status, user, error, isUpdate];
}

