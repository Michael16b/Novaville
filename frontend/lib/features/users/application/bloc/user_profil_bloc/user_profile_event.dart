part of 'user_profile_bloc.dart';

/// Events for the UserProfileBloc.
abstract class UserProfileEvent extends Equatable {
  const UserProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load the user profile.
class UserProfileLoadRequested extends UserProfileEvent {
  const UserProfileLoadRequested();
}

/// Event to update the user profile.
class UserProfileUpdateRequested extends UserProfileEvent {
  const UserProfileUpdateRequested({
    required this.userId,
    this.firstName,
    this.lastName,
    this.username,
    this.email,
  });

  final int userId;
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? email;

  @override
  List<Object?> get props => [userId, firstName, lastName, username, email];
}

/// Event to update the user password.
class UserProfilePasswordUpdateRequested extends UserProfileEvent {
  const UserProfilePasswordUpdateRequested({
    required this.userId,
    required this.currentPassword,
    required this.newPassword,
  });

  final int userId;
  final String currentPassword;
  final String newPassword;

  @override
  List<Object?> get props => [userId, currentPassword, newPassword];
}
