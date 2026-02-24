import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:frontend/features/account/data/models/user.dart';
import 'package:frontend/features/account/data/user_repository.dart';

part 'user_profile_event.dart';
part 'user_profile_state.dart';

/// Bloc pour gérer le profil utilisateur
class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  UserProfileBloc({required IUserRepository repository})
      : _repository = repository,
        super(const UserProfileState.initial()) {
    on<UserProfileLoadRequested>(_onLoadRequested);
    on<UserProfileUpdateRequested>(_onUpdateRequested);
  }

  final IUserRepository _repository;

  Future<void> _onLoadRequested(
    UserProfileLoadRequested event,
    Emitter<UserProfileState> emit,
  ) async {
    emit(const UserProfileState.loading());
    try {
      final user = await _repository.getCurrentUser();
      emit(UserProfileState.loaded(user));
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(UserProfileState.failure(message));
    }
  }

  Future<void> _onUpdateRequested(
    UserProfileUpdateRequested event,
    Emitter<UserProfileState> emit,
  ) async {
    final currentUser = state.user;
    if (currentUser == null) return;
    emit(UserProfileState.updating(currentUser));
    try {
      final updatedUser = await _repository.updateUser(
        userId: event.userId,
        firstName: event.firstName,
        lastName: event.lastName,
        username: event.username,
        email: event.email,
      );
      emit(UserProfileState.loaded(updatedUser, isUpdate: true));
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      emit(UserProfileState.failure(message, user: currentUser, isUpdate: true));
    }
  }
}

