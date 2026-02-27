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
    on<UserAccountsSearchRequested>(_onSearchRequested);
  }

  final IUserRepository _repository;
  final Map<_UserPageCacheKey, _CachedUserPage> _pageCache = {};

  static const Duration _revalidationInterval = Duration(seconds: 20);

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
    await _loadPageWithCache(
      emit: emit,
      page: 1,
      ordering: event.ordering,
      search: event.search ?? '',
      forceRefresh: false,
      useInitialLoading: true,
    );
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
      _pageCache.clear();

      final updatedUsers = currentState.users
          .where((user) => user.id != event.userId)
          .toList();

      emit(
        UserAccountsState.loaded(
          updatedUsers,
          page: currentState.page,
          count: currentState.count - 1,
          next: currentState.next,
          previous: currentState.previous,
          pageSize: currentState.pageSize,
          search: currentState.search,
        ),
      );
    } catch (e) {
      emit(UserAccountsState.failure(e.toString()));
      emit(
        UserAccountsState.loaded(
          currentState.users,
          page: currentState.page,
          count: currentState.count,
          next: currentState.next,
          previous: currentState.previous,
          pageSize: currentState.pageSize,
          search: currentState.search,
        ),
      );
    }
  }

  Future<void> _onRefreshRequested(
    UserAccountsRefreshRequested event,
    Emitter<UserAccountsState> emit,
  ) async {
    await _loadPageWithCache(
      emit: emit,
      page: state.page,
      ordering: null,
      search: state.search,
      forceRefresh: true,
      useInitialLoading: false,
    );
  }

  Future<void> _onSortRequested(
    UserAccountsSortRequested event,
    Emitter<UserAccountsState> emit,
  ) async {
    final ordering = event.ascending ? event.column : '-${event.column}';
    await _loadPageWithCache(
      emit: emit,
      page: 1,
      ordering: ordering,
      search: event.search ?? state.search,
      forceRefresh: false,
      useInitialLoading: false,
    );
  }

  Future<void> _onPageRequested(
    UserAccountsPageRequested event,
    Emitter<UserAccountsState> emit,
  ) async {
    await _loadPageWithCache(
      emit: emit,
      page: event.page,
      ordering: event.ordering,
      search: event.search ?? state.search,
      forceRefresh: false,
      useInitialLoading: false,
    );
  }

  Future<void> _onSearchRequested(
    UserAccountsSearchRequested event,
    Emitter<UserAccountsState> emit,
  ) async {
    await _loadPageWithCache(
      emit: emit,
      page: 1,
      ordering: event.ordering,
      search: event.query,
      forceRefresh: false,
      useInitialLoading: false,
    );
  }

  Future<void> _loadPageWithCache({
    required Emitter<UserAccountsState> emit,
    required int page,
    required String? ordering,
    required String search,
    required bool forceRefresh,
    required bool useInitialLoading,
  }) async {
    final key = _UserPageCacheKey(
      page: page,
      ordering: ordering,
      search: search,
    );
    final cached = _pageCache[key];

    if (!forceRefresh && cached != null) {
      try {
        _emitLoadedFromPage(emit, cached.pageData, search: search);

        final needsRevalidation =
            DateTime.now().difference(cached.cachedAt) >= _revalidationInterval;
        if (needsRevalidation) {
          try {
            final freshPage = await _repository.listUsers(
              ordering: ordering,
              search: search,
              page: page,
            );
            _pageCache[key] = _CachedUserPage(
              pageData: freshPage,
              cachedAt: DateTime.now(),
            );
            _emitLoadedFromPage(emit, freshPage, search: search);
          } catch (_) {}
        }
        return;
      } catch (_) {
        _pageCache.remove(key);
      }
    }

    if (useInitialLoading) {
      emit(const UserAccountsState.loading());
    } else {
      emit(state.copyWith(status: UserAccountsStatus.loading, error: null));
    }

    try {
      final userPage = await _repository.listUsers(
        ordering: ordering,
        search: search,
        page: page,
      );
      _pageCache[key] = _CachedUserPage(
        pageData: userPage,
        cachedAt: DateTime.now(),
      );
      _emitLoadedFromPage(emit, userPage, search: search);
    } catch (e) {
      emit(
        state.copyWith(status: UserAccountsStatus.failure, error: e.toString()),
      );
    }
  }

  void _emitLoadedFromPage(
    Emitter<UserAccountsState> emit,
    UserPage userPage, {
    required String search,
  }) {
    final page = _extractPageNumber(userPage.previous);
    emit(
      UserAccountsState.loaded(
        userPage.results,
        page: page,
        count: userPage.count,
        next: userPage.next,
        previous: userPage.previous,
        search: search,
      ),
    );
  }
}

class _UserPageCacheKey extends Equatable {
  const _UserPageCacheKey({
    required this.page,
    required this.ordering,
    required this.search,
  });

  final int page;
  final String? ordering;
  final String search;

  @override
  List<Object?> get props => [page, ordering, search];
}

class _CachedUserPage {
  const _CachedUserPage({required this.pageData, required this.cachedAt});

  final UserPage pageData;
  final DateTime cachedAt;
}
