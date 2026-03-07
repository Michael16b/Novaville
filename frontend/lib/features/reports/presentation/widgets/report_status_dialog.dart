import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_general.dart';
import 'package:frontend/constants/texts/texts_reports.dart';
import 'package:frontend/features/reports/data/models/report.dart';
import 'package:frontend/features/reports/data/models/report_status.dart';
import 'package:frontend/ui/widgets/styled_dialog.dart';

/// Dialog for staff to change the status of a report.
class ReportStatusDialog extends StatefulWidget {
  /// Creates a [ReportStatusDialog].
  const ReportStatusDialog({required this.report, super.key});

  /// The report whose status will be changed.
  final Report report;

  @override
  State<ReportStatusDialog> createState() => _ReportStatusDialogState();
}

class _ReportStatusDialogState extends State<ReportStatusDialog> {
  late ReportStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.report.status;
  }

  @override
  Widget build(BuildContext context) {
    return StyledDialog(
      title: ReportTexts.updateStatus,
      icon: Icons.sync_outlined,
      closeTooltip: ReportTexts.cancel,
      maxWidth: 420,
      actions: [
        StyledDialog.cancelButton(
          label: ReportTexts.cancel,
          onPressed: () => Navigator.pop(context),
        ),
        StyledDialog.primaryButton(
          label: ReportTexts.save,
          icon: Icons.check,
          onPressed: () {
            Navigator.pop(context, _selectedStatus.toJson());
          },
        ),
      ],
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${ReportTexts.statusLabel} *',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryText,
                ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<ReportStatus>(
            initialValue: _selectedStatus,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            items: ReportStatus.values
                .map(
                  (status) => DropdownMenuItem<ReportStatus>(
                    value: status,
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _statusColor(status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(status.label),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                _selectedStatus = value;
              }
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.secondaryText.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline,
                  size: 12,
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                AppTextsGeneral.requiredFieldsHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.secondaryText,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(ReportStatus status) {
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
