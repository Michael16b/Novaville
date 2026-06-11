import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_general.dart';
import 'package:frontend/constants/texts/texts_reports.dart';
import 'package:frontend/core/api_config.dart';
import 'package:frontend/features/reports/data/models/problem_type.dart';
import 'package:frontend/features/reports/data/models/report.dart';
import 'package:frontend/features/reports/data/report_repository.dart';
import 'package:frontend/ui/widgets/interactive_address_map.dart';
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
  final _formKey = GlobalKey<FormState>();
  ProblemType? _selectedProblemType;
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;
  final List<ReportPhotoAttachment> _photos = [];
  late final List<ReportPhoto> _existingPhotos;
  final List<int> _deletedPhotoIds = [];

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
    _existingPhotos =
        widget.report?.photos
            .where((photo) => photo.imageUrl.trim().isNotEmpty)
            .toList() ??
        [];
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
                return null;
              },
            ),
            InteractiveAddressMap(
              height: 180,
              onAddressSelected: (address) {
                setState(() {
                  _addressController.text = address;
                });
                _formKey.currentState?.validate();
              },
            ),
            const SizedBox(height: 14),
            _buildLabel(ReportTexts.photosLabel),
            _buildPhotoPicker(context),
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

  Widget _buildPhotoPicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _pickPhotos,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text(ReportTexts.addPhotos),
        ),
        if (_existingPhotos.isNotEmpty || _photos.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 74,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _existingPhotos.length + _photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index < _existingPhotos.length) {
                  final photo = _existingPhotos[index];
                  return _PhotoPreview(
                    child: Image.network(
                      _resolveImageUrl(photo),
                      width: 74,
                      height: 74,
                      fit: BoxFit.cover,
                    ),
                    onRemove: () {
                      setState(() {
                        _deletedPhotoIds.add(photo.id);
                        _existingPhotos.removeAt(index);
                      });
                    },
                  );
                }

                final newPhotoIndex = index - _existingPhotos.length;
                final photo = _photos[newPhotoIndex];
                return _PhotoPreview(
                  child: Image.memory(
                    photo.bytes,
                    width: 74,
                    height: 74,
                    fit: BoxFit.cover,
                  ),
                  onRemove: () {
                    setState(() {
                      _photos.removeAt(newPhotoIndex);
                    });
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickPhotos() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
      withData: true,
    );
    if (result == null || !mounted) return;

    final selectedPhotos = result.files
        .where((file) => file.bytes != null)
        .map(
          (file) => ReportPhotoAttachment(
            field: 'photos',
            filename: file.name,
            bytes: file.bytes!,
          ),
        )
        .toList();

    setState(() {
      _photos.addAll(selectedPhotos);
    });
  }

  String _resolveImageUrl(ReportPhoto photo) {
    return Uri.parse(apiBaseUrl).resolve(photo.imageUrl).toString();
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
      'photos': List<ReportPhotoAttachment>.from(_photos),
      'deleted_photo_ids': List<int>.from(_deletedPhotoIds),
    });
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.child, required this.onRemove});

  final Widget child;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(8), child: child),
        Positioned(
          top: 2,
          right: 2,
          child: Material(
            color: AppColors.overlay,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(3),
                child: Icon(Icons.close, size: 14, color: AppColors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
