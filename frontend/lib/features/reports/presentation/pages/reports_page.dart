import 'dart:async';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_general.dart';
import 'package:frontend/constants/texts/texts_reports.dart';
import 'package:frontend/design_systems/custom_snack_bar.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/features/reports/application/bloc/reports_bloc/reports_bloc.dart';
import 'package:frontend/features/reports/data/models/problem_type.dart';
import 'package:frontend/features/reports/data/models/report.dart';
import 'package:frontend/features/reports/data/models/report_status.dart';
import 'package:frontend/features/reports/data/report_repository.dart';
import 'package:frontend/features/reports/data/report_repository_factory.dart';
import 'package:frontend/features/reports/presentation/widgets/report_card.dart';
import 'package:frontend/ui/widgets/styled_dialog.dart';
import 'package:frontend/features/reports/presentation/widgets/report_form_dialog.dart';
import 'package:frontend/features/reports/presentation/widgets/report_status_dialog.dart';
import 'package:frontend/ui/widgets/expandable_fab_menu.dart';
import 'package:frontend/ui/widgets/neighborhood_autocomplete.dart';
import 'package:frontend/ui/widgets/neighborhood_filter_skeleton.dart';
import 'package:frontend/ui/widgets/page_header.dart';

/// Date filter periods
enum DateFilterPeriod {
  all,
  today,
  last7Days,
  last30Days,
}

/// Reports feature page for citizen reports.
class ReportsPage extends StatelessWidget {
  /// Creates the reports page.
  ///
  /// [reportRepository] can be provided for testing purposes.
  const ReportsPage({super.key, this.reportRepository});

  /// The repository used to fetch report data.
  final IReportRepository? reportRepository;

  @override
  Widget build(BuildContext context) {
    final repository = reportRepository ?? createReportRepository();

    return BlocProvider(
      create: (context) => ReportsBloc(repository: repository)
        ..add(const ReportsLoadRequested(ordering: '-created_at'))
        ..add(const ReportsNeighborhoodsLoadRequested()),
      child: const _ReportsPageContent(),
    );
  }
}

class _ReportsPageContent extends StatefulWidget {
  const _ReportsPageContent();

  @override
  State<_ReportsPageContent> createState() => _ReportsPageContentState();
}

class _ReportsPageContentState extends State<_ReportsPageContent> {
  String _sortColumnKey = 'created_at';
  bool _sortAscending = false;
  int? _preferredCardsPerRow;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  Timer? _loadingTimer;
  String _searchQuery = '';
  bool _showLoadingOverlay = false;

  // Advanced filters
  String? _filterStatus;
  String? _filterProblemType;
  int? _filterNeighborhood;
  DateFilterPeriod _filterDatePeriod = DateFilterPeriod.all;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _loadingTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String get _currentOrdering =>
      _sortAscending ? _sortColumnKey : '-$_sortColumnKey';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: ExpandableFabMenu(
        heroTag: 'reports-fab',
        tooltip: ReportTexts.createReport,
        actions: [
          FabMenuAction(
            label: ReportTexts.createReport,
            icon: Icons.report_outlined,
            onPressed: () => _showCreateDialog(context),
          ),
        ],
      ),
      body: BlocConsumer<ReportsBloc, ReportsState>(
        listener: _handleStateChanges,
        builder: (context, state) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PageHeader(
                      title: ReportTexts.title,
                      description: ReportTexts.titleDescription,
                      icon: Icons.report_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildControlsSection(context, state),
                    const SizedBox(height: 12),
                    _buildResultsSection(context, state),
                  ],
                ),
              ),
              if (_showLoadingOverlay)
                Positioned.fill(
                  child: ColoredBox(
                    color: AppColors.overlay,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _handleStateChanges(BuildContext context, ReportsState state) {
    _handleLoadingOverlay(state);

    switch (state.status) {
      case ReportsStatus.failure:
        CustomSnackBar.showError(
          context,
          state.error ?? ReportTexts.error,
        );
      case ReportsStatus.created:
        CustomSnackBar.showSuccess(context, ReportTexts.createSuccess);
      case ReportsStatus.deleted:
        CustomSnackBar.showSuccess(context, ReportTexts.deleteSuccess);
      case ReportsStatus.updated:
        CustomSnackBar.showSuccess(context, ReportTexts.updateSuccess);
      case ReportsStatus.initial:
      case ReportsStatus.loading:
      case ReportsStatus.loaded:
      case ReportsStatus.creating:
      case ReportsStatus.deleting:
      case ReportsStatus.updating:
        break;
    }
  }

  void _handleLoadingOverlay(ReportsState state) {
    if (state.status == ReportsStatus.loading ||
        state.status == ReportsStatus.creating ||
        state.status == ReportsStatus.deleting ||
        state.status == ReportsStatus.updating) {
      if (_loadingTimer != null || _showLoadingOverlay) return;
      _loadingTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        final latest = context.read<ReportsBloc>().state;
        if (latest.status == ReportsStatus.loading ||
            latest.status == ReportsStatus.creating ||
            latest.status == ReportsStatus.deleting ||
            latest.status == ReportsStatus.updating) {
          setState(() {
            _showLoadingOverlay = true;
          });
        }
      });
      return;
    }

    _loadingTimer?.cancel();
    _loadingTimer = null;
    if (_showLoadingOverlay && mounted) {
      setState(() {
        _showLoadingOverlay = false;
      });
    }
  }

  // ─── Controls Section ──────────────────────────────────────────

  Widget _buildControlsSection(
    BuildContext context,
    ReportsState state,
  ) {
    final sortItems = [
      (label: ReportTexts.sortByDate, key: 'created_at'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: ReportTexts.search,
                hintText: ReportTexts.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                          setState(() {});
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            _buildSortAndLayoutControls(sortItems),
            const SizedBox(height: 10),
            _buildAdvancedFilters(context, state),
            const SizedBox(height: 8),
            _buildPaginationControls(context, state),
          ],
        ),
      ),
    );
  }

  // ─── Advanced Filters ──────────────────────────────────────────

  Widget _buildAdvancedFilters(
    BuildContext context,
    ReportsState state,
  ) {
    final hasActiveFilter = _filterStatus != null ||
        _filterProblemType != null ||
        _filterNeighborhood != null ||
        _filterDatePeriod != DateFilterPeriod.all;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.filter_list,
              size: 18,
              color: AppColors.secondaryText,
            ),
            const SizedBox(width: 6),
            Text(
              ReportTexts.advancedFilters,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(width: 8),
              TextButton.icon(
                onPressed: hasActiveFilter ? _clearAllFilters : null,
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text(ReportTexts.clearFilters),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            _buildFilterChipGroup<String>(
              label: ReportTexts.filterByProblemType,
              selectedValue: _filterProblemType,
              options: [
                (
                  label: ReportTexts.allProblemTypes,
                  value: null,
                ),
                ...ProblemType.values.map(
                  (t) => (label: t.label, value: t.value),
                ),
              ],
              onSelected: (value) {
                setState(() => _filterProblemType = value);
                _applyFilters();
              },
            ),
            _buildFilterChipGroup<String>(
              label: ReportTexts.filterByStatus,
              selectedValue: _filterStatus,
              options: [
                (
                  label: ReportTexts.allStatuses,
                  value: null,
                ),
                ...ReportStatus.values.map(
                  (s) => (label: s.label, value: s.value),
                ),
              ],
              onSelected: (value) {
                setState(() => _filterStatus = value);
                _applyFilters();
              },
            ),
            _buildNeighborhoodFilter(state),
            _buildDateFilter(),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChipGroup<T>({
    required String label,
    required T? selectedValue,
    required List<({String label, T? value})> options,
    required ValueChanged<T?> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: options.map((option) {
            final isSelected = selectedValue == option.value;
            return ChoiceChip(
              label: Text(option.label),
              selected: isSelected,
              onSelected: (_) => onSelected(option.value),
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNeighborhoodFilter(ReportsState state) {
    final neighborhoods = state.neighborhoods;

    // Show skeleton while loading
    if (!state.neighborhoodsLoaded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              ReportTexts.filterByNeighborhood,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(
            width: 250,
            height: 32,
            child: NeighborhoodFilterSkeleton(),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            ReportTexts.filterByNeighborhood,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        SizedBox(
          width: 250,
          child: NeighborhoodAutocomplete(
            neighborhoods: neighborhoods,
            selectedId: _filterNeighborhood,
            hintText: ReportTexts.allNeighborhoods,
            onSelected: (int? value) {
              setState(() => _filterNeighborhood = value);
              _applyFilters();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateFilter() {
    final dateOptions = [
      (label: ReportTexts.allDates, value: DateFilterPeriod.all),
      (label: ReportTexts.today, value: DateFilterPeriod.today),
      (label: ReportTexts.last7Days, value: DateFilterPeriod.last7Days),
      (label: ReportTexts.last30Days, value: DateFilterPeriod.last30Days),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            ReportTexts.filterByDate,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: dateOptions.map((option) {
            final isSelected = _filterDatePeriod == option.value;
            return ChoiceChip(
              label: Text(option.label),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _filterDatePeriod = option.value);
                _applyFilters();
              },
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }

  void _applyFilters() {
    _flushSearchDebounce();
    
    DateTime? createdAfter;
    final now = DateTime.now();
    
    switch (_filterDatePeriod) {
      case DateFilterPeriod.today:
        createdAfter = DateTime(now.year, now.month, now.day);
      case DateFilterPeriod.last7Days:
        createdAfter = now.subtract(const Duration(days: 7));
      case DateFilterPeriod.last30Days:
        createdAfter = now.subtract(const Duration(days: 30));
      case DateFilterPeriod.all:
        createdAfter = null;
    }

    context.read<ReportsBloc>().add(
          ReportsFilterRequested(
            status: _filterStatus,
            problemType: _filterProblemType,
            neighborhood: _filterNeighborhood,
            createdAfter: createdAfter,
            ordering: _currentOrdering,
            search: _searchQuery,
          ),
        );
  }

  void _clearAllFilters() {
    setState(() {
      _filterStatus = null;
      _filterProblemType = null;
      _filterNeighborhood = null;
      _filterDatePeriod = DateFilterPeriod.all;
    });
    _applyFilters();
  }

  Widget _buildSortAndLayoutControls(
    List<({String label, String key})> sortItems,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showCardsPerRowFilter =
            _maxCardsAllowedForWidth(constraints.maxWidth) > 1;

        if (constraints.maxWidth < 900) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSortControlsWrap(sortItems),
              if (showCardsPerRowFilter) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: 220,
                  child: _buildCardsPerRowDropdown(
                    constraints.maxWidth,
                  ),
                ),
              ],
            ],
          );
        }

        if (!showCardsPerRowFilter) {
          return _buildSortControlsWrap(sortItems);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildSortControlsWrap(sortItems)),
            const SizedBox(width: 12),
            SizedBox(
              width: 220,
              child: _buildCardsPerRowDropdown(
                constraints.maxWidth,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSortControlsWrap(
    List<({String label, String key})> sortItems,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          ReportTexts.sortBy,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        for (final sortItem in sortItems)
          ChoiceChip(
            label: Text(sortItem.label),
            selected: _sortColumnKey == sortItem.key,
            onSelected: (_) =>
                _applySort(sortItem.key, _sortAscending),
          ),
        OutlinedButton.icon(
          onPressed: () =>
              _applySort(_sortColumnKey, !_sortAscending),
          icon: Icon(
            _sortAscending
                ? Icons.arrow_upward
                : Icons.arrow_downward,
            size: 16,
          ),
          label: Text(
            _sortAscending
                ? ReportTexts.ascending
                : ReportTexts.descending,
          ),
        ),
      ],
    );
  }

  Widget _buildCardsPerRowDropdown(double width) {
    final maxAllowedCount = _maxCardsAllowedForWidth(width);
    final options = <int?>[
      null,
      for (var count = 1; count <= maxAllowedCount; count++) count,
    ];
    final selectedValue = (_preferredCardsPerRow != null &&
            _preferredCardsPerRow! <= maxAllowedCount)
        ? _preferredCardsPerRow
        : null;

    return DropdownButtonFormField<int?>(
      value: selectedValue,
      isExpanded: true,
      menuMaxHeight: 300,
      borderRadius: BorderRadius.circular(12),
      decoration: const InputDecoration(
        labelText: ReportTexts.cardsPerRow,
        border: OutlineInputBorder(),
      ),
      items: options
          .map(
            (option) => DropdownMenuItem<int?>(
              value: option,
              child: Text(
                option == null
                    ? ReportTexts.auto
                    : option.toString(),
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          _preferredCardsPerRow = value;
        });
      },
    );
  }

  // ─── Pagination ────────────────────────────────────────────────

  Widget _buildPaginationControls(
    BuildContext context,
    ReportsState state,
  ) {
    final start = (state.page - 1) * state.pageSize + 1;
    final end =
        (start + state.reports.length - 1).clamp(0, state.count);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$start-$end ${ReportTexts.on} ${state.count}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: state.previous != null
                ? () {
                    _flushSearchDebounce();
                    context.read<ReportsBloc>().add(
                          ReportsPageRequested(
                            page: state.page - 1,
                            ordering: _currentOrdering,
                            search: _searchQuery,
                          ),
                        );
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: state.next != null
                ? () {
                    _flushSearchDebounce();
                    context.read<ReportsBloc>().add(
                          ReportsPageRequested(
                            page: state.page + 1,
                            ordering: _currentOrdering,
                            search: _searchQuery,
                          ),
                        );
                  }
                : null,
          ),
        ],
      ),
    );
  }

  // ─── Results Section ───────────────────────────────────────────

  Widget _buildResultsSection(
    BuildContext context,
    ReportsState state,
  ) {
    if (state.status == ReportsStatus.initial ||
        state.status == ReportsStatus.loading) {
      return _buildReportsSkeleton(context);
    }

    if (state.status == ReportsStatus.failure &&
        state.reports.isEmpty) {
      return _buildErrorState(
        context,
        state.error ?? ReportTexts.error,
      );
    }

    if (state.reports.isEmpty) {
      return const _EmptyState();
    }

    return _buildReportsGrid(context, state.reports);
  }

  // ─── Grid Layout ──────────────────────────────────────────────

  ({int crossAxisCount, double childAspectRatio}) _computeGridLayout(
    double width,
  ) {
    const spacing = 14.0;
    const minCardWidth = 280.0;
    final maxByWidth = _maxCardsAllowedForWidth(width);

    final estimatedCount =
        ((width + spacing) / (minCardWidth + spacing))
            .floor()
            .clamp(1, maxByWidth);

    final maxAllowedCount = estimatedCount.clamp(1, maxByWidth);

    final chosenCount = _preferredCardsPerRow == null
        ? maxAllowedCount
        : _preferredCardsPerRow!.clamp(1, maxAllowedCount);

    final cardWidth =
        (width - (spacing * (chosenCount - 1))) / chosenCount;
    final estimatedCardHeight = chosenCount == 1
        ? 210.0
        : chosenCount == 2
            ? 230.0
            : 250.0;

    final childAspectRatio =
        (cardWidth / estimatedCardHeight).clamp(0.9, 2.2);

    return (
      crossAxisCount: chosenCount,
      childAspectRatio: childAspectRatio,
    );
  }

  int _maxCardsAllowedForWidth(double width) {
    if (width < 700) return 1;
    if (width < 1000) return 2;
    if (width < 1300) return 3;
    return 3;
  }

  Widget _buildReportsSkeleton(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _computeGridLayout(constraints.maxWidth);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: layout.crossAxisCount * 2,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: layout.crossAxisCount,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: layout.childAspectRatio,
          ),
          itemBuilder: (context, index) {
            return const _ReportCardSkeleton();
          },
        );
      },
    );
  }

  Widget _buildReportsGrid(
    BuildContext context,
    List<Report> reports,
  ) {
    final currentUser = context.read<AuthBloc>().state.user;
    final isStaff = currentUser?.isStaff ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _computeGridLayout(constraints.maxWidth);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reports.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: layout.crossAxisCount,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: layout.childAspectRatio,
          ),
          itemBuilder: (context, index) {
            final report = reports[index];
            final isOwner = report.user.id == currentUser?.id;

            return ReportCard(
              report: report,
              isOwner: isOwner,
              isStaff: isStaff,
              onEdit: (isOwner || isStaff)
                  ? (r) => _showEditDialog(context, r)
                  : null,
              onDelete: (isOwner || isStaff)
                  ? (r) => _showDeleteDialog(context, r)
                  : null,
              onStatusChange: isStaff
                  ? (r) => _showStatusDialog(context, r)
                  : null,
            );
          },
        );
      },
    );
  }

  // ─── Error / Empty states ──────────────────────────────────────

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            ReportTexts.error,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<ReportsBloc>().add(
                    ReportsLoadRequested(
                      ordering: _currentOrdering,
                      search: _searchQuery,
                    ),
                  );
            },
            icon: const Icon(Icons.refresh),
            label: const Text(AppTextsGeneral.retry),
          ),
        ],
      ),
    );
  }

  // ─── Search / Sort helpers ─────────────────────────────────────

  void _flushSearchDebounce() {
    if (_searchDebounce?.isActive ?? false) {
      _searchDebounce!.cancel();
      final nextQuery = _searchController.text.trim();
      if (nextQuery != _searchQuery) {
        setState(() {
          _searchQuery = nextQuery;
        });
      }
    }
  }

  void _applySort(String columnKey, bool ascending) {
    _flushSearchDebounce();
    setState(() {
      _sortColumnKey = columnKey;
      _sortAscending = ascending;
    });
    context.read<ReportsBloc>().add(
          ReportsSortRequested(
            column: columnKey,
            ascending: ascending,
            search: _searchQuery,
          ),
        );
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () {
        if (!mounted) return;
        final nextQuery = value.trim();
        if (nextQuery == _searchQuery) return;
        setState(() {
          _searchQuery = nextQuery;
        });
        context.read<ReportsBloc>().add(
              ReportsSearchRequested(
                query: _searchQuery,
                ordering: _currentOrdering,
              ),
            );
      },
    );
  }

  // ─── Dialogs ───────────────────────────────────────────────────

  Future<void> _showCreateDialog(BuildContext context) async {
    final bloc = context.read<ReportsBloc>();
    final neighborhoods = bloc.state.neighborhoods;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => ReportFormDialog(
        neighborhoods: neighborhoods,
      ),
    );

    if (result != null && mounted) {
      bloc.add(
        ReportCreateRequested(
          title: result['title'] as String,
          problemType: result['problem_type'] as String,
          description: result['description'] as String,
          neighborhood: result['neighborhood'] as int?,
          latitude: result['latitude'] as double?,
          longitude: result['longitude'] as double?,
          address: result['address'] as String?,
          media: result['media'] as List<XFile>,
        ),
      );
    }
  }

  Future<void> _showEditDialog(
    BuildContext context,
    Report report,
  ) async {
    final bloc = context.read<ReportsBloc>();
    final neighborhoods = bloc.state.neighborhoods;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => ReportFormDialog(
        neighborhoods: neighborhoods,
        report: report,
      ),
    );

    if (result != null && mounted) {
      bloc.add(
        ReportUpdateRequested(
          reportId: report.id,
          title: result['title'] as String?,
          problemType: result['problem_type'] as String?,
          description: result['description'] as String?,
          neighborhood: result['neighborhood'] as int?,
          latitude: result['latitude'] as double?,
          longitude: result['longitude'] as double?,
          address: result['address'] as String?,
          media: result['media'] as List<XFile>,
        ),
      );
    }
  }

  void _showDeleteDialog(BuildContext context, Report report) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StyledDialog(
        title: ReportTexts.confirmDeleteTitle,
        icon: Icons.warning_amber_rounded,
        accentColor: AppColors.error,
        closeTooltip: AppTextsGeneral.cancel,
        maxWidth: 420,
        actions: [
          StyledDialog.cancelButton(
            label: AppTextsGeneral.cancel,
            onPressed: () => Navigator.pop(dialogContext),
          ),
          StyledDialog.destructiveButton(
            label: AppTextsGeneral.delete,
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<ReportsBloc>().add(
                    ReportDeleteRequested(reportId: report.id),
                  );
            },
          ),
        ],
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ReportTexts.confirmDelete,
              style: Theme.of(dialogContext).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              ReportTexts.irreversible,
              style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showStatusDialog(
    BuildContext context,
    Report report,
  ) async {
    final bloc = context.read<ReportsBloc>();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) =>
          ReportStatusDialog(report: report),
    );

    if (result != null && mounted) {
      bloc.add(
        ReportStatusUpdateRequested(
          reportId: report.id,
          status: result,
        ),
      );
    }
  }
}

// ─── Empty State ──────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.report_off_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            ReportTexts.noReports,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            ReportTexts.noReportsFound,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────

class _ReportCardSkeleton extends StatefulWidget {
  const _ReportCardSkeleton();

  @override
  State<_ReportCardSkeleton> createState() =>
      _ReportCardSkeletonState();
}

class _ReportCardSkeletonState extends State<_ReportCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseValue = _pulseController.value;
        final barColor = Color.lerp(
          AppColors.secondaryText.withValues(alpha: 0.12),
          AppColors.secondaryText.withValues(alpha: 0.24),
          pulseValue,
        );

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 24,
                      width: 80,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: 24,
                      width: 70,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 14,
                  width: double.infinity,
                  color: barColor,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 14,
                  width: 200,
                  color: barColor,
                ),
                const SizedBox(height: 10),
                Container(
                  height: 12,
                  width: 150,
                  color: barColor,
                ),
                const SizedBox(height: 6),
                Container(
                  height: 12,
                  width: 180,
                  color: barColor,
                ),
                const Spacer(),
                const Divider(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 32,
                        color: barColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 32,
                        color: barColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
