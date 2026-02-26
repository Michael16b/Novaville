part of 'auth_bloc.dart';

enum AuthStatus {
  unauthenticated,
  checking,
  authenticating,
  authenticated,
  failure,
}

class AuthState extends Equatable {
  const AuthState({
    required this.status,
    this.error,
    this.user,
  });

  const AuthState.unauthenticated()
    : status = AuthStatus.unauthenticated,
      error = null,
      user = null;
  const AuthState.checking()
    : status = AuthStatus.checking,
      error = null,
      user = null;
  const AuthState.authenticating()
    : status = AuthStatus.authenticating,
      error = null,
      user = null;
  const AuthState.authenticated({User? user})
    : status = AuthStatus.authenticated,
      error = null,
      user = user;
  const AuthState.failure(String message)
    : status = AuthStatus.failure,
      error = message,
      user = null;

  final AuthStatus status;
  final String? error;
  final User? user;

  AuthState copyWith({
    AuthStatus? status,
    String? error,
    User? user,
  }) {
    return AuthState(
      status: status ?? this.status,
      error: error ?? this.error,
      user: user ?? this.user,
    );
  }

  @override
  List<Object?> get props => [status, error, user];
}
