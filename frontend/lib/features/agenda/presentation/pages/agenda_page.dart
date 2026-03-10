import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_agenda.dart';
import 'package:frontend/constants/texts/texts_general.dart';
import 'package:frontend/design_systems/custom_snack_bar.dart';
import 'package:frontend/features/agenda/application/bloc/agenda_bloc/agenda_bloc.dart';
import 'package:frontend/features/agenda/data/event_repository.dart';
import 'package:frontend/features/agenda/data/event_repository_factory.dart';
import 'package:frontend/features/agenda/data/models/community_event.dart';
import 'package:frontend/features/agenda/data/models/event_theme.dart';
import 'package:frontend/features/agenda/presentation/helpers/calendar_export_helper.dart';
import 'package:frontend/features/agenda/presentation/widgets/calendar_icons/apple_icon.dart';
import 'package:frontend/features/agenda/presentation/widgets/calendar_icons/google_icon.dart';
import 'package:frontend/features/agenda/presentation/widgets/event_card.dart';
import 'package:frontend/features/agenda/presentation/widgets/event_form_dialog.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/ui/widgets/expandable_fab_menu.dart';
import 'package:frontend/ui/widgets/page_header.dart';
import 'package:frontend/ui/widgets/styled_dialog.dart';
import 'package:table_calendar/table_calendar.dart';

/// Participatory agenda page using [TableCalendar].
///
/// Layout:
/// 1. Calendar showing ALL events (past + future) with dot markers.
///    Clicking a day opens a **modal** with the day's event cards.
/// 2. Below the calendar: a **paginated list** of upcoming (future)
///    events only, sorted by start date, following the same pagination
///    pattern as reports_page.dart and user_accounts_page.dart.
///
/// Accessibility:
/// - Large font and strong contrasts (WCAG AAA) — seniors.
/// - Left-aligned text, line height ≥ 1.4 — dyslexia.
/// - Icon + text label for each theme — color blindness.
/// - Cards and buttons are focusable via keyboard / D-Pad — TV / Desktop.
class AgendaPage extends StatelessWidget {
  /// Creates the agenda page.
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
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Upcoming events pagination (client-side)
  static const int _pageSize = 20;
  int _currentPage = 1;
  bool _sortAscending = true;

  // Advanced filters
  EventTheme? _filterTheme;

  String get _currentOrdering => 'start_date';

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _loadingTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }



  DateTime _normalizeDate(DateTime date) {
    final localDate = date.toLocal();
    return DateTime(localDate.year, localDate.month, localDate.day);
  }

  /// Builds a map of ALL events (past + future) grouped by day.
  /// Used by TableCalendar's eventLoader for dot markers.
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

  List<CommunityEvent> _getEventsForDay(
    DateTime day,
    Map<DateTime, List<CommunityEvent>> eventsByDay,
  ) {
    return eventsByDay[_normalizeDate(day)] ?? [];
  }

  /// Filters the full event list to keep only upcoming events
  /// (start_date >= today at midnight), sorted by start_date.
  List<CommunityEvent> _getUpcomingEvents(List<CommunityEvent> all) {
    final now = _normalizeDate(DateTime.now());
    final upcoming = all
        .where((e) => !e.startDate.isBefore(now))
        .toList()
      ..sort((a, b) => _sortAscending
          ? a.startDate.compareTo(b.startDate)
          : b.startDate.compareTo(a.startDate));
    return upcoming;
  }

  /// Material ripple effect on tap (similar to Angular MatRipple).
  Widget _buildRippleDay(
    BuildContext context,
    DateTime day,
    Map<DateTime, List<CommunityEvent>> eventsByDay, {
    required Color textColor,
    BoxDecoration? decoration,
    FontWeight fontWeight = FontWeight.normal,
    double fontSize = 15,
    bool enabled = true,
  }) {
    final dayEvents = _getEventsForDay(day, eventsByDay);
    final hasEvents = dayEvents.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: AppColors.primary.withValues(alpha: 0.3),
          highlightColor: AppColors.primary.withValues(alpha: 0.1),
          onTap: enabled
              ? () {
                  setState(() => _focusedDay = day);
                  _showDayEventsModal(context, day, dayEvents);
                }
              : null,
          child: Container(
            decoration: decoration,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${day.day}',
                  style: TextStyle(
                    color: textColor,
                    fontSize: fontSize,
                    fontWeight: fontWeight,
                  ),
                ),
                if (hasEvents)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      dayEvents.length.clamp(0, 3).toInt(),
                      (_) => Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 0.5),
                        decoration: const BoxDecoration(
                          color: AppColors.calendarMarker,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _buildFab(context),
      body: BlocConsumer<AgendaBloc, AgendaState>(
        listener: _handleStateChanges,
        builder: (context, state) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PageHeader(
                          title: AgendaTexts.title,
                          description: AgendaTexts.titleDescription,
                          icon: Icons.calendar_month,
                        ),
                        const SizedBox(height: 16),
                        _buildControlsSection(context, state),
                        const SizedBox(height: 12),
                        _buildCalendarSection(context, state),
                        const SizedBox(height: 24),
                        _buildUpcomingEventsSection(context, state),
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


  Widget? _buildFab(BuildContext context) {
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


  void _handleStateChanges(BuildContext context, AgendaState state) {
    _handleLoadingOverlay(state);

    switch (state.status) {
      case AgendaStatus.failure:
        CustomSnackBar.showError(
          context,
          state.error ?? AgendaTexts.error,
        );
        break;
      case AgendaStatus.created:
        CustomSnackBar.showSuccess(context, AgendaTexts.createSuccess);
        break;
      case AgendaStatus.deleted:
        CustomSnackBar.showSuccess(context, AgendaTexts.deleteSuccess);
        break;
      case AgendaStatus.updated:
        CustomSnackBar.showSuccess(context, AgendaTexts.updateSuccess);
        break;
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
          setState(() => _showLoadingOverlay = true);
        }
      });
      return;
    }

    _loadingTimer?.cancel();
    _loadingTimer = null;
    if (_showLoadingOverlay && mounted) {
      setState(() => _showLoadingOverlay = false);
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            const SizedBox(height: 12),
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
            _buildThemeFilterChips(),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeFilterChips() {
    final options = <({String label, IconData? icon, EventTheme? value})>[
      (label: AgendaTexts.allThemes, icon: null, value: null),
      ...EventTheme.values
          .map((t) => (label: t.label, icon: t.icon, value: t)),
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
                setState(() {
                  _filterTheme = option.value;
                  _currentPage = 1;
                });
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
      _currentPage = 1;
    });
    _applyFilters();
  }

  // Shows ALL events (past + future) as dot markers.
  // Clicking a day opens a modal dialog listing that day's events.

  Widget _buildCalendarSection(
    BuildContext context,
    AgendaState state,
  ) {
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
          firstDay: DateTime.now().subtract(const Duration(days: 730)),
          lastDay: DateTime.now().add(const Duration(days: 730)),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          startingDayOfWeek: StartingDayOfWeek.monday,
          locale: 'fr_FR',

          // No day selection highlight — day click opens a modal
          selectedDayPredicate: (_) => false,

          eventLoader: (day) => _getEventsForDay(day, eventsByDay),

          // Open modal on day tap
          // Open modal on day tap — handled by custom builders' InkWell.
          // onDaySelected only updates focusedDay for calendar navigation.
          onDaySelected: (selectedDay, focusedDay) {
            setState(() => _focusedDay = focusedDay);
            final dayEvents = _getEventsForDay(selectedDay, eventsByDay);
            _showDayEventsModal(context, selectedDay, dayEvents);
          },

          onPageChanged: (focusedDay) {
            setState(() => _focusedDay = focusedDay);
          },

          onFormatChanged: (format) {
            setState(() => _calendarFormat = format);
          },

          availableCalendarFormats: const {
            CalendarFormat.month: AgendaTexts.formatMonth,
            CalendarFormat.twoWeeks: AgendaTexts.format2Weeks,
            CalendarFormat.week: AgendaTexts.formatWeek,
          },

          calendarBuilders: CalendarBuilders<CommunityEvent>(
            defaultBuilder: (context, day, focusedDay) {
              return _buildRippleDay(
                context, day, eventsByDay,
                textColor: AppColors.primaryText,
              );
            },
            todayBuilder: (context, day, focusedDay) {
              return _buildRippleDay(
                context, day, eventsByDay,
                textColor: AppColors.primaryText,
                decoration: const BoxDecoration(
                  color: AppColors.calendarToday,
                  shape: BoxShape.circle,
                ),
                fontWeight: FontWeight.bold,
              );
            },
            outsideBuilder: (context, day, focusedDay) {
              return _buildRippleDay(
                context, day, eventsByDay,
                textColor: AppColors.calendarOutside,
                fontSize: 14,
              );
            },
            disabledBuilder: (context, day, focusedDay) {
              return _buildRippleDay(
                context, day, eventsByDay,
                textColor: AppColors.calendarOutside.withValues(alpha: 0.5),
                enabled: false,
              );
            },
          ),

          calendarStyle: const CalendarStyle(
            todayDecoration: BoxDecoration(
              color: AppColors.calendarToday,
              shape: BoxShape.circle,
            ),
            todayTextStyle: TextStyle(
              color: AppColors.primaryText,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            selectedDecoration: BoxDecoration(
              color: AppColors.calendarSelected,
              shape: BoxShape.circle,
            ),
            selectedTextStyle: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            defaultTextStyle: TextStyle(
              color: AppColors.primaryText,
              fontSize: 15,
            ),
            weekendTextStyle: TextStyle(
              color: AppColors.calendarWeekend,
              fontSize: 15,
            ),
            outsideTextStyle: TextStyle(
              color: AppColors.calendarOutside,
              fontSize: 14,
            ),
            markerDecoration: BoxDecoration(
              color: AppColors.calendarMarker,
              shape: BoxShape.circle,
            ),
            markerSize: 0,
            markersMaxCount: 0,
            markerMargin: EdgeInsets.zero,
            cellMargin: EdgeInsets.all(4),
          ),

          headerStyle: HeaderStyle(
            titleCentered: true,
            titleTextStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
            formatButtonTextStyle: TextStyle(
              fontSize: 13,
              color: AppColors.primary,
            ),
            formatButtonDecoration: BoxDecoration(
              border: Border.all(color: AppColors.primary),
              borderRadius: BorderRadius.circular(16),
            ),
            leftChevronIcon: Icon(
              Icons.chevron_left,
              color: AppColors.primary,
              size: 28,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right,
              color: AppColors.primary,
              size: 28,
            ),
          ),

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

  // Opens a dialog listing EventCards for the selected day.

  void _showDayEventsModal(
    BuildContext context,
    DateTime day,
    List<CommunityEvent> dayEvents,
  ) {
    final dayStr =
        '${day.day.toString().padLeft(2, '0')}/'
        '${day.month.toString().padLeft(2, '0')}/'
        '${day.year}';

    final currentUser = context.read<AuthBloc>().state.user;
    final isStaff = currentUser?.isStaff ?? false;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StyledDialog(
          title: '${AgendaTexts.eventsOf} $dayStr',
          icon: Icons.event_note,
          closeTooltip: AppTextsGeneral.close,
          maxWidth: 700,
          actions: [
            StyledDialog.cancelButton(
              label: AppTextsGeneral.close,
              onPressed: () => Navigator.pop(dialogContext),
            ),
          ],
          body: dayEvents.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.emptyState
                              .withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.event_busy,
                          size: 36,
                          color: AppColors.emptyState,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AgendaTexts.noEventsOnDay,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(
                              color: AppColors.secondaryText,
                              height: 1.5,
                            ),
                      ),
                    ],
                  ),
                )
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 500),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: dayEvents.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final event = dayEvents[index];
                      return EventCard(
                        event: event,
                        isStaff: isStaff,
                        onEdit: isStaff
                            ? (e) {
                                Navigator.pop(dialogContext);
                                _showEditDialog(context, e);
                              }
                            : null,
                        onDelete: isStaff
                            ? (e) {
                                Navigator.pop(dialogContext);
                                _showDeleteDialog(context, e);
                              }
                            : null,
                        onAddToCalendar: (e) {
                          _handleAddToCalendar(e);
                        },
                      );
                    },
                  ),
                ),
        );
      },
    );
  }

  // ─── Upcoming events section ───────────────────────────────────
  // Paginated list of FUTURE events only (start_date >= today).
  // Follows the same pagination pattern as reports_page.dart:
  // "X-Y sur Z" label + chevron buttons.

  Widget _buildUpcomingEventsSection(
    BuildContext context,
    AgendaState state,
  ) {
    if (state.status == AgendaStatus.initial ||
        state.status == AgendaStatus.loading) {
      return _buildUpcomingEventsSkeleton();
    }

    final upcoming = _getUpcomingEvents(state.events);
    final totalCount = upcoming.length;
    final totalPages =
        (totalCount / _pageSize).ceil().clamp(1, double.infinity).toInt();

    // Ensure current page is within bounds after filter/data changes
    if (_currentPage > totalPages) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentPage = totalPages);
      });
    }

    final startIndex = (_currentPage - 1) * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, totalCount);
    final pageEvents = upcoming.sublist(
      startIndex.clamp(0, totalCount),
      endIndex,
    );

    final currentUser = context.read<AuthBloc>().state.user;
    final isStaff = currentUser?.isStaff ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.upcoming_rounded, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 8),
            Text(
              AgendaTexts.upcomingEvents,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          AgendaTexts.upcomingEventsDescription,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.secondaryText,
                height: 1.4,
              ),
        ),
        const SizedBox(height: 12),

        // Sort + pagination controls
        Card(
          color: AppColors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            child: Row(
              children: [
                // Sort controls (same pattern as reports_page)
                Text(
                  AgendaTexts.sortBy,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text(AgendaTexts.sortByDate),
                  selected: true,
                  onSelected: (_) {},
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                      _currentPage = 1;
                    });
                  },
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
                const Spacer(),
                // Pagination controls (same pattern as reports_page)
                _buildPaginationControls(
                  totalCount: totalCount,
                  pageEventsCount: pageEvents.length,
                  totalPages: totalPages,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Events list or empty state
        if (pageEvents.isEmpty)
          _buildUpcomingEmptyState(context)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pageEvents.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final event = pageEvents[index];
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

  // ─── Pagination controls ───────────────────────────────────────
  // Same pattern as reports_page.dart: "X-Y sur Z" + chevrons.

  Widget _buildPaginationControls({
    required int totalCount,
    required int pageEventsCount,
    required int totalPages,
  }) {
    final start = totalCount == 0 ? 0 : (_currentPage - 1) * _pageSize + 1;
    final end = (start + pageEventsCount - 1).clamp(0, totalCount);
    final hasPrevious = _currentPage > 1;
    final hasNext = _currentPage < totalPages;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$start-$end ${AgendaTexts.on} $totalCount',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: AgendaTexts.previousPage,
          onPressed: hasPrevious
              ? () => setState(() => _currentPage--)
              : null,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: AgendaTexts.nextPage,
          onPressed: hasNext
              ? () => setState(() => _currentPage++)
              : null,
        ),
      ],
    );
  }


  Widget _buildCalendarSkeleton() {
    return Card(
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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

  Widget _buildUpcomingEventsSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 200,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.skeletonDark,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              color: AppColors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 90,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.skeletonDark,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 18,
                      color: AppColors.skeletonDark,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 14,
                      color: AppColors.skeletonLight,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 200,
                      height: 14,
                      color: AppColors.skeletonLight,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 150,
                      height: 14,
                      color: AppColors.skeletonLight,
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

  Widget _buildUpcomingEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(
              Icons.event_busy,
              size: 48,
              color: AppColors.emptyState,
            ),
            const SizedBox(height: 12),
            Text(
              AgendaTexts.noUpcomingEvents,
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


  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
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
            label: const Text(AppTextsGeneral.retry),
          ),
        ],
      ),
    );
  }


  void _flushSearchDebounce() {
    if (_searchDebounce?.isActive ?? false) {
      _searchDebounce!.cancel();
      final nextQuery = _searchController.text.trim();
      if (nextQuery != _searchQuery) {
        setState(() => _searchQuery = nextQuery);
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
          _currentPage = 1;
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
      builder: (dialogContext) => StyledDialog(
        title: AgendaTexts.confirmDeleteTitle,
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
              context.read<AgendaBloc>().add(
                    AgendaEventDeleteRequested(eventId: event.id),
                  );
            },
          ),
        ],
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AgendaTexts.confirmDelete,
              style: Theme.of(dialogContext).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              AgendaTexts.irreversible,
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


  void _handleAddToCalendar(CommunityEvent event) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StyledDialog(
        title: AgendaTexts.chooseCalendar,
        icon: Icons.event_available_outlined,
        accentColor: AppColors.info,
        closeTooltip: AppTextsGeneral.close,
        maxWidth: 400,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Google Calendar option
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                leading: const GoogleCalendarIcon(size: 36),
                title: const Text(
                  AgendaTexts.googleCalendar,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                onTap: () async {
                  Navigator.pop(dialogContext);
                  final success =
                      await CalendarExportHelper.exportToGoogleCalendar(
                    event,
                  );
                  if (!mounted) return;
                  if (success) {
                    CustomSnackBar.showSuccess(
                      context,
                      AgendaTexts.calendarExportSuccess,
                    );
                  } else {
                    CustomSnackBar.showError(
                      context,
                      AgendaTexts.calendarExportError,
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 10),
            // Apple Calendar option (ICS file)
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                leading: const AppleCalendarIcon(size: 36),
                title: const Text(
                  AgendaTexts.appleCalendar,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                onTap: () async {
                  Navigator.pop(dialogContext);
                  final success =
                      await CalendarExportHelper.exportToIcsCalendar(
                    event,
                  );
                  if (!mounted) return;
                  if (success) {
                    CustomSnackBar.showSuccess(
                      context,
                      AgendaTexts.calendarExportSuccess,
                    );
                  } else {
                    CustomSnackBar.showError(
                      context,
                      AgendaTexts.calendarExportError,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
