import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_reports.dart';
import 'package:frontend/features/reports/data/models/problem_type.dart';
import 'package:frontend/features/reports/data/models/report.dart';
import 'package:frontend/features/reports/data/models/report_status.dart';

/// Card widget used to display a single citizen report.
class ReportCard extends StatelessWidget {
  /// Creates a [ReportCard].
  const ReportCard({
    required this.report,
    required this.isOwner,
    required this.isStaff,
    this.onEdit,
    this.onDelete,
    this.onStatusChange,
    super.key,
  });

  /// The report to display.
  final Report report;

  /// Whether the current user is the owner of this report.
  final bool isOwner;

  /// Whether the current user is a staff member.
  final bool isStaff;

  /// Callback when the edit button is pressed.
  final ValueChanged<Report>? onEdit;

  /// Callback when the delete button is pressed.
  final ValueChanged<Report>? onDelete;

  /// Callback when the status change button is pressed.
  final ValueChanged<Report>? onStatusChange;

  @override
  Widget build(BuildContext context) {
    final authorName =
        '${report.user.firstName} ${report.user.lastName}'.trim();
    final dateStr = _formatDate(report.createdAt);
    final neighborhoodName =
        report.neighborhoodDetail?.name ?? ReportTexts.noNeighborhood;
    final canModify = isOwner || isStaff;
    final isResolved = report.status == ReportStatus.resolved;
    final typeColor = _problemTypeColor(report.problemType);

    return Opacity(
      opacity: isResolved ? 0.55 : 1.0,
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
            // ── Header: colored accent + problem type icon + status ──
            Container(
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.08),
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _problemTypeIcon(report.problemType),
                      size: 20,
                      color: typeColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.problemType.label,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        _StatusBadge(status: report.status),
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
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: AppColors.secondaryText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateStr,
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    Text(
                      report.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 10),
                    // Info rows
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      text: neighborhoodName,
                    ),
                    const SizedBox(height: 6),
                    _InfoRow(
                      icon: Icons.person_outline_rounded,
                      text: authorName.isNotEmpty
                          ? authorName
                          : report.user.username,
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),

            // ── Footer: action buttons ──
            if (canModify)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Row(
                  children: [
                    if (canModify) ...[
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.edit_outlined,
                          label: ReportTexts.edit,
                          color: AppColors.primary,
                          onTap: onEdit != null
                              ? () => onEdit!(report)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.delete_outline_rounded,
                          label: ReportTexts.delete,
                          color: AppColors.error,
                          onTap: onDelete != null
                              ? () => onDelete!(report)
                              : null,
                        ),
                      ),
                    ],
                    if (isStaff) ...[
                      const SizedBox(width: 4),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.sync_outlined,
                          label: ReportTexts.updateStatus,
                          color: AppColors.info,
                          onTap: onStatusChange != null
                              ? () => onStatusChange!(report)
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
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Color _problemTypeColor(ProblemType type) {
    switch (type) {
      case ProblemType.roads:
        return AppColors.warning;
      case ProblemType.lighting:
        return AppColors.info;
      case ProblemType.cleanliness:
        return AppColors.success;
    }
  }

  IconData _problemTypeIcon(ProblemType type) {
    switch (type) {
      case ProblemType.roads:
        return Icons.construction;
      case ProblemType.lighting:
        return Icons.lightbulb_outline;
      case ProblemType.cleanliness:
        return Icons.cleaning_services_outlined;
    }
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
                  height: 1.3,
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

/// Badge displaying the report status.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color get _color {
    switch (status) {
      case ReportStatus.recorded:
        return AppColors.info;
      case ReportStatus.inProgress:
        return AppColors.warning;
      case ReportStatus.resolved:
        return AppColors.success;
    }
  }
}

