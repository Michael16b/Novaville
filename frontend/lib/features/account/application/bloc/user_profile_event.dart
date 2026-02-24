part of 'user_profile_bloc.dart';

/// Événements du UserProfileBloc
abstract class UserProfileEvent extends Equatable {
  const UserProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Événement pour charger le profil utilisateur
class UserProfileLoadRequested extends UserProfileEvent {
  const UserProfileLoadRequested();
}

/// Événement pour mettre à jour le profil utilisateur
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

