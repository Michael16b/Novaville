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
    on<UserAccountsSortRequested>(_onSortRequested);
    on<UserAccountsPageRequested>(_onPageRequested);
  }

  final IUserRepository _repository;

  int _extractPageNumber(String? previous) {
    if (previous == null) return 1;
    final uri = Uri.tryParse(previous);
    if (uri == null) return 1;
    final prevPage = int.tryParse(uri.queryParameters['page'] ?? '1') ?? 1;
    return prevPage + 1;
  }

  Future<void> _onLoadRequested(
    UserAccountsLoadRequested event,
    Emitter<UserAccountsState> emit,
  ) async {
    emit(const UserAccountsState.loading());
    try {
      final userPage = await _repository.listUsers(ordering: event.ordering, page: 1);
      final page = _extractPageNumber(userPage.previous);
      emit(UserAccountsState.loaded(
        userPage.results,
        page: page,
        count: userPage.count,
        next: userPage.next,
        previous: userPage.previous,
        // On garde la taille de page par défaut (20) au lieu d'utiliser la taille de la liste reçue
      ));
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

      final updatedUsers = currentState.users
          .where((user) => user.id != event.userId)
          .toList();

      emit(UserAccountsState.loaded(
        updatedUsers,
        page: currentState.page,
        count: currentState.count - 1,
        next: currentState.next,
        previous: currentState.previous,
        pageSize: currentState.pageSize,
      ));
    } catch (e) {
      emit(UserAccountsState.failure(e.toString()));
      emit(UserAccountsState.loaded(
        currentState.users,
        page: currentState.page,
        count: currentState.count,
        next: currentState.next,
        previous: currentState.previous,
        pageSize: currentState.pageSize,
      ));
    }
  }

  Future<void> _onRefreshRequested(
    UserAccountsRefreshRequested event,
    Emitter<UserAccountsState> emit,
  ) async {
    emit(state.copyWith(status: UserAccountsStatus.loading));
    try {
      final userPage = await _repository.listUsers(page: state.page);
      final page = _extractPageNumber(userPage.previous);
      emit(UserAccountsState.loaded(
        userPage.results,
        page: page,
        count: userPage.count,
        next: userPage.next,
        previous: userPage.previous,
      ));
    } catch (e) {
      emit(UserAccountsState.failure(e.toString()));
    }
  }

  Future<void> _onSortRequested(
    UserAccountsSortRequested event,
    Emitter<UserAccountsState> emit,
  ) async {
    emit(state.copyWith(status: UserAccountsStatus.loading));
    try {
      final ordering = event.ascending ? event.column : '-${event.column}';
      final userPage = await _repository.listUsers(ordering: ordering, page: 1);
      emit(UserAccountsState.loaded(
        userPage.results,
        page: 1,
        count: userPage.count,
        next: userPage.next,
        previous: userPage.previous,
      ));
    } catch (e) {
      emit(state.copyWith(status: UserAccountsStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onPageRequested(
    UserAccountsPageRequested event,
    Emitter<UserAccountsState> emit,
  ) async {
    emit(state.copyWith(status: UserAccountsStatus.loading));
    try {
      final userPage = await _repository.listUsers(ordering: event.ordering, page: event.page);
      final page = _extractPageNumber(userPage.previous);
      emit(UserAccountsState.loaded(
        userPage.results,
        page: page,
        count: userPage.count,
        next: userPage.next,
        previous: userPage.previous,
      ));
    } catch (e) {
      emit(state.copyWith(status: UserAccountsStatus.failure, error: e.toString()));
    }
  }
}
