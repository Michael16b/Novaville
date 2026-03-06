import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_agenda.dart';
import 'package:frontend/design_systems/custom_snack_bar.dart';
import 'package:frontend/features/agenda/application/bloc/agenda_bloc/agenda_bloc.dart';
import 'package:frontend/features/agenda/data/event_repository.dart';
import 'package:frontend/features/agenda/data/event_repository_factory.dart';
import 'package:frontend/features/agenda/data/models/community_event.dart';
import 'package:frontend/features/agenda/data/models/event_theme.dart';
import 'package:frontend/features/agenda/presentation/widgets/event_card.dart';
import 'package:frontend/features/agenda/presentation/widgets/event_form_dialog.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/ui/widgets/expandable_fab_menu.dart';
import 'package:frontend/ui/widgets/page_header.dart';

/// Date filter periods for the agenda.
enum AgendaDateFilter {
  /// All dates.
  all,

  /// Today.
  today,

  /// Next 7 days.
  next7Days,

  /// Next 30 days.
  next30Days,
}

/// Participatory agenda page.
///
/// Responsive UI adapted to all screen sizes:
/// - **Mobile** (< 700px): single-column list.
/// - **Tablet** (700–1000px): 2-column grid.
/// - **Desktop / Web** (1000–1600px): 3-column grid.
/// - **TV / Ultra-wide** (> 1600px): 4-column grid with
///   capped max-width to prevent overly stretched cards.
///
/// Accessibility:
/// - Large font and strong contrasts (WCAG AAA) — seniors.
/// - Left-aligned text, line height ≥ 1.4 — dyslexia.
/// - Icon + text label for each theme — color blindness.
/// - Cards and buttons are focusable via keyboard / D-Pad — TV / Desktop.
class AgendaPage extends StatelessWidget {
  /// Creates the agenda page.
  ///
  /// [eventRepository] can be provided for testing purposes.
  const AgendaPage({super.key, this.eventRepository});

  /// Repository used to fetch event data.
  final IEventRepository? eventRepository;

  @override
  Widget build(BuildContext context) {
    final repository = eventRepository ?? createEventRepository();

    return BlocProvider(
      create: (context) => AgendaBloc(repository: repository)
        ..add(const AgendaLoadRequested(ordering: 'start_date')),
      child: const _AgendaPageContent(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Internal page content
// ─────────────────────────────────────────────────────────────────

class _AgendaPageContent extends StatefulWidget {
  const _AgendaPageContent();

  @override
  State<_AgendaPageContent> createState() => _AgendaPageContentState();
}

class _AgendaPageContentState extends State<_AgendaPageContent> {
  String _sortColumnKey = 'start_date';
  bool _sortAscending = true;
  int? _preferredCardsPerRow;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  Timer? _loadingTimer;
  String _searchQuery = '';
  bool _showLoadingOverlay = false;

  // Advanced filters
  EventTheme? _filterTheme;
  AgendaDateFilter _filterDatePeriod = AgendaDateFilter.all;

  String get _currentOrdering =>
      _sortAscending ? _sortColumnKey : '-$_sortColumnKey';

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _loadingTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ─── Main build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // FAB identical to user_accounts_page.dart and reports_page.dart:
      // same placement (endFloat), same ExpandableFabMenu widget,
      // same expansion behavior.
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _buildFab(context),
      body: BlocConsumer<AgendaBloc, AgendaState>(
        listener: _handleStateChanges,
        builder: (context, state) {
          return Stack(
            children: [
              SingleChildScrollView(
                // Bottom padding of 100 to prevent content from being
                // hidden behind the FAB — seniors accessibility.
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const PageHeader(
                      title: AgendaTexts.title,
                      description: AgendaTexts.titleDescription,
                      icon: Icons.calendar_month,
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

  // ─── FAB ───────────────────────────────────────────────────────
  // Replicates the exact same placement, behavior and logic
  // as user_accounts_page.dart and reports_page.dart:
  // ExpandableFabMenu positioned at endFloat.

  Widget? _buildFab(BuildContext context) {
    // Only staff can create events
    final currentUser = context.read<AuthBloc>().state.user;
    final isStaff = currentUser?.isStaff ?? false;
    if (!isStaff) return null;

    return ExpandableFabMenu(
      heroTag: 'agenda-fab',
      tooltip: AgendaTexts.addActionsTooltip,
      actions: [
        FabMenuAction(
          label: AgendaTexts.createEvent,
          icon: Icons.event,
          onPressed: () => _showCreateDialog(context),
        ),
      ],
    );
  }

  // ─── State listener ────────────────────────────────────────────

  void _handleStateChanges(BuildContext context, AgendaState state) {
    _handleLoadingOverlay(state);

    switch (state.status) {
      case AgendaStatus.failure:
        CustomSnackBar.showError(
          context,
          state.error ?? AgendaTexts.error,
        );
      case AgendaStatus.created:
        CustomSnackBar.showSuccess(context, AgendaTexts.createSuccess);
      case AgendaStatus.deleted:
        CustomSnackBar.showSuccess(context, AgendaTexts.deleteSuccess);
      case AgendaStatus.updated:
        CustomSnackBar.showSuccess(context, AgendaTexts.updateSuccess);
      case AgendaStatus.initial:
      case AgendaStatus.loading:
      case AgendaStatus.loaded:
      case AgendaStatus.creating:
      case AgendaStatus.deleting:
      case AgendaStatus.updating:
        break;
    }
  }

  void _handleLoadingOverlay(AgendaState state) {
    if (state.status == AgendaStatus.loading ||
        state.status == AgendaStatus.creating ||
        state.status == AgendaStatus.deleting ||
        state.status == AgendaStatus.updating) {
      if (_loadingTimer != null || _showLoadingOverlay) return;
      _loadingTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        final latest = context.read<AgendaBloc>().state;
        if (latest.status == AgendaStatus.loading ||
            latest.status == AgendaStatus.creating ||
            latest.status == AgendaStatus.deleting ||
            latest.status == AgendaStatus.updating) {
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

  // ─── Controls section (search, sort, filters) ──────────────────

  Widget _buildControlsSection(
    BuildContext context,
    AgendaState state,
  ) {
    final sortItems = [
      (label: AgendaTexts.sortByDate, key: 'start_date'),
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
                labelText: AgendaTexts.search,
                hintText: AgendaTexts.searchHint,
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
            _buildAdvancedFilters(context),
            const SizedBox(height: 8),
            _buildPaginationControls(context, state),
          ],
        ),
      ),
    );
  }

  // ─── Advanced filters ──────────────────────────────────────────
  // Horizontally scrollable filter strip (Wrap):
  // theme and date period. Each filter displays icon + label
  // (color-blind accessibility).

  Widget _buildAdvancedFilters(BuildContext context) {
    final hasActiveFilter =
        _filterTheme != null || _filterDatePeriod != AgendaDateFilter.all;

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
              AgendaTexts.advancedFilters,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: hasActiveFilter ? _clearAllFilters : null,
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text(AgendaTexts.clearFilters),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Filters wrapped for adaptive scrolling
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: [
            _buildThemeFilterChips(),
            _buildDateFilter(),
          ],
        ),
      ],
    );
  }

  /// Theme filter chips.
  ///
  /// Color blindness: each chip displays the EventTheme icon + text
  /// label — color is never the sole indicator.
  Widget _buildThemeFilterChips() {
    final options = <({String label, IconData? icon, EventTheme? value})>[
      (
        label: AgendaTexts.allThemes,
        icon: null,
        value: null,
      ),
      ...EventTheme.values.map(
        (t) => (label: t.label, icon: t.icon, value: t),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            AgendaTexts.filterByTheme,
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
            final isSelected = _filterTheme == option.value;
            return ChoiceChip(
              avatar: option.icon != null
                  ? Icon(option.icon, size: 16)
                  : null,
              showCheckmark: false,
              label: Text(option.label),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _filterTheme = option.value);
                _applyFilters();
              },
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateFilter() {
    final dateOptions = [
      (label: AgendaTexts.allDates, value: AgendaDateFilter.all),
      (label: AgendaTexts.today, value: AgendaDateFilter.today),
      (label: AgendaTexts.next7Days, value: AgendaDateFilter.next7Days),
      (label: AgendaTexts.next30Days, value: AgendaDateFilter.next30Days),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            AgendaTexts.filterByDate,
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

    DateTime? startDateGte;
    final now = DateTime.now();

    switch (_filterDatePeriod) {
      case AgendaDateFilter.today:
        startDateGte = DateTime(now.year, now.month, now.day);
      case AgendaDateFilter.next7Days:
        startDateGte = DateTime(now.year, now.month, now.day);
      case AgendaDateFilter.next30Days:
        startDateGte = DateTime(now.year, now.month, now.day);
      case AgendaDateFilter.all:
        startDateGte = null;
    }

    context.read<AgendaBloc>().add(
          AgendaFilterRequested(
            themeTitle: _filterTheme?.label,
            startDateGte: startDateGte,
            ordering: _currentOrdering,
            search: _searchQuery,
          ),
        );
  }

  void _clearAllFilters() {
    setState(() {
      _filterTheme = null;
      _filterDatePeriod = AgendaDateFilter.all;
    });
    _applyFilters();
  }

  // ─── Sort and layout ───────────────────────────────────────────

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
          AgendaTexts.sortBy,
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
                ? AgendaTexts.ascending
                : AgendaTexts.descending,
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
      initialValue: selectedValue,
      decoration: const InputDecoration(
        labelText: AgendaTexts.cardsPerRow,
        border: OutlineInputBorder(),
      ),
      items: options
          .map(
            (option) => DropdownMenuItem<int?>(
              value: option,
              child: Text(
                option == null
                    ? AgendaTexts.auto
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
    AgendaState state,
  ) {
    final start = (state.page - 1) * state.pageSize + 1;
    final end =
        (start + state.events.length - 1).clamp(0, state.count);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$start-$end ${AgendaTexts.on} ${state.count}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous page',
            onPressed: state.previous != null
                ? () {
                    _flushSearchDebounce();
                    context.read<AgendaBloc>().add(
                          AgendaPageRequested(
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
            tooltip: 'Next page',
            onPressed: state.next != null
                ? () {
                    _flushSearchDebounce();
                    context.read<AgendaBloc>().add(
                          AgendaPageRequested(
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

  // ─── Results section ───────────────────────────────────────────

  Widget _buildResultsSection(
    BuildContext context,
    AgendaState state,
  ) {
    if (state.status == AgendaStatus.initial ||
        state.status == AgendaStatus.loading) {
      return _buildEventsSkeleton(context);
    }

    if (state.status == AgendaStatus.failure && state.events.isEmpty) {
      return _buildErrorState(context, state.error ?? AgendaTexts.error);
    }

    if (state.events.isEmpty) {
      return const _EmptyState();
    }

    return _buildEventsGrid(context, state.events);
  }

  // ─── Responsive grid ──────────────────────────────────────────
  // Responsive design:
  // - Mobile (< 700px): 1 column (classic list).
  // - Tablet (700–1000px): 2 columns.
  // - Desktop / Web (1000–1600px): 3 columns.
  // - TV / Ultra-wide (> 1600px): 4 columns, max-width capped.
  //
  // Uses LayoutBuilder to adapt column count to actual available
  // width (not MediaQuery) so it also reacts in split-view or
  // side panels.

  ({int crossAxisCount, double childAspectRatio}) _computeGridLayout(
    double width,
  ) {
    const spacing = 14.0;
    const minCardWidth = 300.0;
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

    // Taller estimated height for event cards
    // (more text content + action buttons)
    final estimatedCardHeight = chosenCount == 1
        ? 260.0
        : chosenCount == 2
            ? 290.0
            : 310.0;

    final childAspectRatio =
        (cardWidth / estimatedCardHeight).clamp(0.8, 2.0);

    return (
      crossAxisCount: chosenCount,
      childAspectRatio: childAspectRatio,
    );
  }

  /// Maximum number of columns allowed by width.
  ///
  /// Responsive breakpoints:
  /// - < 700px → 1 column (mobile).
  /// - 700–1000px → 2 columns (tablet).
  /// - 1000–1600px → 3 columns (desktop / web).
  /// - > 1600px → 4 columns (TV / ultra-wide).
  int _maxCardsAllowedForWidth(double width) {
    if (width < 700) return 1;
    if (width < 1000) return 2;
    if (width < 1600) return 3;
    return 4;
  }

  Widget _buildEventsSkeleton(BuildContext context) {
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
            return const _EventCardSkeleton();
          },
        );
      },
    );
  }

  Widget _buildEventsGrid(
    BuildContext context,
    List<CommunityEvent> events,
  ) {
    final currentUser = context.read<AuthBloc>().state.user;
    final isStaff = currentUser?.isStaff ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _computeGridLayout(constraints.maxWidth);

        // TV / Ultra-wide: cap max content width to prevent
        // overly stretched cards.
        final maxWidth = constraints.maxWidth > 1600
            ? 1600.0
            : constraints.maxWidth;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: layout.crossAxisCount,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: layout.childAspectRatio,
              ),
              itemBuilder: (context, index) {
                final event = events[index];

                return EventCard(
                  event: event,
                  isStaff: isStaff,
                  onEdit: isStaff
                      ? (e) => _showEditDialog(context, e)
                      : null,
                  onDelete: isStaff
                      ? (e) => _showDeleteDialog(context, e)
                      : null,
                  onAddToCalendar: (e) => _handleAddToCalendar(e),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ─── Empty / error states ──────────────────────────────────────

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
            AgendaTexts.error,
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
              context.read<AgendaBloc>().add(
                    AgendaLoadRequested(
                      ordering: _currentOrdering,
                      search: _searchQuery,
                    ),
                  );
            },
            icon: const Icon(Icons.refresh),
            label: const Text(AgendaTexts.retry),
          ),
        ],
      ),
    );
  }

  // ─── Search / sort helpers ─────────────────────────────────────

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
    context.read<AgendaBloc>().add(
          AgendaSortRequested(
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
        context.read<AgendaBloc>().add(
              AgendaSearchRequested(
                query: _searchQuery,
                ordering: _currentOrdering,
              ),
            );
      },
    );
  }

  // ─── CRUD dialogs ──────────────────────────────────────────────

  Future<void> _showCreateDialog(BuildContext context) async {
    final bloc = context.read<AgendaBloc>();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => const EventFormDialog(),
    );

    if (result != null && mounted) {
      final selectedTheme = result['theme'] as EventTheme?;
      bloc.add(
        AgendaEventCreateRequested(
          title: result['title'] as String,
          description: result['description'] as String,
          startDate: result['start_date'] as DateTime,
          endDate: result['end_date'] as DateTime,
          theme: selectedTheme != null
              ? bloc.resolveThemeId(selectedTheme.label)
              : null,
        ),
      );
    }
  }

  Future<void> _showEditDialog(
    BuildContext context,
    CommunityEvent event,
  ) async {
    final bloc = context.read<AgendaBloc>();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => EventFormDialog(event: event),
    );

    if (result != null && mounted) {
      final selectedTheme = result['theme'] as EventTheme?;
      bloc.add(
        AgendaEventUpdateRequested(
          eventId: event.id,
          title: result['title'] as String?,
          description: result['description'] as String?,
          startDate: result['start_date'] as DateTime?,
          endDate: result['end_date'] as DateTime?,
          theme: selectedTheme != null
              ? bloc.resolveThemeId(selectedTheme.label)
              : null,
        ),
      );
    }
  }

  void _showDeleteDialog(BuildContext context, CommunityEvent event) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(AgendaTexts.confirmDeleteTitle),
        content: const Text(
          '${AgendaTexts.confirmDelete}\n\n'
          '${AgendaTexts.irreversible}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(AgendaTexts.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AgendaBloc>().add(
                    AgendaEventDeleteRequested(eventId: event.id),
                  );
            },
            child: const Text(
              AgendaTexts.delete,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Calendar export ───────────────────────────────────────────
  // Displays a confirmation snackbar.
  // For full integration, consider using the `add_2_calendar`
  // or `url_launcher` package for Google Calendar.

  void _handleAddToCalendar(CommunityEvent event) {
    CustomSnackBar.showInfo(
      context,
      '${AgendaTexts.addToCalendar} : ${event.title}',
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Empty state widget
// ─────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        // Seniors: generous spacing
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.event_busy,
              size: 64,
              color: AppColors.secondaryText,
            ),
            const SizedBox(height: 16),
            Text(
              AgendaTexts.noEvents,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primaryText,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              AgendaTexts.noEventsDescription,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.secondaryText,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Card skeleton (shimmer placeholder)
// ─────────────────────────────────────────────────────────────────

class _EventCardSkeleton extends StatelessWidget {
  const _EventCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme chip
            Container(
              width: 90,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.skeletonDark,
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(height: 12),
            // Title
            Container(
              width: double.infinity,
              height: 18,
              color: AppColors.skeletonDark,
            ),
            const SizedBox(height: 8),
            // Description line 1
            Container(
              width: double.infinity,
              height: 14,
              color: AppColors.skeletonLight,
            ),
            const SizedBox(height: 4),
            // Description line 2
            Container(
              width: 200,
              height: 14,
              color: AppColors.skeletonLight,
            ),
            const SizedBox(height: 12),
            // Date
            Container(
              width: 150,
              height: 14,
              color: AppColors.skeletonLight,
            ),
            const Spacer(),
            const Divider(),
            Container(
              width: 120,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.skeletonLight,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
