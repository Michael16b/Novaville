part of 'user_accounts_bloc.dart';

abstract class UserAccountsEvent extends Equatable {
  const UserAccountsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all user accounts
class UserAccountsLoadRequested extends UserAccountsEvent {
  const UserAccountsLoadRequested({this.ordering, this.search});
  final String? ordering;
  final String? search;
  @override
  List<Object?> get props => [ordering, search];
}

/// Event to demander un tri sur une colonne
class UserAccountsSortRequested extends UserAccountsEvent {
  const UserAccountsSortRequested({
    required this.column,
    required this.ascending,
    this.search,
  });
  final String column;
  final bool ascending;
  final String? search;
  @override
  List<Object?> get props => [column, ascending, search];
}

/// Event to delete a user account
class UserAccountsDeleteRequested extends UserAccountsEvent {
  const UserAccountsDeleteRequested({required this.userId});

  final int userId;

  @override
  List<Object?> get props => [userId];
}

/// Event to refresh the user accounts list
class UserAccountsRefreshRequested extends UserAccountsEvent {
  const UserAccountsRefreshRequested();
}

/// Event to demander une page spécifique
class UserAccountsPageRequested extends UserAccountsEvent {
  const UserAccountsPageRequested({
    required this.page,
    this.ordering,
    this.search,
  });
  final int page;
  final String? ordering;
  final String? search;
  @override
  List<Object?> get props => [page, ordering, search];
}

/// Event to request a filtered list based on a search query.
class UserAccountsSearchRequested extends UserAccountsEvent {
  const UserAccountsSearchRequested({required this.query, this.ordering});

  final String query;
  final String? ordering;

  @override
  List<Object?> get props => [query, ordering];
}

/// Event to apply advanced filters (role, address).
class UserAccountsFilterRequested extends UserAccountsEvent {
  /// Creates a [UserAccountsFilterRequested].
  const UserAccountsFilterRequested({
    this.role,
    this.address,
    this.ordering,
    this.search,
  });

  /// Filter by role.
  final String? role;

  /// Filter by address.
  final String? address;

  /// Current ordering.
  final String? ordering;

  /// Current search query.
  final String? search;

  @override
  List<Object?> get props => [role, address, ordering, search];
}

/// Event to load neighborhoods for filter dropdowns.
class UserAccountsNeighborhoodsLoadRequested extends UserAccountsEvent {
  /// Creates a [UserAccountsNeighborhoodsLoadRequested].
  const UserAccountsNeighborhoodsLoadRequested();
}
