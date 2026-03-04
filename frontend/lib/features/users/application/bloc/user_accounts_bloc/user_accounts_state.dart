part of 'user_accounts_bloc.dart';

enum UserAccountsStatus { initial, loading, loaded, failure }

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
    this.search = '',
    this.neighborhoods = const <Neighborhood>[],
  });

  const UserAccountsState.initial()
    : status = UserAccountsStatus.initial,
      users = const <User>[],
      error = null,
      page = 1,
      count = 0,
      next = null,
      previous = null,
      pageSize = 20,
      search = '',
      neighborhoods = const <Neighborhood>[];

  const UserAccountsState.loading()
    : status = UserAccountsStatus.loading,
      users = const <User>[],
      error = null,
      page = 1,
      count = 0,
      next = null,
      previous = null,
      pageSize = 20,
      search = '',
      neighborhoods = const <Neighborhood>[];

  const UserAccountsState.loaded(
    this.users, {
    required this.page,
    required this.count,
    this.next,
    this.previous,
    this.pageSize = 20,
    this.search = '',
    this.neighborhoods = const <Neighborhood>[],
  }) : status = UserAccountsStatus.loaded,
       error = null;

  const UserAccountsState.failure(String message)
    : status = UserAccountsStatus.failure,
      users = const <User>[],
      error = message,
      page = 1,
      count = 0,
      next = null,
      previous = null,
      pageSize = 20,
      search = '',
      neighborhoods = const <Neighborhood>[];

  final UserAccountsStatus status;
  final List<User> users;
  final String? error;
  final int page;
  final int count;
  final String? next;
  final String? previous;
  final int pageSize;
  final String search;
  final List<Neighborhood> neighborhoods;

  UserAccountsState copyWith({
    UserAccountsStatus? status,
    List<User>? users,
    String? error,
    int? page,
    int? count,
    String? next,
    String? previous,
    int? pageSize,
    String? search,
    List<Neighborhood>? neighborhoods,
  }) {
    return UserAccountsState(
      status: status ?? this.status,
      users: users ?? this.users,
      error: error ?? this.error,
      page: page ?? this.page,
      count: count ?? this.count,
      next: next ?? this.next,
      previous: previous ?? this.previous,
      pageSize: pageSize ?? this.pageSize,
      search: search ?? this.search,
      neighborhoods: neighborhoods ?? this.neighborhoods,
    );
  }

  @override
  List<Object?> get props => [
    status,
    users,
    error,
    page,
    count,
    next,
    previous,
    pageSize,
    search,
    neighborhoods,
  ];
}
