part of 'user_accounts_bloc.dart';

enum UserAccountsStatus {
  initial,
  loading,
  loaded,
  failure,
}

class UserAccountsState extends Equatable {
  const UserAccountsState({
    required this.status,
    this.users = const <User>[],
    this.error,
  });

  const UserAccountsState.initial()
      : status = UserAccountsStatus.initial,
        users = const <User>[],
        error = null;

  const UserAccountsState.loading()
      : status = UserAccountsStatus.loading,
        users = const <User>[],
        error = null;

  const UserAccountsState.loaded(List<User> users)
      : status = UserAccountsStatus.loaded,
        users = users,
        error = null;

  const UserAccountsState.failure(String message)
      : status = UserAccountsStatus.failure,
        users = const <User>[],
        error = message;

  final UserAccountsStatus status;
  final List<User> users;
  final String? error;

  @override
  List<Object?> get props => [status, users, error];
}

