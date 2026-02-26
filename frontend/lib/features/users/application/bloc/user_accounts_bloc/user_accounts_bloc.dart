import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:frontend/features/users/data/models/user.dart';
import 'package:frontend/features/users/data/user_repository.dart';

part 'user_accounts_event.dart';
part 'user_accounts_state.dart';

/// BLoC for managing user accounts (admin only)
class UserAccountsBloc extends Bloc<UserAccountsEvent, UserAccountsState> {
  UserAccountsBloc({required IUserRepository repository})
      : _repository = repository,
        super(const UserAccountsState.initial()) {
    on<UserAccountsLoadRequested>(_onLoadRequested);
    on<UserAccountsDeleteRequested>(_onDeleteRequested);
    on<UserAccountsRefreshRequested>(_onRefreshRequested);
  }

  final IUserRepository _repository;

  Future<void> _onLoadRequested(
    UserAccountsLoadRequested event,
    Emitter<UserAccountsState> emit,
  ) async {
    emit(const UserAccountsState.loading());
    try {
      final users = await _repository.listUsers();
      emit(UserAccountsState.loaded(users));
    } catch (e) {
      emit(UserAccountsState.failure(e.toString()));
    }
  }

  Future<void> _onDeleteRequested(
    UserAccountsDeleteRequested event,
    Emitter<UserAccountsState> emit,
  ) async {
    final currentState = state;
    if (currentState.status != UserAccountsStatus.loaded) {
      return;
    }

    try {
      await _repository.deleteUser(userId: event.userId);

      // Remove the deleted user from the list
      final updatedUsers = currentState.users
          .where((user) => user.id != event.userId)
          .toList();

      emit(UserAccountsState.loaded(updatedUsers));
    } catch (e) {
      emit(UserAccountsState.failure(e.toString()));
      // Reload the list if deletion failed
      emit(UserAccountsState.loaded(currentState.users));
    }
  }

  Future<void> _onRefreshRequested(
    UserAccountsRefreshRequested event,
    Emitter<UserAccountsState> emit,
  ) async {
    try {
      final users = await _repository.listUsers();
      emit(UserAccountsState.loaded(users));
    } catch (e) {
      emit(UserAccountsState.failure(e.toString()));
    }
  }
}

