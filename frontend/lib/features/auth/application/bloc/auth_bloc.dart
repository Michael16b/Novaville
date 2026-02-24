import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:frontend/features/auth/data/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  // The initial state must be 'checking' so that AuthGate shows a loading
  // indicator while AuthStarted verifies the session.
  AuthBloc({required IAuthRepository repository})
    : _repository = repository,
      super(const AuthState.checking()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  final IAuthRepository _repository;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    // Note: emitting 'checking' again is not strictly necessary since it is
    // the initial state, but would be useful if the Bloc could be re-created.
    try {
      final hasSession = await _repository.hasValidSession();
      if (hasSession) {
        emit(const AuthState.authenticated());
      } else {
        // Session is invalid — emit unauthenticated state.
        emit(const AuthState.unauthenticated());
      }
    } catch (e) {
      // On verification error, assume there is no valid session.
      emit(AuthState.failure(e.toString()));
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onLoginSubmitted(
    AuthLoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState.authenticating());
    try {
      await _repository.login(username: event.username, password: event.password);
      emit(const AuthState.authenticated());
    } catch (e) {
      emit(AuthState.failure(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.logout();
    emit(const AuthState.unauthenticated());
  }
}
