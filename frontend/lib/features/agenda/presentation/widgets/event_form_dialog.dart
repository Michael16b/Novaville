import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_agenda.dart';
import 'package:frontend/constants/texts/texts_general.dart';
import 'package:frontend/features/agenda/data/models/community_event.dart';
import 'package:frontend/features/agenda/data/models/event_theme.dart';
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
    _titleController =
        TextEditingController(text: widget.event?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.event?.description ?? '');
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
    return AlertDialog(
      backgroundColor: AppColors.page,
      title: Row(
        children: [
          Expanded(
            child: Text(
              _isEditing
                  ? AgendaTexts.editEvent
                  : AgendaTexts.createEvent,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            tooltip: AgendaTexts.cancel,
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '${AgendaTexts.titleLabel} *',
                    hintText: AgendaTexts.titleHint,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AgendaTexts.requiredField;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: '${AgendaTexts.descriptionLabel} *',
                    hintText: AgendaTexts.descriptionHint,
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AgendaTexts.requiredField;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Theme — required field, no "none" option
                DropdownButtonFormField<EventTheme>(
                  initialValue: _selectedTheme,
                  decoration: const InputDecoration(
                    labelText: '${AgendaTexts.themeLabel} *',
                  ),
                  items: EventTheme.values
                      .map(
                        (t) => DropdownMenuItem<EventTheme>(
                          value: t,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(t.icon, size: 18),
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
                  onChanged: (value) =>
                      setState(() => _selectedTheme = value),
                ),
                const SizedBox(height: 16),

                // Start date — required, validated inline
                _OmniDateTimeFormField(
                  label: '${AgendaTexts.startDateLabel} *',
                  value: _startDate,
                  validator: (date) {
                    if (date == null) {
                      return AgendaTexts.requiredStartDate;
                    }
                    return null;
                  },
                  onPicked: (date) =>
                      setState(() => _startDate = date),
                ),
                const SizedBox(height: 12),

                // End date — required, validated inline
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
                  onPicked: (date) =>
                      setState(() => _endDate = date),
                ),
                const SizedBox(height: 16),

                // Required fields hint
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
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AgendaTexts.cancel),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(
            _isEditing ? AgendaTexts.save : AgendaTexts.validate,
          ),
        ),
      ],
    );
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
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _pickDateTime(context, field),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: label,
                  suffixIcon: const Icon(Icons.calendar_month_outlined),
                  errorText: hasError ? field.errorText : null,
                ),
                child: Text(
                  displayText,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.primaryText,
                      ),
                ),
              ),
            ),
          ],
        );
      },
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
      type: OmniDateTimePickerType.dateAndTime,
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
