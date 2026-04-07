import 'package:flutter/material.dart';
import 'package:frontend/core/validation_patterns.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_general.dart';
import 'package:frontend/constants/texts/texts_reports.dart';
import 'package:frontend/features/reports/data/models/problem_type.dart';
import 'package:frontend/features/reports/data/models/report.dart';
import 'package:frontend/ui/widgets/styled_dialog.dart';

/// Dialog for creating or editing a report.
class ReportFormDialog extends StatefulWidget {
  /// Creates a [ReportFormDialog].
  const ReportFormDialog({this.report, super.key});

  /// Report to edit (null for creation).
  final Report? report;

  @override
  State<ReportFormDialog> createState() => _ReportFormDialogState();
}

class _ReportFormDialogState extends State<ReportFormDialog> {
  static final RegExp _exactAddressPattern = RegExp(
    r'^\s*\d{1,5}(?:\s?(?:bis|ter|quater|[A-Za-z]))?\s+'
    r'(?:rue|avenue|av\.?|boulevard|bd\.?|chemin|impasse|allee|all[ée]e|route|'
    r'place|quai|square|cours|esplanade|faubourg|sentier|sente)\s+'
    r"[A-Za-zÀ-ÿ0-9'’., -]{2,}\s*$",
    caseSensitive: false,
  );

  static final RegExp _exactAddressPattern = RegExp(
    r'^\s*\d{1,5}(?:\s?(?:bis|ter|quater|[A-Za-z]))?\s+'
    r'(?:rue|avenue|av\.?|boulevard|bd\.?|chemin|impasse|allee|all[ée]e|route|'
    r'place|quai|square|cours|esplanade|faubourg|sentier|sente)\s+'
    r"[A-Za-zÀ-ÿ0-9'’., -]{2,}\s*$",
    caseSensitive: false,
  );

  final _formKey = GlobalKey<FormState>();
  ProblemType? _selectedProblemType;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;

  bool get _isEditing => widget.report != null;

  @override
  void initState() {
    super.initState();
    _selectedProblemType = widget.report?.problemType;
    _titleController = TextEditingController(text: widget.report?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.report?.description ?? '',
    );
    _addressController = TextEditingController(
      text: widget.report?.address ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing
        ? ReportTexts.editReport
        : ReportTexts.createReport;
    final actionLabel = _isEditing
        ? AppTextsGeneral.save
        : AppTextsGeneral.create;

    return StyledDialog(
      title: title,
      icon: _isEditing ? Icons.edit_outlined : Icons.add_circle_outline,
      closeTooltip: AppTextsGeneral.cancel,
      maxWidth: 500,
      actions: [
        StyledDialog.cancelButton(
          label: AppTextsGeneral.cancel,
          onPressed: () => Navigator.pop(context),
        ),
        StyledDialog.primaryButton(
          label: actionLabel,
          icon: _isEditing ? Icons.check : Icons.send_outlined,
          onPressed: _onSubmit,
        ),
      ],
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLabel('${ReportTexts.problemTypeLabel} *'),
            DropdownButtonFormField<ProblemType>(
              initialValue: _selectedProblemType,
              isExpanded: true,
              menuMaxHeight: 300,
              borderRadius: BorderRadius.circular(12),
              decoration: InputDecoration(
                hintText: ReportTexts.selectProblemType,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              items: ProblemType.values
                  .map(
                    (type) => DropdownMenuItem<ProblemType>(
                      value: type,
                      child: Row(
                        children: [
                          Icon(
                            _problemTypeIcon(type),
                            size: 18,
                            color: _problemTypeColor(type),
                          ),
                          const SizedBox(width: 8),
                          Text(type.label),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedProblemType = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return ReportTexts.problemTypeRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            _buildLabel('${ReportTexts.titleLabel} *'),
            TextFormField(
              controller: _titleController,
              maxLength: 255,
              decoration: InputDecoration(
                hintText: ReportTexts.titleLabel,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return ReportTexts.titleRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            _buildLabel('${ReportTexts.descriptionLabel} *'),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: ReportTexts.descriptionHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(14),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return ReportTexts.descriptionRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            _buildLabel('${ReportTexts.addressLabel} *'),
            TextFormField(
              controller: _addressController,
              maxLength: 255,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: ReportTexts.addressHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) {
                  return ReportTexts.addressRequired;
                }
                if (!ValidationPatterns.exactAddress.hasMatch(trimmed)) {
                  return ReportTexts.addressInvalid;
                }
                return null;
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
                Expanded(
                  child: Text(
                    AppTextsGeneral.requiredFieldsHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.secondaryText,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.secondaryText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
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

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(context, {
      'title': _titleController.text.trim(),
      'problem_type': _selectedProblemType!.toJson(),
      'description': _descriptionController.text.trim(),
      'address': _addressController.text.trim(),
      'neighborhood': widget.report?.neighborhoodId,
    });
  }
}
