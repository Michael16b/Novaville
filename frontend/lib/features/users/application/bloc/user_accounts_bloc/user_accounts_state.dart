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
    this.page = 1,
    this.count = 0,
    this.next,
    this.previous,
    this.pageSize = 20,
  });

  const UserAccountsState.initial()
      : status = UserAccountsStatus.initial,
        users = const <User>[],
        error = null,
        page = 1,
        count = 0,
        next = null,
        previous = null,
        pageSize = 20;

  const UserAccountsState.loading()
      : status = UserAccountsStatus.loading,
        users = const <User>[],
        error = null,
        page = 1,
        count = 0,
        next = null,
        previous = null,
        pageSize = 20;

  const UserAccountsState.loaded(List<User> users, {
    required int page,
    required int count,
    String? next,
    String? previous,
    int pageSize = 20,
  }) : status = UserAccountsStatus.loaded,
        users = users,
        error = null,
        page = page,
        count = count,
        next = next,
        previous = previous,
        pageSize = pageSize;

  const UserAccountsState.failure(String message)
      : status = UserAccountsStatus.failure,
        users = const <User>[],
        error = message,
        page = 1,
        count = 0,
        next = null,
        previous = null,
        pageSize = 20;

  final UserAccountsStatus status;
  final List<User> users;
  final String? error;
  final int page;
  final int count;
  final String? next;
  final String? previous;
  final int pageSize;

  @override
  List<Object?> get props => [status, users, error, page, count, next, previous, pageSize];
}
