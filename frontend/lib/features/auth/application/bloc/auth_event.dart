part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
  @override
  List<Object?> get props => const [];
}

class AuthLoginSubmitted extends AuthEvent {
  const AuthLoginSubmitted({required this.username, required this.password});
  final String username;
  final String password;
  @override
  List<Object?> get props => [username, password];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
  @override
  List<Object?> get props => const [];
}
