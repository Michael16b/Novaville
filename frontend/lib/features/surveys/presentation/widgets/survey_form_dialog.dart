import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_general.dart';
import 'package:frontend/constants/texts/texts_surveys.dart';
import 'package:frontend/features/surveys/data/models/survey.dart';
import 'package:frontend/features/users/data/models/user_role.dart';
import 'package:frontend/ui/widgets/styled_dialog.dart';

/// Dialog used by staff to create surveys.
class SurveyFormDialog extends StatefulWidget {
  /// Creates a [SurveyFormDialog].
  const SurveyFormDialog({this.survey, super.key});

  /// Existing survey when editing.
  final Survey? survey;

  @override
  State<SurveyFormDialog> createState() => _SurveyFormDialogState();
}

class _SurveyFormDialogState extends State<SurveyFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  late final List<TextEditingController> _optionControllers;

  UserRole? _targetRole;
  bool get _isEditing => widget.survey != null;

  @override
  void initState() {
    super.initState();
    final survey = widget.survey;
    _questionController.text = survey?.title ?? '';
    _descriptionController.text = survey?.description ?? '';
    _addressController.text = survey?.address ?? '';
    _targetRole = survey?.citizenTarget;

    if (survey == null) {
      _optionControllers = [TextEditingController(), TextEditingController()];
      return;
    }

    _optionControllers = survey.options.isNotEmpty
        ? survey.options
              .map((option) => TextEditingController(text: option.text))
              .toList()
        : [TextEditingController(), TextEditingController()];
  }

  @override
  void dispose() {
    _questionController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StyledDialog(
      title: _isEditing ? SurveysTexts.editSurvey : SurveysTexts.createSurvey,
      icon: _isEditing ? Icons.edit_outlined : Icons.how_to_vote,
      closeTooltip: AppTextsGeneral.cancel,
      actions: [
        StyledDialog.cancelButton(
          label: AppTextsGeneral.cancel,
          onPressed: () => Navigator.pop(context),
        ),
        StyledDialog.primaryButton(
          label: _isEditing ? AppTextsGeneral.save : AppTextsGeneral.create,
          icon: _isEditing ? Icons.check : Icons.add,
          onPressed: _onSubmit,
        ),
      ],
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldLabel('${SurveysTexts.questionLabel} *'),
            TextFormField(
              controller: _questionController,
              maxLength: 255,
              decoration: InputDecoration(
                hintText: SurveysTexts.questionHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return SurveysTexts.questionRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildFieldLabel('${SurveysTexts.addressLabel} *'),
            TextFormField(
              controller: _addressController,
              maxLength: 255,
              decoration: InputDecoration(
                hintText: SurveysTexts.searchAddressHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return SurveysTexts.addressRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _buildFieldLabel(SurveysTexts.targetLabel),
            DropdownButtonFormField<UserRole?>(
              initialValue: _targetRole,
              isExpanded: true,
              borderRadius: BorderRadius.circular(12),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: [
                const DropdownMenuItem<UserRole?>(
                  child: Text(SurveysTexts.targetAll),
                ),
                ...UserRole.values.map(
                  (role) => DropdownMenuItem<UserRole?>(
                    value: role,
                    child: Text(role.label),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _targetRole = value),
            ),
            const SizedBox(height: 14),
            _buildFieldLabel(SurveysTexts.descriptionLabel),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (!_isEditing) ...[
              _buildFieldLabel('${SurveysTexts.optionsLabel} *'),
              for (
                var index = 0;
                index < _optionControllers.length;
                index++
              ) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _optionControllers[index],
                        decoration: InputDecoration(
                          labelText: '${SurveysTexts.optionLabel} ${index + 1}',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return SurveysTexts.optionRequired;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _optionControllers.length > 2
                          ? () {
                              setState(() {
                                final controller = _optionControllers.removeAt(
                                  index,
                                );
                                controller.dispose();
                              });
                            }
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _optionControllers.add(TextEditingController());
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text(SurveysTexts.addOption),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              AppTextsGeneral.requiredFieldsHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.secondaryText,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
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

  void _onSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final options = _optionControllers
        .map((controller) => controller.text.trim())
        .where((text) => text.isNotEmpty)
        .toSet()
        .toList();

    if (!_isEditing && options.length < 2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(SurveysTexts.minOptions)));
      return;
    }

    Navigator.pop<Map<String, dynamic>>(context, {
      if (_isEditing) 'survey_id': widget.survey!.id,
      'question': _questionController.text.trim(),
      'description': _descriptionController.text.trim(),
      'address': _addressController.text.trim(),
      'citizen_target': _targetRole,
      if (!_isEditing) 'options': options,
    });
  }
}
