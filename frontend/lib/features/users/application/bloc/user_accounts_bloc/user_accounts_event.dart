part of 'user_accounts_bloc.dart';

abstract class UserAccountsEvent extends Equatable {
  const UserAccountsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all user accounts
class UserAccountsLoadRequested extends UserAccountsEvent {
  const UserAccountsLoadRequested({this.ordering});
  final String? ordering;
  @override
  List<Object?> get props => [ordering];
}

/// Event to demander un tri sur une colonne
class UserAccountsSortRequested extends UserAccountsEvent {
  const UserAccountsSortRequested({required this.column, required this.ascending});
  final String column;
  final bool ascending;
  @override
  List<Object?> get props => [column, ascending];
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
  const UserAccountsPageRequested({required this.page});
  final int page;
  @override
  List<Object?> get props => [page];
}
