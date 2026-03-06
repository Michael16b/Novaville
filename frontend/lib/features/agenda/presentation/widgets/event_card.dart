import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_agenda.dart';
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
    final theme = Theme.of(context);

    // TV / Desktop accessibility: Focus for keyboard / D-Pad navigation
    return Focus(
      child: Semantics(
        label: '${AgendaTexts.eventDate} ${_formatDate(event.startDate)}, '
            '${event.title}',
        child: Card(
          elevation: 2,
          child: Padding(
            // Generous spacing comfortable for seniors
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header: theme chip ──
                _ThemeChip(theme: event.theme),
                const SizedBox(height: 10),

                // ── Title ──
                // Dyslexia: left-aligned, large font, no justification
                Text(
                  event.title,
                  textAlign: TextAlign.left,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 6),

                // ── Description ──
                // Dyslexia: line height ≥ 1.5, overflow limited
                // to 3 lines to keep the card compact
                Text(
                  event.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 10),

                // ── Date ──
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppColors.secondaryText,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _formatDateRange(event.startDate, event.endDate),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.secondaryText,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // ── Author ──
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 16,
                      color: AppColors.secondaryText,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${AgendaTexts.createdBy} '
                        '${event.createdBy.firstName} '
                        '${event.createdBy.lastName}'.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.secondaryText,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Actions ──
                const Divider(height: 20),
                _buildActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the action buttons.
  ///
  /// Seniors: minimum 48×48 hit-box (Material default constraint
  /// on TextButton.icon). Clearly labeled buttons.
  Widget _buildActions(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        // "Add to my calendar" button — visible to all users
        // Styled in blue (AppColors.info) to match the info snackbar.
        TextButton.icon(
          onPressed: onAddToCalendar != null
              ? () => onAddToCalendar!(event)
              : null,
          icon: const Icon(
            Icons.event_available,
            size: 18,
            color: AppColors.info,
          ),
          label: const Text(
            AgendaTexts.addToCalendar,
            style: TextStyle(color: AppColors.info),
          ),
        ),

        // Staff buttons: Edit / Delete
        if (isStaff) ...[
          TextButton.icon(
            onPressed: onEdit != null ? () => onEdit!(event) : null,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text(AgendaTexts.edit),
          ),
          TextButton.icon(
            onPressed:
                onDelete != null ? () => onDelete!(event) : null,
            icon: const Icon(
              Icons.delete_outline,
              size: 18,
              color: AppColors.error,
            ),
            label: const Text(
              AgendaTexts.delete,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ],
    );
  }

  /// Formats a date as DD/MM/YYYY.
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  /// Formats a human-readable date range.
  String _formatDateRange(DateTime start, DateTime end) {
    final startStr = _formatDate(start);
    final startTime =
        '${start.hour.toString().padLeft(2, '0')}:'
        '${start.minute.toString().padLeft(2, '0')}';
    final endTime =
        '${end.hour.toString().padLeft(2, '0')}:'
        '${end.minute.toString().padLeft(2, '0')}';

    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return '$startStr · $startTime – $endTime';
    }

    final endStr = _formatDate(end);
    return '$startStr $startTime – $endStr $endTime';
  }
}

/// Chip displaying the theme with icon and label.
///
/// Color-blind accessibility: both the icon AND the text label identify
/// the theme — color is never the sole indicator.
class _ThemeChip extends StatelessWidget {
  const _ThemeChip({this.theme});

  final EventTheme? theme;

  @override
  Widget build(BuildContext context) {
    final displayTheme = theme ?? EventTheme.other;

    return Semantics(
      label: 'Theme: ${displayTheme.label}',
      child: Chip(
        avatar: Icon(displayTheme.icon, size: 18),
        label: Text(
          displayTheme.label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
        ),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

