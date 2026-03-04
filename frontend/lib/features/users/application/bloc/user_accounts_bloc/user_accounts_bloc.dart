import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:frontend/features/reports/data/models/neighborhood.dart';
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
    on<UserAccountsFilterRequested>(_onFilterRequested);
    on<UserAccountsNeighborhoodsLoadRequested>(
      _onNeighborhoodsLoadRequested,
    );
  }

  final IUserRepository _repository;
  final Map<_UserPageCacheKey, _CachedUserPage> _pageCache = {};

  // Current active filters
  String? _filterRole;
  int? _filterNeighborhood;

  static const Duration _revalidationInterval = Duration(seconds: 20);
  static const Duration _minimumSkeletonDuration = Duration(milliseconds: 300);

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
      forceLoadingStateFirst: false,
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
      forceLoadingStateFirst: false,
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
      forceLoadingStateFirst: false,
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
      forceLoadingStateFirst: true,
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
      forceLoadingStateFirst: false,
    );
  }

  Future<void> _onFilterRequested(
    UserAccountsFilterRequested event,
    Emitter<UserAccountsState> emit,
  ) async {
    _filterRole = event.role;
    _filterNeighborhood = event.neighborhood;
    _pageCache.clear();
    await _loadPageWithCache(
      emit: emit,
      page: 1,
      ordering: event.ordering,
      search: event.search ?? state.search,
      forceRefresh: true,
      useInitialLoading: false,
      forceLoadingStateFirst: false,
    );
  }

  Future<void> _onNeighborhoodsLoadRequested(
    UserAccountsNeighborhoodsLoadRequested event,
    Emitter<UserAccountsState> emit,
  ) async {
    try {
      final neighborhoods = await _repository.listNeighborhoods();
      emit(state.copyWith(neighborhoods: neighborhoods, neighborhoodsLoaded: true));
    } catch (_) {
      // Silently fail – neighborhoods are optional for filters
      emit(state.copyWith(neighborhoodsLoaded: true));
    }
  }

  Future<void> _loadPageWithCache({
    required Emitter<UserAccountsState> emit,
    required int page,
    required String? ordering,
    required String search,
    required bool forceRefresh,
    required bool useInitialLoading,
    required bool forceLoadingStateFirst,
  }) async {
    DateTime? loadingStartedAt;
    if (forceLoadingStateFirst) {
      emit(state.copyWith(status: UserAccountsStatus.loading, error: null));
      loadingStartedAt = DateTime.now();
    }

    final key = _UserPageCacheKey(
      page: page,
      ordering: ordering,
      search: search,
      role: _filterRole,
      neighborhood: _filterNeighborhood,
    );
    final cached = _pageCache[key];

    if (!forceRefresh && cached != null) {
      try {
        await _waitForMinimumSkeleton(loadingStartedAt);
        _emitLoadedFromPage(emit, cached.pageData, search: search);

        final needsRevalidation =
            DateTime.now().difference(cached.cachedAt) >= _revalidationInterval;
        if (needsRevalidation) {
          try {
            final freshPage = await _repository.listUsers(
              ordering: ordering,
              search: search,
              page: page,
              role: _filterRole,
              neighborhood: _filterNeighborhood,
            );
            _pageCache[key] = _CachedUserPage(
              pageData: freshPage,
              cachedAt: DateTime.now(),
            );
            if (_hasPageChanged(cached.pageData, freshPage)) {
              _emitLoadedFromPage(emit, freshPage, search: search);
            }
          } catch (_) {}
        }
        return;
      } catch (_) {
        _pageCache.remove(key);
      }
    }

    if (useInitialLoading) {
      emit(const UserAccountsState.loading());
    } else if (!forceLoadingStateFirst) {
      emit(state.copyWith(status: UserAccountsStatus.loading, error: null));
    }

    try {
      final userPage = await _repository.listUsers(
        ordering: ordering,
        search: search,
        page: page,
        role: _filterRole,
        neighborhood: _filterNeighborhood,
      );
      _pageCache[key] = _CachedUserPage(
        pageData: userPage,
        cachedAt: DateTime.now(),
      );
      await _waitForMinimumSkeleton(loadingStartedAt);
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
        neighborhoods: state.neighborhoods,
        neighborhoodsLoaded: state.neighborhoodsLoaded,
      ),
    );
  }

  Future<void> _waitForMinimumSkeleton(DateTime? loadingStartedAt) async {
    if (loadingStartedAt == null) {
      return;
    }
    final elapsed = DateTime.now().difference(loadingStartedAt);
    final remaining = _minimumSkeletonDuration - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
  }

  bool _hasPageChanged(UserPage previousPage, UserPage nextPage) {
    if (previousPage.count != nextPage.count ||
        previousPage.next != nextPage.next ||
        previousPage.previous != nextPage.previous ||
        previousPage.results.length != nextPage.results.length) {
      return true;
    }

    for (var index = 0; index < previousPage.results.length; index++) {
      if (previousPage.results[index] != nextPage.results[index]) {
        return true;
      }
    }

    return false;
  }
}

class _UserPageCacheKey extends Equatable {
  const _UserPageCacheKey({
    required this.page,
    required this.ordering,
    required this.search,
    this.role,
    this.neighborhood,
  });

  final int page;
  final String? ordering;
  final String search;
  final String? role;
  final int? neighborhood;

  @override
  List<Object?> get props => [page, ordering, search, role, neighborhood];
}

class _CachedUserPage {
  const _CachedUserPage({required this.pageData, required this.cachedAt});

  final UserPage pageData;
  final DateTime cachedAt;
}
