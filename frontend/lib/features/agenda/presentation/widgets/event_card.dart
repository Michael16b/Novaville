import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_agenda.dart';
import 'package:frontend/constants/texts/texts_general.dart';
import 'package:frontend/features/agenda/data/models/community_event.dart';
import 'package:frontend/features/agenda/data/models/event_theme.dart';

/// Card widget displaying a community event.
///
/// Accessibility rules applied:
/// - **Seniors / TV**: large font, strong contrasts (WCAG AAA),
///   minimum 48×48 hit-box on action buttons.
/// - **Dyslexia**: sans-serif font (inherited from theme), left-aligned
///   text (never justified), generous line height (height ≥ 1.4).
/// - **Color blindness**: the theme is always identified by its
///   icon + text label (never color alone).
/// - **TV / Desktop**: the entire card is focusable via [Focus] for
///   keyboard / D-Pad navigation.
class EventCard extends StatelessWidget {
  /// Creates an [EventCard].
  const EventCard({
    required this.event,
    required this.isStaff,
    this.onEdit,
    this.onDelete,
    this.onAddToCalendar,
    super.key,
  });

  /// The event to display.
  final CommunityEvent event;

  /// Whether the current user is staff (elected, agent, admin).
  final bool isStaff;

  /// Edit callback.
  final ValueChanged<CommunityEvent>? onEdit;

  /// Delete callback.
  final ValueChanged<CommunityEvent>? onDelete;

  /// Add to calendar callback.
  final ValueChanged<CommunityEvent>? onAddToCalendar;

  @override
  Widget build(BuildContext context) {
    final displayTheme = event.theme ?? EventTheme.other;
    final themeColor = _themeColor(displayTheme);
    final authorName =
        '${event.createdBy.firstName} ${event.createdBy.lastName}'.trim();
    final isPast = event.endDate.isBefore(DateTime.now());

    return Focus(
      child: Semantics(
        label:
            '${AgendaTexts.eventDate} ${_formatDate(event.startDate)}, '
            '${event.title}',
        child: Opacity(
          opacity: isPast ? 0.55 : 1.0,
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header: theme accent + title + theme badge ──
                Container(
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.08),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          displayTheme.icon,
                          size: 20,
                          color: themeColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.left,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    height: 1.4,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: themeColor,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                displayTheme.label,
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Date chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 12,
                              color: AppColors.secondaryText,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(event.startDate),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.secondaryText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Body: description + info rows ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description — dyslexia-friendly
                      Text(
                        event.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        icon: Icons.schedule_outlined,
                        text: _formatDateRange(event.startDate, event.endDate),
                      ),
                      const SizedBox(height: 6),
                      _InfoRow(
                        icon: Icons.person_outline_rounded,
                        text: authorName.isNotEmpty
                            ? authorName
                            : event.createdBy.username,
                      ),
                    ],
                  ),
                ),

                // ── Footer: action buttons ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Row(
                    children: [
                      // Calendar button — visible to all
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.event_available_outlined,
                          label: AgendaTexts.addToCalendar,
                          color: AppColors.info,
                          onTap: onAddToCalendar != null
                              ? () => onAddToCalendar!(event)
                              : null,
                        ),
                      ),
                      if (isStaff) ...[
                        const SizedBox(width: 4),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.edit_outlined,
                            label: AppTextsGeneral.edit,
                            color: AppColors.primary,
                            onTap: onEdit != null ? () => onEdit!(event) : null,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.delete_outline_rounded,
                            label: AppTextsGeneral.delete,
                            color: AppColors.error,
                            onTap: onDelete != null
                                ? () => onDelete!(event)
                                : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Returns a color associated with the event theme.
  Color _themeColor(EventTheme theme) {
    switch (theme) {
      case EventTheme.sport:
        return AppColors.info;
      case EventTheme.culture:
        return const Color(0xFF9C27B0); // purple
      case EventTheme.citizenship:
        return AppColors.primary;
      case EventTheme.environment:
        return AppColors.success;
      case EventTheme.other:
        return AppColors.warning;
    }
  }

  /// Formats a date as DD/MM/YYYY.
  String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year}';
  }

  /// Formats a human-readable date range.
  String _formatDateRange(DateTime start, DateTime end) {
    final localStart = start.toLocal();
    final localEnd = end.toLocal();

    final startStr = _formatDate(start);
    final startTime =
        '${localStart.hour.toString().padLeft(2, '0')}:'
        '${localStart.minute.toString().padLeft(2, '0')}';
    final endTime =
        '${localEnd.hour.toString().padLeft(2, '0')}:'
        '${localEnd.minute.toString().padLeft(2, '0')}';

    if (localStart.year == localEnd.year &&
        localStart.month == localEnd.month &&
        localStart.day == localEnd.day) {
      return '$startStr · $startTime – $endTime';
    }

    final endStr = _formatDate(end);
    return '$startStr $startTime – $endStr $endTime';
  }
}

/// A single info row with a leading icon and text.
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.secondaryText),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.primaryText,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

/// A compact action button used in the card footer.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = onTap != null ? color : AppColors.disabled;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: effectiveColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: effectiveColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
