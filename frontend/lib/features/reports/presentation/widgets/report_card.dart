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

    return Opacity(
      opacity: isResolved ? 0.55 : 1.0,
      child: Card(
        color: isResolved
            ? Theme.of(context).cardColor.withValues(alpha: 0.85)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: problem type chip + status badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProblemTypeChip(problemType: report.problemType),
                  const Spacer(),
                  _StatusBadge(status: report.status),
                ],
              ),
              const SizedBox(height: 10),
              // Title
              if (report.title.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    report.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              // Description
              Text(
                report.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              // Neighborhood
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.secondaryText,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      neighborhoodName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.secondaryText,
                              ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Author + date
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: AppColors.secondaryText,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${ReportTexts.createdBy} $authorName · '
                      '${ReportTexts.createdAt} $dateStr',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.secondaryText,
                              ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (canModify) ...[
                const Divider(height: 20),
                _buildActions(context, canModify),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, bool canModify) {
    final actions = <Widget>[];

    if (canModify) {
      actions
        ..add(
          Expanded(
            child: TextButton.icon(
              onPressed: onEdit != null ? () => onEdit!(report) : null,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text(ReportTexts.edit),
            ),
          ),
        )
        ..add(
          Expanded(
            child: TextButton.icon(
              onPressed:
                  onDelete != null ? () => onDelete!(report) : null,
              icon: const Icon(
                Icons.delete_outline,
                size: 18,
                color: AppColors.error,
              ),
              label: const Text(
                ReportTexts.delete,
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ),
        );
    }

    if (isStaff) {
      actions.add(
        Expanded(
          child: TextButton.icon(
            onPressed:
                onStatusChange != null ? () => onStatusChange!(report) : null,
            icon: const Icon(Icons.sync_outlined, size: 18),
            label: const Text(ReportTexts.updateStatus),
          ),
        ),
      );
    }

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(children: actions);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

/// Chip displaying the problem type with a color.
class _ProblemTypeChip extends StatelessWidget {
  const _ProblemTypeChip({required this.problemType});

  final ProblemType problemType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: AppColors.white),
          const SizedBox(width: 4),
          Text(
            problemType.label,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Color get _color {
    switch (problemType) {
      case ProblemType.roads:
        return AppColors.warning;
      case ProblemType.lighting:
        return AppColors.info;
      case ProblemType.cleanliness:
        return AppColors.success;
    }
  }

  IconData get _icon {
    switch (problemType) {
      case ProblemType.roads:
        return Icons.construction;
      case ProblemType.lighting:
        return Icons.lightbulb_outline;
      case ProblemType.cleanliness:
        return Icons.cleaning_services_outlined;
    }
  }
}

/// Badge displaying the report status with a color.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ReportStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        border: Border.all(color: _color),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: _color,
          fontSize: 11,
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

