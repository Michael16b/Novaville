part of 'user_accounts_bloc.dart';

abstract class UserAccountsEvent extends Equatable {
  const UserAccountsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all user accounts
class UserAccountsLoadRequested extends UserAccountsEvent {
  const UserAccountsLoadRequested();
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

