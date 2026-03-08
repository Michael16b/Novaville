import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_general.dart';
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
  late final TextEditingController _titleController;
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

    _titleController = TextEditingController(
      text: widget.report?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.report?.description ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
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
    const accentColor = AppColors.primary;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isEditing
                          ? Icons.edit_outlined
                          : Icons.add_circle_outline,
                      size: 22,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context)
                          .textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: ReportTexts.cancel,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      minimumSize: const Size(36, 36),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),

            // ── Form body ──
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Problem type
                      Text(
                        '${ReportTexts.problemTypeLabel} *',
                        style: Theme.of(context)
                            .textTheme.bodySmall
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondaryText,
                            ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<ProblemType>(
                        value: _selectedProblemType,
                        decoration: InputDecoration(
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

                      // Title
                      Text(
                        '${ReportTexts.titleLabel} *',
                        style: Theme.of(context)
                            .textTheme.bodySmall
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondaryText,
                            ),
                      ),
                      const SizedBox(height: 6),
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

                      // Description
                      Text(
                        '${ReportTexts.descriptionLabel} *',
                        style: Theme.of(context)
                            .textTheme.bodySmall
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondaryText,
                            ),
                      ),
                      const SizedBox(height: 6),
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

                      // Neighborhood
                      Text(
                        '${ReportTexts.neighborhoodLabel} *',
                        style: Theme.of(context)
                            .textTheme.bodySmall
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondaryText,
                            ),
                      ),
                      const SizedBox(height: 6),
                      _NeighborhoodAutocompleteField(
                        neighborhoods: widget.neighborhoods,
                        initialNeighborhoodId: _selectedNeighborhood,
                        onChanged: (value) {
                          _selectedNeighborhood = value;
                        },
                        validator: (value) {
                          if (value == null) {
                            return ReportTexts.neighborhoodRequired;
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      // Required fields hint
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryText
                                  .withValues(alpha: 0.1),
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
                            style: Theme.of(context)
                                .textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.secondaryText,
                                  fontStyle: FontStyle.italic,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Footer actions ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        ReportTexts.cancel,
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _onSubmit,
                      icon: Icon(
                        _isEditing ? Icons.check : Icons.send_outlined,
                        size: 18,
                      ),
                      label: Text(actionLabel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

    final result = {
      'title': _titleController.text.trim(),
      'problem_type': _selectedProblemType!.toJson(),
      'description': _descriptionController.text.trim(),
      'neighborhood': _selectedNeighborhood!,
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
    this.validator,
  });

  final List<Neighborhood> neighborhoods;
  final int? initialNeighborhoodId;
  final ValueChanged<int?> onChanged;
  final String? Function(int?)? validator;

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
          validator: (_) => widget.validator?.call(_selectedId),
          decoration: InputDecoration(
            hintText: ReportTexts.selectNeighborhood,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
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
            borderRadius: BorderRadius.circular(12),
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
