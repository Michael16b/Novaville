import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_general.dart';
import 'package:frontend/constants/texts/texts_useful_info.dart';

import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/features/useful_info/application/bloc/useful_info_bloc.dart';
import 'package:frontend/features/useful_info/application/bloc/useful_info_event.dart';
import 'package:frontend/features/useful_info/application/bloc/useful_info_state.dart';
import 'package:frontend/features/useful_info/domain/useful_info.dart';

import 'package:frontend/ui/widgets/page_header.dart';

import '../widgets/contact_actions.dart';
import '../widgets/opening_hours_table.dart';
import '../widgets/social_network_actions.dart';

class UsefulInfoPage extends StatefulWidget {
  const UsefulInfoPage({super.key});

  @override
  State<UsefulInfoPage> createState() => _UsefulInfoPageState();
}

class _UsefulInfoPageState extends State<UsefulInfoPage> {
  bool _isEditing = false;

  void _startEditing() {
    setState(() => _isEditing = true);
  }

  void _stopEditing() {
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select<AuthBloc, bool>((bloc) {
      final state = bloc.state;
      if (state.status != AuthStatus.authenticated) return false;
      return state.user?.isGlobalAdmin == true;
    });

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              heroTag: 'useful-info-fab',
              tooltip: _isEditing ? 'Fermer' : UsefulInfoTexts.edit,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              onPressed: () {
                final blocState = context.read<UsefulInfoBloc>().state;
                if (blocState is! UsefulInfoLoaded) return;

                if (_isEditing) {
                  _stopEditing();
                } else {
                  _startEditing();
                }
              },
              child: Icon(_isEditing ? Icons.close : Icons.edit_outlined),
            )
          : null,
      body: BlocListener<UsefulInfoBloc, UsefulInfoState>(
        listener: (context, state) {
          if (state is UsefulInfoLoaded && _isEditing) {
            _stopEditing();
          }

          if (state is UsefulInfoFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: BlocBuilder<UsefulInfoBloc, UsefulInfoState>(
          builder: (context, state) {
            if (state is UsefulInfoInitial) {
              context.read<UsefulInfoBloc>().add(const UsefulInfoRequested());
              return const SizedBox.shrink();
            }

            if (state is UsefulInfoLoading || state is UsefulInfoSaving) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (state is UsefulInfoFailure) {
              return Center(child: Text(state.message));
            }

            if (state is! UsefulInfoLoaded) {
              return const SizedBox.shrink();
            }

            final info = state.info;

            if (_isEditing && isAdmin) {
              return _UsefulInfoEditView(
                info: info,
                onCancel: _stopEditing,
                onSave: (updated) {
                  context.read<UsefulInfoBloc>().add(UsefulInfoSaved(updated));
                },
              );
            }

            if (_isInfoEmpty(info)) {
              return const _EmptyState();
            }

            return _UsefulInfoReadView(info: info);
          },
        ),
      ),
    );
  }
}

class _UsefulInfoReadView extends StatelessWidget {
  final UsefulInfo info;

  const _UsefulInfoReadView({required this.info});

  @override
  Widget build(BuildContext context) {
    final hasSocialNetworks =
        (info.instagram ?? '').trim().isNotEmpty ||
        (info.facebook ?? '').trim().isNotEmpty ||
        (info.x ?? '').trim().isNotEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(
            title: UsefulInfoTexts.title,
            description: UsefulInfoTexts.description,
            icon: Icons.info_outline,
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              _SectionCard(
                title: UsefulInfoTexts.cityHallSection,
                icon: Icons.location_city_outlined,
                child: _CityHallBlock(info: info),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: UsefulInfoTexts.openingHoursSection,
                icon: Icons.schedule_outlined,
                child: OpeningHoursTable(openingHours: info.openingHours),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: UsefulInfoTexts.contactSection,
                icon: Icons.phone_outlined,
                child: ContactActions(
                  phone: info.phone,
                  email: info.email,
                  website: info.website,
                ),
              ),
              if (hasSocialNetworks) ...[
                const SizedBox(height: 12),
                _SectionCard(
                  title: UsefulInfoTexts.reseaux,
                  icon: Icons.share_outlined,
                  child: SocialNetworkActions(
                    instagram: info.instagram,
                    facebook: info.facebook,
                    x: info.x,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _UsefulInfoEditView extends StatefulWidget {
  final UsefulInfo info;
  final ValueChanged<UsefulInfo> onSave;
  final VoidCallback onCancel;

  const _UsefulInfoEditView({
    required this.info,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_UsefulInfoEditView> createState() => _UsefulInfoEditViewState();
}

class _UsefulInfoEditViewState extends State<_UsefulInfoEditView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _postalController;
  late final TextEditingController _cityController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _websiteController;
  late final TextEditingController _instagramController;
  late final TextEditingController _facebookController;
  late final TextEditingController _xController;

  static const List<String> _dayOrder = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];

  late Map<String, List<_TimeRange>> _openingHours;

  @override
  void initState() {
    super.initState();
    final info = widget.info;

    _nameController = TextEditingController(text: info.cityHallName);
    _addressController = TextEditingController(text: info.addressLine1);
    _postalController = TextEditingController(text: info.postalCode);
    _cityController = TextEditingController(text: info.city);
    _phoneController = TextEditingController(text: info.phone ?? '');
    _emailController = TextEditingController(text: info.email ?? '');
    _websiteController = TextEditingController(text: info.website ?? '');
    _instagramController = TextEditingController(text: info.instagram ?? '');
    _facebookController = TextEditingController(text: info.facebook ?? '');
    _xController = TextEditingController(text: info.x ?? '');
    _openingHours = {
      for (final day in _dayOrder)
        day: _parseTimeRanges(widget.info.openingHours[day] ?? []),
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _postalController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    _xController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) return;

    final openingHoursError = _validateOpeningHours();
    if (openingHoursError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(openingHoursError)));
      return;
    }

    final updated = widget.info.copyWith(
      cityHallName: _nameController.text.trim(),
      addressLine1: _addressController.text.trim(),
      postalCode: _postalController.text.trim(),
      city: _cityController.text.trim(),
      phone: _emptyToNull(_phoneController.text),
      email: _emptyToNull(_emailController.text),
      website: _emptyToNull(_websiteController.text),
      instagram: _emptyToNull(_instagramController.text),
      facebook: _emptyToNull(_facebookController.text),
      x: _emptyToNull(_xController.text),
      openingHours: _buildOpeningHoursMap(),
    );

    widget.onSave(updated);
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  List<_TimeRange> _parseTimeRanges(List<String> slots) {
    return slots
        .map((slot) => _TimeRange.tryParse(slot))
        .whereType<_TimeRange>()
        .toList();
  }

  Map<String, List<String>> _buildOpeningHoursMap() {
    return {
      for (final day in _dayOrder)
        day: _openingHours[day]!
            .where((range) => range.isComplete)
            .map((range) => range.toDisplayString())
            .toList(),
    };
  }

  Future<void> _pickTime({
    required String day,
    required int index,
    required bool isStart,
  }) async {
    final currentRange = _openingHours[day]![index];

    final initialTime = isStart
        ? (currentRange.start ?? const TimeOfDay(hour: 8, minute: 0))
        : (currentRange.end ?? const TimeOfDay(hour: 17, minute: 0));

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        currentRange.start = picked;
      } else {
        currentRange.end = picked;
      }
    });
  }

  void _addSlot(String day) {
    setState(() {
      _openingHours[day]!.add(_TimeRange());
    });
  }

  void _removeSlot(String day, int index) {
    setState(() {
      _openingHours[day]!.removeAt(index);
    });
  }

  String? _validateOpeningHours() {
    for (final entry in _openingHours.entries) {
      for (final range in entry.value) {
        if (!range.isComplete) {
          return 'Chaque créneau doit avoir une heure de début et de fin.';
        }

        if (!range.isValid) {
          return 'L’heure de fin doit être après l’heure de début.';
        }
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PageHeader(
              title: UsefulInfoTexts.editTitle,
              description: UsefulInfoTexts.description,
              icon: Icons.edit_outlined,
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: UsefulInfoTexts.cityHallSection,
              icon: Icons.location_city_outlined,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: '${UsefulInfoTexts.nameLabel} *',
                    ),
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: '${UsefulInfoTexts.addressLabel} *',
                    ),
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _postalController,
                    decoration: const InputDecoration(
                      labelText: '${UsefulInfoTexts.postalCodeLabel} *',
                    ),
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: '${UsefulInfoTexts.cityLabel} *',
                    ),
                    validator: _requiredValidator,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: UsefulInfoTexts.openingHoursSection,
              icon: Icons.schedule_outlined,
              child: Column(
                children: _dayOrder.map((day) {
                  final slots = _openingHours[day]!;
                  final isClosed = slots.isEmpty;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                day,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Switch(
                              value: !isClosed,
                              onChanged: (isOpen) {
                                setState(() {
                                  if (isOpen) {
                                    if (_openingHours[day]!.isEmpty) {
                                      _openingHours[day]!.add(_TimeRange());
                                    }
                                  } else {
                                    _openingHours[day] = [];
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        if (isClosed)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text('Fermé'),
                          )
                        else ...[
                          ...List.generate(slots.length, (index) {
                            final slot = slots[index];

                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _pickTime(
                                        day: day,
                                        index: index,
                                        isStart: true,
                                      ),
                                      child: Text(
                                        slot.start != null
                                            ? '${slot.start!.hour.toString().padLeft(2, '0')}:${slot.start!.minute.toString().padLeft(2, '0')}'
                                            : 'Début',
                                      ),
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text('à'),
                                  ),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _pickTime(
                                        day: day,
                                        index: index,
                                        isStart: false,
                                      ),
                                      child: Text(
                                        slot.end != null
                                            ? '${slot.end!.hour.toString().padLeft(2, '0')}:${slot.end!.minute.toString().padLeft(2, '0')}'
                                            : 'Fin',
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _removeSlot(day, index),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => _addSlot(day),
                              icon: const Icon(Icons.add),
                              label: const Text('Ajouter un créneau'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),
            const SizedBox(height: 12),
            _SectionCard(
              title: UsefulInfoTexts.contactSection,
              icon: Icons.phone_outlined,
              child: Column(
                children: [
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: UsefulInfoTexts.phoneLabel.replaceAll(
                        ' :',
                        '',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: UsefulInfoTexts.emailLabel.replaceAll(
                        ' :',
                        '',
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _websiteController,
                    decoration: InputDecoration(
                      labelText: UsefulInfoTexts.websiteLabel.replaceAll(
                        ' :',
                        '',
                      ),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            _SectionCard(
              title: UsefulInfoTexts.reseaux,
              icon: Icons.share_outlined,
              child: Column(
                children: [
                  TextFormField(
                    controller: _instagramController,
                    decoration: const InputDecoration(
                      labelText: UsefulInfoTexts.instagramLabel,
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _facebookController,
                    decoration: const InputDecoration(
                      labelText: UsefulInfoTexts.facebookLabel,
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _xController,
                    decoration: const InputDecoration(
                      labelText: UsefulInfoTexts.xLabel,
                    ),
                    keyboardType: TextInputType.url,
                  ),
                ],
              ),
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
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: widget.onCancel,
                  child: const Text('Annuler'),
                ),

                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _handleSave,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Enregistrer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return UsefulInfoTexts.requiredField;
    }
    return null;
  }
}

bool _isInfoEmpty(UsefulInfo info) {
  final hasContactData =
      (info.phone ?? '').trim().isNotEmpty ||
      (info.email ?? '').trim().isNotEmpty ||
      (info.website ?? '').trim().isNotEmpty;

  final hasAddressData =
      info.cityHallName.trim().isNotEmpty ||
      info.addressLine1.trim().isNotEmpty ||
      (info.addressLine2 ?? '').trim().isNotEmpty ||
      info.postalCode.trim().isNotEmpty ||
      info.city.trim().isNotEmpty;
  final hasSocialData =
      (info.instagram ?? '').trim().isNotEmpty ||
      (info.facebook ?? '').trim().isNotEmpty ||
      (info.x ?? '').trim().isNotEmpty;

  final hasOpeningHours = info.openingHours.entries.any(
    (entry) => entry.value.any((slot) => slot.trim().isNotEmpty),
  );

  final hasAdditionalInfo = (info.additionalInfo ?? '').trim().isNotEmpty;

  return !hasContactData &&
      !hasAddressData &&
      !hasOpeningHours &&
      !hasAdditionalInfo &&
      !hasSocialData;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            UsefulInfoTexts.noUsefulInfo,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            UsefulInfoTexts.noUsefulInfoFound,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Text(
                  title,
                  style:
                      textTheme.titleSmall ??
                      const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DefaultTextStyle.merge(
              style: textTheme.bodyMedium ?? const TextStyle(fontSize: 14),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _CityHallBlock extends StatelessWidget {
  final UsefulInfo info;

  const _CityHallBlock({required this.info});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(info.cityHallName, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        Text(info.addressLine1, style: textStyle),
        if ((info.addressLine2 ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(info.addressLine2!, style: textStyle),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text('${info.postalCode} ${info.city}', style: textStyle),
        ),
      ],
    );
  }
}

class _TimeRange {
  TimeOfDay? start;
  TimeOfDay? end;

  _TimeRange({this.start, this.end});

  bool get isComplete => start != null && end != null;

  bool get isValid {
    if (!isComplete) return false;

    final startMinutes = start!.hour * 60 + start!.minute;
    final endMinutes = end!.hour * 60 + end!.minute;

    return endMinutes > startMinutes;
  }

  String toDisplayString() {
    if (!isComplete) return '';
    return '${_formatTime(start!)} - ${_formatTime(end!)}';
  }

  static _TimeRange? tryParse(String value) {
    final regex = RegExp(r'^\s*(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})\s*$');
    final match = regex.firstMatch(value);

    if (match == null) return null;

    final startHour = int.tryParse(match.group(1)!);
    final startMinute = int.tryParse(match.group(2)!);
    final endHour = int.tryParse(match.group(3)!);
    final endMinute = int.tryParse(match.group(4)!);

    if (startHour == null ||
        startMinute == null ||
        endHour == null ||
        endMinute == null) {
      return null;
    }

    return _TimeRange(
      start: TimeOfDay(hour: startHour, minute: startMinute),
      end: TimeOfDay(hour: endHour, minute: endMinute),
    );
  }

  static String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
