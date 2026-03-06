import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_agenda.dart';
import 'package:frontend/features/agenda/data/models/community_event.dart';
import 'package:frontend/features/agenda/data/models/event_theme.dart';

/// Dialog for creating / editing an event.
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
      title: Text(
        _isEditing ? AgendaTexts.editEvent : AgendaTexts.createEvent,
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
                    labelText: AgendaTexts.titleLabel,
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
                    labelText: AgendaTexts.descriptionLabel,
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

                // Theme
                DropdownButtonFormField<EventTheme>(
                  initialValue: _selectedTheme,
                  decoration: const InputDecoration(
                    labelText: AgendaTexts.themeLabel,
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
                  onChanged: (value) =>
                      setState(() => _selectedTheme = value),
                ),
                const SizedBox(height: 16),

                // Start date
                _DatePickerField(
                  label: AgendaTexts.startDateLabel,
                  value: _startDate,
                  onPicked: (date) =>
                      setState(() => _startDate = date),
                ),
                const SizedBox(height: 12),

                // End date
                _DatePickerField(
                  label: AgendaTexts.endDateLabel,
                  value: _endDate,
                  onPicked: (date) =>
                      setState(() => _endDate = date),
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

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AgendaTexts.requiredField),
        ),
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AgendaTexts.invalidDate),
        ),
      );
      return;
    }

    Navigator.pop(context, <String, dynamic>{
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'start_date': _startDate!,
      'end_date': _endDate!,
      if (_selectedTheme != null) 'theme': _selectedTheme,
    });
  }
}

/// Date and time picker field.
///
/// Seniors: large action button (48×48) with clear text label.
/// Opens a date picker followed by a time picker to allow
/// selecting both date and hour.
class _DatePickerField extends StatefulWidget {
  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onPicked,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPicked;

  @override
  State<_DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<_DatePickerField> {
  @override
  Widget build(BuildContext context) {
    final displayText = widget.value != null
        ? '${widget.value!.day.toString().padLeft(2, '0')}/'
            '${widget.value!.month.toString().padLeft(2, '0')}/'
            '${widget.value!.year} '
            '${widget.value!.hour.toString().padLeft(2, '0')}:'
            '${widget.value!.minute.toString().padLeft(2, '0')}'
        : '';

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: _pickDateTime,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label,
          suffixIcon: const Icon(Icons.calendar_month_outlined),
        ),
        child: Text(
          displayText,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.primaryText,
              ),
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();

    // Step 1: Pick the date
    final date = await showDatePicker(
      context: context,
      initialDate: widget.value ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;

    // Step 2: Pick the time
    final time = await showTimePicker(
      context: context,
      initialTime: widget.value != null
          ? TimeOfDay.fromDateTime(widget.value!)
          : TimeOfDay.now(),
    );
    if (time == null || !mounted) return;

    widget.onPicked(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }
}
