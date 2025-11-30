import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:frontend/features/auth/data/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  // L'état initial doit être 'checking' pour forcer l'AuthGate à afficher un
  // indicateur de chargement pendant que l'événement AuthStarted vérifie la session.
  AuthBloc({required IAuthRepository repository})
    : _repository = repository,
      super(const AuthState.checking()) {
    // CHANGEMENT: Démarrer en 'checking'
    on<AuthStarted>(_onStarted);
    on<AuthLoginSubmitted>(_onLoginSubmitted);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  final IAuthRepository _repository;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    // Note: Pas besoin d'émettre 'checking' à nouveau si c'est l'état initial,
    // mais si le Bloc pouvait être réinitialisé, cette ligne serait utile.
    // Pour l'instant, on procède directement à la vérification.
    try {
      final hasSession = await _repository.hasValidSession();
      if (hasSession) {
        emit(const AuthState.authenticated());
      } else {
        // Si la session n'est pas valide, émettre l'état non authentifié.
        emit(const AuthState.unauthenticated());
      }
    } catch (e) {
      // En cas d'erreur de vérification, on assume qu'il n'y a pas de session.
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
      await _repository.login(email: event.email, password: event.password);
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
