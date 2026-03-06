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
import 'package:table_calendar/table_calendar.dart';

/// Participatory agenda page using [TableCalendar].
///
/// Responsive UI adapted to all screen sizes:
/// - **Mobile** (< 700px): calendar at full width, event list below.
/// - **Tablet / Desktop / TV** (≥ 700px): constrained max-width (900px)
///   centered to keep the calendar readable.
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
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  Timer? _loadingTimer;
  String _searchQuery = '';
  bool _showLoadingOverlay = false;

  // Calendar state
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Advanced filters
  EventTheme? _filterTheme;

  String get _currentOrdering => 'start_date';

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _loadingTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ─── Utility: normalize a DateTime to date-only (no time) ──────
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // ─── Build a map of events grouped by day ──────────────────────
  // Used by TableCalendar's eventLoader to show markers
  // on days that have events.
  Map<DateTime, List<CommunityEvent>> _buildEventsByDay(
    List<CommunityEvent> events,
  ) {
    final map = <DateTime, List<CommunityEvent>>{};
    for (final event in events) {
      final key = _normalizeDate(event.startDate);
      map.putIfAbsent(key, () => []).add(event);
    }
    return map;
  }

  /// Returns events for a given day from the pre-built map.
  List<CommunityEvent> _getEventsForDay(
    DateTime day,
    Map<DateTime, List<CommunityEvent>> eventsByDay,
  ) {
    return eventsByDay[_normalizeDate(day)] ?? [];
  }

  // ─── Main build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
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
                child: Center(
                  // Responsive: constrain max-width on large screens
                  // to keep the calendar readable.
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
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
                        _buildCalendarSection(context, state),
                        const SizedBox(height: 16),
                        _buildSelectedDayEvents(context, state),
                      ],
                    ),
                  ),
                ),
              ),
              if (_showLoadingOverlay)
                const Positioned.fill(
                  child: ColoredBox(
                    color: AppColors.overlay,
                    child: Center(
                      child: CircularProgressIndicator(),
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

  // ─── Controls section (search, theme filter) ───────────────────

  Widget _buildControlsSection(
    BuildContext context,
    AgendaState state,
  ) {
    final hasActiveFilter = _filterTheme != null;

    return Card(
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search field
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
            const SizedBox(height: 12),

            // Theme filters
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildThemeFilterChips(),
          ],
        ),
      ),
    );
  }

  /// Theme filter chips.
  ///
  /// Color blindness accessibility: each chip displays the EventTheme
  /// icon + text label — color is never the sole indicator.
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

  void _applyFilters() {
    _flushSearchDebounce();

    context.read<AgendaBloc>().add(
          AgendaFilterRequested(
            themeTitle: _filterTheme?.label,
            ordering: _currentOrdering,
            search: _searchQuery,
          ),
        );
  }

  void _clearAllFilters() {
    setState(() {
      _filterTheme = null;
    });
    _applyFilters();
  }

  // ─── Calendar section ──────────────────────────────────────────
  // Uses table_calendar to display events on a month calendar.
  // Event markers (dots) are shown on days that have events.
  // Selecting a day displays the events for that day below.

  Widget _buildCalendarSection(
    BuildContext context,
    AgendaState state,
  ) {
    // Show skeleton while loading
    if (state.status == AgendaStatus.initial ||
        state.status == AgendaStatus.loading) {
      return _buildCalendarSkeleton();
    }

    if (state.status == AgendaStatus.failure && state.events.isEmpty) {
      return _buildErrorState(context, state.error ?? AgendaTexts.error);
    }

    final eventsByDay = _buildEventsByDay(state.events);

    return Card(
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: TableCalendar<CommunityEvent>(
          // Calendar range: 2 years back to 2 years forward
          firstDay: DateTime.now().subtract(const Duration(days: 730)),
          lastDay: DateTime.now().add(const Duration(days: 730)),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          startingDayOfWeek: StartingDayOfWeek.monday,
          locale: 'fr_FR',

          // Selected day highlight
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

          // Event markers on days
          eventLoader: (day) => _getEventsForDay(day, eventsByDay),

          // Day selection callback
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },

          // Page change callback (month navigation)
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
          },

          // Format toggle (month / 2 weeks / week)
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },

          // Calendar format button labels
          availableCalendarFormats: const {
            CalendarFormat.month: AgendaTexts.format2Weeks,
            CalendarFormat.twoWeeks: AgendaTexts.formatWeek,
            CalendarFormat.week: AgendaTexts.formatMonth,
          },

          // ── Styling ──
          // Seniors: large text, strong contrasts (WCAG AAA).
          // Color blindness: markers use secondary color (yellow)
          // combined with dot count as indicator.
          calendarStyle: const CalendarStyle(
            // Today
            todayDecoration: BoxDecoration(
              color: AppColors.calendarToday,
              shape: BoxShape.circle,
            ),
            todayTextStyle: TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            // Selected day
            selectedDecoration: BoxDecoration(
              color: AppColors.calendarSelected,
              shape: BoxShape.circle,
            ),
            selectedTextStyle: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            // Default day
            defaultTextStyle: TextStyle(
              color: AppColors.primaryText,
              fontSize: 15,
            ),
            // Weekend days
            weekendTextStyle: TextStyle(
              color: AppColors.calendarWeekend,
              fontSize: 15,
            ),
            // Days outside current month
            outsideTextStyle: TextStyle(
              color: AppColors.calendarOutside,
              fontSize: 14,
            ),
            // Event markers (dots below the day number)
            markerDecoration: BoxDecoration(
              color: AppColors.calendarMarker,
              shape: BoxShape.circle,
            ),
            markerSize: 7,
            markersMaxCount: 3,
            markerMargin: EdgeInsets.symmetric(horizontal: 1),
            // Cell padding
            cellMargin: EdgeInsets.all(4),
          ),

          // Header styling
          headerStyle: HeaderStyle(
            titleCentered: true,
            titleTextStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
            formatButtonTextStyle: const TextStyle(
              fontSize: 13,
              color: AppColors.primary,
            ),
            formatButtonDecoration: BoxDecoration(
              border: Border.all(color: AppColors.primary),
              borderRadius: BorderRadius.circular(16),
            ),
            leftChevronIcon: const Icon(
              Icons.chevron_left,
              color: AppColors.primary,
              size: 28,
            ),
            rightChevronIcon: const Icon(
              Icons.chevron_right,
              color: AppColors.primary,
              size: 28,
            ),
          ),

          // Day-of-week header
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            weekendStyle: TextStyle(
              color: AppColors.calendarWeekend,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Events for selected day ───────────────────────────────────
  // Displays a list of EventCards for the currently selected day.

  Widget _buildSelectedDayEvents(
    BuildContext context,
    AgendaState state,
  ) {
    if (state.status == AgendaStatus.initial ||
        state.status == AgendaStatus.loading) {
      return _buildEventListSkeleton();
    }

    if (_selectedDay == null) {
      return const SizedBox.shrink();
    }

    final eventsByDay = _buildEventsByDay(state.events);
    final dayEvents = _getEventsForDay(_selectedDay!, eventsByDay);

    final currentUser = context.read<AuthBloc>().state.user;
    final isStaff = currentUser?.isStaff ?? false;

    // Header with selected day info
    final dayStr =
        '${_selectedDay!.day.toString().padLeft(2, '0')}/'
        '${_selectedDay!.month.toString().padLeft(2, '0')}/'
        '${_selectedDay!.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              const Icon(
                Icons.event_note,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  dayEvents.isEmpty
                      ? '${AgendaTexts.noEventsOnDay} ($dayStr)'
                      : '${dayEvents.length} ${AgendaTexts.eventsOnDay}'
                          ' $dayStr',
                  style:
                      Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Event cards list
        if (dayEvents.isEmpty)
          const _EmptyDayState()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dayEvents.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final event = dayEvents[index];
              return EventCard(
                event: event,
                isStaff: isStaff,
                onEdit: isStaff
                    ? (e) => _showEditDialog(context, e)
                    : null,
                onDelete: isStaff
                    ? (e) => _showDeleteDialog(context, e)
                    : null,
                onAddToCalendar: _handleAddToCalendar,
              );
            },
          ),
      ],
    );
  }

  // ─── Calendar skeleton (loading placeholder) ───────────────────

  Widget _buildCalendarSkeleton() {
    return Card(
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppColors.skeletonDark,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 160,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.skeletonDark,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppColors.skeletonDark,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Days of week header skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                7,
                (_) => Container(
                  width: 30,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.skeletonLight,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Calendar grid skeleton (5 rows × 7 days)
            ...List.generate(
              5,
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(
                    7,
                    (col) => Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: (row + col) % 3 == 0
                            ? AppColors.skeletonDark
                            : AppColors.skeletonLight,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Event list skeleton shown below the calendar during loading.
  Widget _buildEventListSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header skeleton
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            width: 200,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.skeletonDark,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // 2 card skeletons
        ...List.generate(
          2,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              color: AppColors.white,
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
                    const SizedBox(height: 12),
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
            ),
          ),
        ),
      ],
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

  // ─── Search helpers ────────────────────────────────────────────

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
        backgroundColor: AppColors.page,
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
// Empty state for selected day (no events)
// ─────────────────────────────────────────────────────────────────

class _EmptyDayState extends StatelessWidget {
  const _EmptyDayState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        // Seniors: generous spacing
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.event_busy,
              size: 48,
              color: AppColors.emptyState,
            ),
            const SizedBox(height: 12),
            Text(
              AgendaTexts.noEventsOnDay,
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

