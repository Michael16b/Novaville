import 'package:flutter/material.dart';
import 'package:frontend/constants/texts/texts_reports.dart';
import 'package:frontend/features/reports/data/models/neighborhood.dart';
import 'package:frontend/features/reports/data/models/problem_type.dart';
import 'package:frontend/features/reports/data/models/report.dart';

/// Dialog for creating or editing a report.
class ReportFormDialog extends StatefulWidget {
  /// Creates a [ReportFormDialog].
  const ReportFormDialog({
    required this.neighborhoods,
    this.report,
    super.key,
  });

  /// Available neighborhoods.
  final List<Neighborhood> neighborhoods;

  /// Report to edit (null for creation).
  final Report? report;

  @override
  State<ReportFormDialog> createState() => _ReportFormDialogState();
}

class _ReportFormDialogState extends State<ReportFormDialog> {
  final _formKey = GlobalKey<FormState>();
  ProblemType? _selectedProblemType;
  int? _selectedNeighborhood;
  late final TextEditingController _descriptionController;

  bool get _isEditing => widget.report != null;

  @override
  void initState() {
    super.initState();
    _selectedProblemType = widget.report?.problemType;

    // Ensure the neighborhood ID exists in the available list,
    // otherwise reset to null to avoid DropdownButton assertion.
    final reportNeighborhoodId = widget.report?.neighborhoodId;
    final neighborhoodIds =
        widget.neighborhoods.map((n) => n.id).toSet();
    _selectedNeighborhood =
        (reportNeighborhoodId != null &&
                neighborhoodIds.contains(reportNeighborhoodId))
            ? reportNeighborhoodId
            : null;

    _descriptionController = TextEditingController(
      text: widget.report?.description ?? '',
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing
        ? ReportTexts.editReport
        : ReportTexts.createReport;
    final actionLabel =
        _isEditing ? ReportTexts.save : ReportTexts.create;

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 450,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Problem type dropdown
                DropdownButtonFormField<ProblemType>(
                  initialValue: _selectedProblemType,
                  decoration: const InputDecoration(
                    labelText: ReportTexts.problemTypeLabel,
                    border: OutlineInputBorder(),
                  ),
                  items: ProblemType.values
                      .map(
                        (type) => DropdownMenuItem<ProblemType>(
                          value: type,
                          child: Text(type.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    _selectedProblemType = value;
                  },
                  validator: (value) {
                    if (value == null) {
                      return ReportTexts.problemTypeRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: ReportTexts.descriptionLabel,
                    hintText: ReportTexts.descriptionHint,
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return ReportTexts.descriptionRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Neighborhood dropdown
                DropdownButtonFormField<int?>(
                  initialValue: _selectedNeighborhood,
                  decoration: const InputDecoration(
                    labelText: ReportTexts.neighborhoodLabel,
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      child: Text(
                        ReportTexts.selectNeighborhood,
                      ),
                    ),
                    ...widget.neighborhoods.map(
                      (n) => DropdownMenuItem<int?>(
                        value: n.id,
                        child: Text(n.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    _selectedNeighborhood = value;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(ReportTexts.cancel),
        ),
        ElevatedButton(
          onPressed: _onSubmit,
          child: Text(actionLabel),
        ),
      ],
    );
  }

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final result = {
      'problem_type': _selectedProblemType!.toJson(),
      'description': _descriptionController.text.trim(),
      if (_selectedNeighborhood != null)
        'neighborhood': _selectedNeighborhood,
    };

    Navigator.pop(context, result);
  }
}
