part of 'auth_bloc.dart';

enum AuthStatus {
  unauthenticated,
  checking,
  authenticating,
  authenticated,
  failure,
}

class AuthState extends Equatable {
  const AuthState({required this.status, this.error});

  const AuthState.unauthenticated()
    : status = AuthStatus.unauthenticated,
      error = null;
  const AuthState.checking() : status = AuthStatus.checking, error = null;
  const AuthState.authenticating()
    : status = AuthStatus.authenticating,
      error = null;
  const AuthState.authenticated()
    : status = AuthStatus.authenticated,
      error = null;
  const AuthState.failure(String message)
    : status = AuthStatus.failure,
      error = message;
  final AuthStatus status;
  final String? error;

  AuthState copyWith({AuthStatus? status, String? error}) {
    return AuthState(status: status ?? this.status, error: error ?? this.error);
  }

  @override
  List<Object?> get props => [status, error];
}
