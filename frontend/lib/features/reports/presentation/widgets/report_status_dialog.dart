import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_general.dart';
import 'package:frontend/constants/texts/texts_reports.dart';
import 'package:frontend/features/reports/data/models/report.dart';
import 'package:frontend/features/reports/data/models/report_status.dart';

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
    return AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text(ReportTexts.updateStatus)),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            tooltip: ReportTexts.cancel,
          ),
        ],
      ),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<ReportStatus>(
              initialValue: _selectedStatus,
              decoration: const InputDecoration(
                labelText: '${ReportTexts.statusLabel} *',
                border: OutlineInputBorder(),
              ),
              items: ReportStatus.values
                  .map(
                    (status) => DropdownMenuItem<ReportStatus>(
                      value: status,
                      child: Text(status.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  _selectedStatus = value;
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 14,
                  color: AppColors.secondaryText,
                ),
                const SizedBox(width: 6),
                Text(
                  AppTextsGeneral.requiredFieldsHint,
                  style:
                      Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.secondaryText,
                            fontStyle: FontStyle.italic,
                          ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(ReportTexts.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, _selectedStatus.toJson());
          },
          child: const Text(ReportTexts.save),
        ),
      ],
    );
  }
}
