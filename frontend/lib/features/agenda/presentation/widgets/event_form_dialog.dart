import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_agenda.dart';
import 'package:frontend/constants/texts/texts_general.dart';
import 'package:frontend/features/agenda/data/models/community_event.dart';
import 'package:frontend/features/agenda/data/models/event_theme.dart';
import 'package:frontend/ui/widgets/styled_dialog.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';

/// Dialog for creating / editing an event.
///
/// Uses [OmniDateTimePicker] for a clean date+time selection.
///
/// Accessibility:
/// - Fields with explicit labels (not placeholder-only).
/// - Large font, strong contrasts.
/// - Buttons with hit-box ≥ 48×48.
class EventFormDialog extends StatefulWidget {
  /// Creates an [EventFormDialog].
  /// If [event] is provided, the form is in edit mode.
  const EventFormDialog({super.key, this.event});

  /// Event to edit (null = creation mode).
  final CommunityEvent? event;

  @override
  State<EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<EventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  DateTime? _startDate;
  DateTime? _endDate;
  EventTheme? _selectedTheme;

  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.event?.description ?? '',
    );
    _startDate = widget.event?.startDate;
    _endDate = widget.event?.endDate;
    _selectedTheme = widget.event?.theme;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEditing ? AgendaTexts.editEvent : AgendaTexts.createEvent;
    final actionLabel = _isEditing
        ? AppTextsGeneral.save
        : AppTextsGeneral.create;

    return StyledDialog(
      title: title,
      icon: _isEditing ? Icons.edit_outlined : Icons.add_circle_outline,
      closeTooltip: AppTextsGeneral.cancel,
      maxWidth: 520,
      actions: [
        StyledDialog.cancelButton(
          label: AppTextsGeneral.cancel,
          onPressed: () => Navigator.pop(context),
        ),
        StyledDialog.primaryButton(
          label: actionLabel,
          icon: _isEditing ? Icons.check : Icons.send_outlined,
          onPressed: _submit,
        ),
      ],
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            _buildLabel(context, '${AgendaTexts.titleLabel} *'),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: AgendaTexts.titleHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AgendaTexts.requiredField;
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            // Description
            _buildLabel(context, '${AgendaTexts.descriptionLabel} *'),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: AgendaTexts.descriptionHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(14),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AgendaTexts.requiredField;
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            // Theme
            _buildLabel(context, '${AgendaTexts.themeLabel} *'),
            DropdownButtonFormField<EventTheme>(
              initialValue: _selectedTheme,
              isExpanded: true,
              menuMaxHeight: 300,
              borderRadius: BorderRadius.circular(12),
              decoration: InputDecoration(
                hintText: AgendaTexts.selectTheme,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              items: EventTheme.values
                  .map(
                    (t) => DropdownMenuItem<EventTheme>(
                      value: t,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(t.icon, size: 18, color: _themeColor(t)),
                          const SizedBox(width: 8),
                          Text(t.label),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              validator: (value) {
                if (value == null) {
                  return AgendaTexts.requiredTheme;
                }
                return null;
              },
              onChanged: (value) => setState(() => _selectedTheme = value),
            ),
            const SizedBox(height: 18),

            // Start date
            _OmniDateTimeFormField(
              label: '${AgendaTexts.startDateLabel} *',
              value: _startDate,
              validator: (date) {
                if (date == null) {
                  return AgendaTexts.requiredStartDate;
                }
                return null;
              },
              onPicked: (date) => setState(() => _startDate = date),
            ),
            const SizedBox(height: 14),

            // End date
            _OmniDateTimeFormField(
              label: '${AgendaTexts.endDateLabel} *',
              value: _endDate,
              firstDate: _startDate,
              validator: (date) {
                if (date == null) {
                  return AgendaTexts.requiredEndDate;
                }
                if (_startDate != null && date.isBefore(_startDate!)) {
                  return AgendaTexts.invalidDate;
                }
                return null;
              },
              onPicked: (date) => setState(() => _endDate = date),
            ),
            const SizedBox(height: 14),

            // Required fields hint
            _RequiredFieldsHint(),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(BuildContext context, String label) {
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

  Color _themeColor(EventTheme theme) {
    switch (theme) {
      case EventTheme.sport:
        return AppColors.info;
      case EventTheme.culture:
        return const Color(0xFF9C27B0);
      case EventTheme.citizenship:
        return AppColors.primary;
      case EventTheme.environment:
        return AppColors.success;
      case EventTheme.other:
        return AppColors.warning;
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(context, <String, dynamic>{
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'start_date': _startDate,
      'end_date': _endDate,
      'theme': _selectedTheme,
    });
  }
}

/// Date and time picker field using [OmniDateTimePicker].
///
/// Wraps a [FormField] so that validation errors are displayed
/// inline, just like [TextFormField] or [DropdownButtonFormField].
///
/// Accessibility:
/// - Seniors: large action button (48×48) with clear text label.
/// - The picker uses the application theme colors.
class _OmniDateTimeFormField extends StatelessWidget {
  const _OmniDateTimeFormField({
    required this.label,
    required this.value,
    required this.onPicked,
    this.firstDate,
    this.validator,
  });

  /// Field label text.
  final String label;

  /// Currently selected date-time value.
  final DateTime? value;

  /// Callback when a date-time is picked.
  final ValueChanged<DateTime> onPicked;

  /// Optional minimum date (e.g. start date for end date field).
  final DateTime? firstDate;

  /// Validator returning an error string if invalid.
  final String? Function(DateTime?)? validator;

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      initialValue: value,
      validator: validator,
      builder: (field) {
        final displayText = value != null ? _formatDateTime(value!) : '';
        final hasError = field.hasError;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLabel(context, label),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _pickDateTime(context, field),
              child: InputDecorator(
                decoration: InputDecoration(
                  errorText: hasError ? field.errorText : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  suffixIcon: const Icon(Icons.calendar_month_outlined),
                ),
                child: value != null
                    ? Text(
                        displayText,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.primaryText,
                        ),
                      )
                    : Text(
                        AgendaTexts.selectDate,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLabel(BuildContext context, String label) {
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

  Future<void> _pickDateTime(
    BuildContext context,
    FormFieldState<DateTime> field,
  ) async {
    final now = DateTime.now();
    final initialDate = value ?? firstDate ?? now;
    final minDate = firstDate ?? now.subtract(const Duration(days: 365));

    final result = await showOmniDateTimePicker(
      context: context,
      initialDate: initialDate,
      firstDate: minDate,
      lastDate: now.add(const Duration(days: 730)),
      is24HourMode: true,
      borderRadius: BorderRadius.circular(12),
      constraints: const BoxConstraints(maxWidth: 350, maxHeight: 650),
    );

    if (result != null) {
      onPicked(result);
      field.didChange(result);
    }
  }

  /// Formats a DateTime as DD/MM/YYYY HH:MM.
  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

/// Required fields hint row.
class _RequiredFieldsHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
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
    );
  }
}
