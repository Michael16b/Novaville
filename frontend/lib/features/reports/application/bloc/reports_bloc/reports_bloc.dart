import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/features/reports/data/models/neighborhood.dart';
import 'package:frontend/features/reports/data/models/report.dart';
import 'package:frontend/features/reports/data/report_repository.dart';

part 'reports_event.dart';
part 'reports_state.dart';

/// BLoC for managing citizen reports.
class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  /// Creates a [ReportsBloc].
  ReportsBloc({required IReportRepository repository})
      : _repository = repository,
        super(const ReportsState.initial()) {
    on<ReportsLoadRequested>(_onLoadRequested);
    on<ReportsSearchRequested>(_onSearchRequested);
    on<ReportsSortRequested>(_onSortRequested);
    on<ReportsPageRequested>(_onPageRequested);
    on<ReportsRefreshRequested>(_onRefreshRequested);
    on<ReportCreateRequested>(_onCreateRequested);
    on<ReportDeleteRequested>(_onDeleteRequested);
    on<ReportStatusUpdateRequested>(_onStatusUpdateRequested);
    on<ReportUpdateRequested>(_onUpdateRequested);
    on<ReportsNeighborhoodsLoadRequested>(_onNeighborhoodsLoadRequested);
    on<ReportsFilterRequested>(_onFilterRequested);
  }

  final IReportRepository _repository;
  final Map<_ReportPageCacheKey, _CachedReportPage> _pageCache = {};

  // Current active filters
  String? _filterStatus;
  String? _filterProblemType;
  int? _filterNeighborhood;
  DateTime? _filterCreatedAfter;

  static const Duration _revalidationInterval = Duration(seconds: 20);
  static const Duration _minimumSkeletonDuration =
      Duration(milliseconds: 300);

  int _extractPageNumber(String? previous) {
    if (previous == null) return 1;
    final uri = Uri.tryParse(previous);
    if (uri == null) return 1;
    final prevPage =
        int.tryParse(uri.queryParameters['page'] ?? '1') ?? 1;
    return prevPage + 1;
  }

  Future<void> _onLoadRequested(
    ReportsLoadRequested event,
    Emitter<ReportsState> emit,
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

  Future<void> _onSearchRequested(
    ReportsSearchRequested event,
    Emitter<ReportsState> emit,
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

  Future<void> _onSortRequested(
    ReportsSortRequested event,
    Emitter<ReportsState> emit,
  ) async {
    final ordering =
        event.ascending ? event.column : '-${event.column}';
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
    ReportsPageRequested event,
    Emitter<ReportsState> emit,
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

  Future<void> _onRefreshRequested(
    ReportsRefreshRequested event,
    Emitter<ReportsState> emit,
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

  Future<void> _onFilterRequested(
    ReportsFilterRequested event,
    Emitter<ReportsState> emit,
  ) async {
    _filterProblemType = event.problemType;
    _filterStatus = event.status;
    _filterNeighborhood = event.neighborhood;
    _filterStatus = event.status;
    _filterCreatedAfter = event.createdAfter;
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

  Future<void> _onCreateRequested(
    ReportCreateRequested event,
    Emitter<ReportsState> emit,
  ) async {
    emit(state.copyWith(status: ReportsStatus.creating));
    try {
      await _repository.createReport(
        problemType: event.problemType,
        description: event.description,
        neighborhood: event.neighborhood,
        citizenTarget: event.citizenTarget,
      );
      _pageCache.clear();
      emit(state.copyWith(status: ReportsStatus.created));
      // Reload the current page
      await _loadPageWithCache(
        emit: emit,
        page: 1,
        ordering: null,
        search: state.search,
        forceRefresh: true,
        useInitialLoading: false,
        forceLoadingStateFirst: false,
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ReportsStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onDeleteRequested(
    ReportDeleteRequested event,
    Emitter<ReportsState> emit,
  ) async {
    final currentState = state;
    if (currentState.status != ReportsStatus.loaded) return;

    emit(state.copyWith(status: ReportsStatus.deleting));
    try {
      await _repository.deleteReport(reportId: event.reportId);
      _pageCache.clear();

      final updatedReports = currentState.reports
          .where((r) => r.id != event.reportId)
          .toList();

      emit(
        state.copyWith(
          status: ReportsStatus.deleted,
          reports: updatedReports,
          count: currentState.count - 1,
        ),
      );
      // Reload to get fresh data
      await _loadPageWithCache(
        emit: emit,
        page: currentState.page,
        ordering: null,
        search: currentState.search,
        forceRefresh: true,
        useInitialLoading: false,
        forceLoadingStateFirst: false,
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ReportsStatus.failure,
          error: e.toString(),
        ),
      );
      emit(
        state.copyWith(
          status: ReportsStatus.loaded,
          reports: currentState.reports,
          count: currentState.count,
        ),
      );
    }
  }

  Future<void> _onStatusUpdateRequested(
    ReportStatusUpdateRequested event,
    Emitter<ReportsState> emit,
  ) async {
    emit(state.copyWith(status: ReportsStatus.updating));
    try {
      final updatedReport = await _repository.updateReportStatus(
        reportId: event.reportId,
        status: event.status,
      );
      _pageCache.clear();

      final updatedReports = state.reports
          .map((r) => r.id == updatedReport.id ? updatedReport : r)
          .toList();

      emit(
        state.copyWith(
          status: ReportsStatus.updated,
          reports: updatedReports,
        ),
      );
      emit(state.copyWith(status: ReportsStatus.loaded));
    } catch (e) {
      emit(
        state.copyWith(
          status: ReportsStatus.failure,
          error: e.toString(),
        ),
      );
      emit(state.copyWith(status: ReportsStatus.loaded));
    }
  }

  Future<void> _onUpdateRequested(
    ReportUpdateRequested event,
    Emitter<ReportsState> emit,
  ) async {
    emit(state.copyWith(status: ReportsStatus.updating));
    try {
      final updatedReport = await _repository.updateReport(
        reportId: event.reportId,
        description: event.description,
        neighborhood: event.neighborhood,
        problemType: event.problemType,
        citizenTarget: event.citizenTarget,
      );
      _pageCache.clear();

      final updatedReports = state.reports
          .map((r) => r.id == updatedReport.id ? updatedReport : r)
          .toList();

      emit(
        state.copyWith(
          status: ReportsStatus.updated,
          reports: updatedReports,
        ),
      );
      emit(state.copyWith(status: ReportsStatus.loaded));
    } catch (e) {
      emit(
        state.copyWith(
          status: ReportsStatus.failure,
          error: e.toString(),
        ),
      );
      emit(state.copyWith(status: ReportsStatus.loaded));
    }
  }

  Future<void> _onNeighborhoodsLoadRequested(
    ReportsNeighborhoodsLoadRequested event,
    Emitter<ReportsState> emit,
  ) async {
    try {
      final neighborhoods = await _repository.listNeighborhoods();
      emit(state.copyWith(neighborhoods: neighborhoods));
    } catch (_) {
      // Silently fail – neighborhoods are optional
    }
  }

  Future<void> _loadPageWithCache({
    required Emitter<ReportsState> emit,
    required int page,
    required String? ordering,
    required String search,
    required bool forceRefresh,
    required bool useInitialLoading,
    required bool forceLoadingStateFirst,
  }) async {
    DateTime? loadingStartedAt;
    if (forceLoadingStateFirst) {
      emit(state.copyWith(status: ReportsStatus.loading));
      loadingStartedAt = DateTime.now();
    }

    final key = _ReportPageCacheKey(
      page: page,
      ordering: ordering,
      search: search,
      status: _filterStatus,
      problemType: _filterProblemType,
      neighborhood: _filterNeighborhood,
      createdAfter: _filterCreatedAfter,
    );
    final cached = _pageCache[key];

    if (!forceRefresh && cached != null) {
      try {
        await _waitForMinimumSkeleton(loadingStartedAt);
        _emitLoadedFromPage(emit, cached.pageData, search: search);

        final needsRevalidation = DateTime.now()
                .difference(cached.cachedAt) >=
            _revalidationInterval;
        if (needsRevalidation) {
          try {
            final freshPage = await _repository.listReports(
              ordering: ordering,
              search: search,
              page: page,
              status: _filterStatus,
              problemType: _filterProblemType,
              neighborhood: _filterNeighborhood,
              createdAfter: _filterCreatedAfter,
            );
            _pageCache[key] = _CachedReportPage(
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
      emit(const ReportsState.loading());
    } else if (!forceLoadingStateFirst) {
      emit(state.copyWith(status: ReportsStatus.loading));
    }

    try {
      final reportPage = await _repository.listReports(
        ordering: ordering,
        search: search,
        page: page,
        status: _filterStatus,
        problemType: _filterProblemType,
        neighborhood: _filterNeighborhood,
        createdAfter: _filterCreatedAfter,
      );
      _pageCache[key] = _CachedReportPage(
        pageData: reportPage,
        cachedAt: DateTime.now(),
      );
      await _waitForMinimumSkeleton(loadingStartedAt);
      _emitLoadedFromPage(emit, reportPage, search: search);
    } catch (e) {
      emit(
        state.copyWith(
          status: ReportsStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  void _emitLoadedFromPage(
    Emitter<ReportsState> emit,
    ReportPage reportPage, {
    required String search,
  }) {
    final page = _extractPageNumber(reportPage.previous);
    emit(
      ReportsState.loaded(
        reportPage.results,
        page: page,
        count: reportPage.count,
        next: reportPage.next,
        previous: reportPage.previous,
        search: search,
        neighborhoods: state.neighborhoods,
      ),
    );
  }

  Future<void> _waitForMinimumSkeleton(DateTime? loadingStartedAt) async {
    if (loadingStartedAt == null) return;
    final elapsed = DateTime.now().difference(loadingStartedAt);
    final remaining = _minimumSkeletonDuration - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
  }

  bool _hasPageChanged(ReportPage previousPage, ReportPage nextPage) {
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

class _ReportPageCacheKey extends Equatable {
  const _ReportPageCacheKey({
    required this.page,
    required this.ordering,
    required this.search,
    this.status,
    this.problemType,
    this.neighborhood,
    this.createdAfter,
  });

  final int page;
  final String? ordering;
  final String search;
  final String? status;
  final String? problemType;
  final int? neighborhood;
  final DateTime? createdAfter;

  @override
  List<Object?> get props => [
        page,
        ordering,
        search,
        status,
        problemType,
        neighborhood,
        createdAfter,
      ];
}

class _CachedReportPage {
  const _CachedReportPage({
    required this.pageData,
    required this.cachedAt,
  });

  final ReportPage pageData;
  final DateTime cachedAt;
}
