import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
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
      backgroundColor: AppColors.page, // Force white background
      surfaceTintColor: AppColors.page, // Prevent Material 3 tint
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
                // Neighborhood autocomplete with search
                _NeighborhoodAutocompleteField(
                  neighborhoods: widget.neighborhoods,
                  initialNeighborhoodId: _selectedNeighborhood,
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

// ─── Neighborhood Autocomplete Field ──────────────────────────────

/// Autocomplete field for selecting a neighborhood with search.
class _NeighborhoodAutocompleteField extends StatefulWidget {
  const _NeighborhoodAutocompleteField({
    required this.neighborhoods,
    required this.initialNeighborhoodId,
    required this.onChanged,
  });

  final List<Neighborhood> neighborhoods;
  final int? initialNeighborhoodId;
  final ValueChanged<int?> onChanged;

  @override
  State<_NeighborhoodAutocompleteField> createState() =>
      _NeighborhoodAutocompleteFieldState();
}

class _NeighborhoodAutocompleteFieldState
    extends State<_NeighborhoodAutocompleteField> {
  late TextEditingController _controller;
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialNeighborhoodId;
    _controller = TextEditingController(text: _labelForId(_selectedId));
  }

  @override
  void didUpdateWidget(covariant _NeighborhoodAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialNeighborhoodId != widget.initialNeighborhoodId) {
      _selectedId = widget.initialNeighborhoodId;
      _controller.text = _labelForId(_selectedId);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _labelForId(int? id) {
    if (id == null) return '';
    return widget.neighborhoods
            .where((n) => n.id == id)
            .map((n) => n.name)
            .firstOrNull ??
        '';
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<Neighborhood>(
      displayStringForOption: (n) => n.name,
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.toLowerCase().trim();
        if (query.isEmpty) {
          return widget.neighborhoods;
        }
        return widget.neighborhoods.where(
          (n) => n.name.toLowerCase().contains(query),
        );
      },
      onSelected: (neighborhood) {
        setState(() {
          _selectedId = neighborhood.id;
          _controller.text = neighborhood.name;
        });
        widget.onChanged(neighborhood.id);
        // Fermer le focus pour fermer la dropdown
        Future.microtask(() {
          FocusScope.of(context).unfocus();
        });
      },
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        // Synchronize the controller only when not focused to avoid
        // resetting user input and cursor position while typing.
        if (!focusNode.hasFocus && controller.text != _controller.text) {
          controller.text = _controller.text;
        }

        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: ReportTexts.neighborhoodLabel,
            hintText: ReportTexts.selectNeighborhood,
            border: const OutlineInputBorder(),
            suffixIcon: _selectedId != null
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      setState(() {
                        _selectedId = null;
                        controller.clear();
                        _controller.clear();
                      });
                      widget.onChanged(null);
                    },
                    tooltip: ReportTexts.selectNeighborhood,
                  )
                : const Icon(Icons.arrow_drop_down, size: 20),
          ),
          onTap: () {
            controller.selection = TextSelection(
              baseOffset: 0,
              extentOffset: controller.text.length,
            );
          },
          onFieldSubmitted: (_) => onSubmitted(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            color: AppColors.page, // Force white background for dropdown
            surfaceTintColor: AppColors.page, // Prevent Material 3 tint
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 250,
                minWidth: MediaQuery.of(context).size.width * 0.3,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final neighborhood = options.elementAt(index);
                  final isSelected = neighborhood.id == _selectedId;
                  return ListTile(
                    dense: true,
                    title: Text(neighborhood.name),
                    selected: isSelected,
                    onTap: () => onSelected(neighborhood),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
