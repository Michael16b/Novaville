import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/config/app_routes.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_auth.dart';
import 'package:frontend/constants/texts/texts_bulk_user_creation.dart';
import 'package:frontend/constants/texts/texts_general.dart';
import 'package:frontend/constants/texts/texts_user_accounts.dart';
import 'package:frontend/core/validation_patterns.dart';
import 'package:frontend/design_systems/custom_snack_bar.dart';
import 'package:frontend/features/reports/data/models/neighborhood.dart';
import 'package:frontend/features/users/data/models/user.dart';
import 'package:frontend/features/users/data/models/user_role.dart';
import 'package:frontend/features/users/data/user_repository.dart';
import 'package:frontend/features/users/presentation/pages/pdf_generation_util.dart';
import 'package:frontend/ui/widgets/styled_dialog.dart';

class SingleUserEditDialog extends StatefulWidget {
  const SingleUserEditDialog({
    required this.userRepository,
    required this.neighborhoods,
    required this.user,
    super.key,
  });

  final IUserRepository userRepository;
  final List<Neighborhood> neighborhoods;
  final User user;

  @override
  State<SingleUserEditDialog> createState() => _SingleUserEditDialogState();
}

class _SingleUserEditDialogState extends State<SingleUserEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;

  late UserRole _selectedRole;
  int? _selectedNeighborhoodId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _usernameController = TextEditingController(text: widget.user.username);
    _emailController = TextEditingController(text: widget.user.email);
    _selectedRole = widget.user.role ?? UserRole.citizen;
    _selectedNeighborhoodId = widget.user.neighborhoodId;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StyledDialog(
      title: UserTexts.editUserTitle,
      icon: Icons.edit_outlined,
      maxWidth: 500,
      actions: [
        StyledDialog.cancelButton(
          label: AppTextsGeneral.cancel,
          onPressed: () => Navigator.pop(context),
        ),
        StyledDialog.primaryButton(
          label: AppTextsGeneral.save,
          icon: _isSubmitting ? null : Icons.check,
          onPressed: _isSubmitting ? null : () => _onSubmit(),
        ),
      ],
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('${BulkUserCreationTexts.firstNameLabel} *'),
                      TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          hintText: BulkUserCreationTexts.firstNameLabel,
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return BulkUserCreationTexts.firstNameMissing;
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('${BulkUserCreationTexts.lastNameLabel} *'),
                      TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          hintText: BulkUserCreationTexts.lastNameLabel,
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return BulkUserCreationTexts.lastNameMissing;
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLabel('${BulkUserCreationTexts.usernameLabel} *'),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                hintText: BulkUserCreationTexts.usernameLabel,
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return BulkUserCreationTexts.usernameMissing;
                }
                if (value.contains(RegExp(r'\s'))) {
                  return BulkUserCreationTexts.usernameInvalidWhitespace;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildLabel('${BulkUserCreationTexts.emailLabel} *'),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                hintText: BulkUserCreationTexts.emailLabel,
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return BulkUserCreationTexts.emailMissing;
                }
                if (!ValidationPatterns.email.hasMatch(value)) {
                  return BulkUserCreationTexts.emailInvalid;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildLabel('${BulkUserCreationTexts.roleLabel} *'),
            DropdownButtonFormField<UserRole>(
              value: _selectedRole,
              isExpanded: true,
              menuMaxHeight: 300,
              borderRadius: BorderRadius.circular(12),
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: UserRole.values
                  .where((role) => role != UserRole.globalAdmin)
                  .map(
                    (role) =>
                        DropdownMenuItem(value: role, child: Text(role.label)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedRole = value);
                }
              },
            ),
            const SizedBox(height: 16),
            _buildLabel('${UserTexts.neighborhoodLabel} *'),
            _NeighborhoodAutocompleteField(
              neighborhoods: widget.neighborhoods,
              initialNeighborhoodId: _selectedNeighborhoodId,
              onChanged: (id) {
                setState(() => _selectedNeighborhoodId = id);
              },
              validator: (value) {
                if (value == null) {
                  return UserTexts.selectNeighborhood;
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _RequiredFieldsHint(),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isSubmitting ? null : _onResetPassword,
              icon: const Icon(Icons.lock_reset),
              label: const Text(UserTexts.resetPassword),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size(double.infinity, 48),
              ),
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

  Future<void> _onResetPassword() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StyledDialog(
        title: AppTextsAuth.adminResetPasswordTitle,
        icon: Icons.warning_amber_rounded,
        accentColor: AppColors.error,
        closeTooltip: AppTextsGeneral.cancel,
        maxWidth: 400,
        actions: [
          StyledDialog.cancelButton(
            label: AppTextsGeneral.cancel,
            onPressed: () => Navigator.pop(context, false),
          ),
          StyledDialog.destructiveButton(
            label: UserTexts.resetPasswordConfirm,
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
        body: Text(
          AppTextsAuth.adminResetPasswordConfirm,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSubmitting = true);

    try {
      final tempPassword = await widget.userRepository.resetPassword(
        userId: widget.user.id,
      );

      if (!mounted) return;

      // Show credentials dialog
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _CredentialsDialog(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          username: _usernameController.text.trim(),
          password: tempPassword,
          email: _emailController.text.trim(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      CustomSnackBar.showError(context, e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await widget.userRepository.updateUser(
        userId: widget.user.id,
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        role: _selectedRole,
        neighborhoodId: _selectedNeighborhoodId,
      );

      if (!mounted) return;

      Navigator.pop(context);
      CustomSnackBar.showSuccess(context, UserTexts.userUpdatedSuccess);
    } catch (e) {
      if (!mounted) return;
      CustomSnackBar.showError(context, e.toString());
      setState(() => _isSubmitting = false);
    }
  }
}

class _CredentialsDialog extends StatefulWidget {
  const _CredentialsDialog({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.password,
    required this.email,
  });

  final String firstName;
  final String lastName;
  final String username;
  final String password;
  final String email;

  @override
  State<_CredentialsDialog> createState() => _CredentialsDialogState();
}

class _CredentialsDialogState extends State<_CredentialsDialog> {
  late final TextEditingController _linkController;
  bool _isCopied = false;

  @override
  void initState() {
    super.initState();
    _linkController = TextEditingController(text: _generateLink());
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  String _generateLink() {
    final payload = jsonEncode({
      'v': 1,
      'first_name': widget.firstName,
      'last_name': widget.lastName,
      'username': widget.username,
      'email': widget.email,
      'temp_password': widget.password,
    });
    final encodedShareRef = base64Url
        .encode(utf8.encode(payload))
        .replaceAll('=', '');

    final routeUri = Uri(
      path: AppRoutes.credentialsShare,
      queryParameters: {
        BulkUserCreationTexts.shareReferenceKey: encodedShareRef,
      },
    );

    final currentUri = Uri.base;
    final usesHashRouting = currentUri.fragment.startsWith('/');

    return usesHashRouting
        ? '${currentUri.scheme}://${currentUri.authority}${currentUri.path}#${routeUri.toString()}'
        : currentUri.resolveUri(routeUri).toString();
  }

  void _copyLink() {
    if (_isCopied) return;

    Clipboard.setData(ClipboardData(text: _linkController.text));
    setState(() => _isCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isCopied = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StyledDialog(
      title: UserTexts.passwordResetSuccess,
      icon: Icons.check_circle_outline,
      accentColor: AppColors.success,
      maxWidth: 450,
      actions: [
        StyledDialog.primaryButton(
          label: AppTextsGeneral.close,
          onPressed: () => Navigator.pop(context),
        ),
      ],
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            UserTexts.passwordResetSuccessMessage,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _linkController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: UserTexts.copyConnectionLink,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _copyLink,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(110, 56),
                ),
                icon: Icon(_isCopied ? Icons.check : Icons.copy, size: 20),
                label: Text(_isCopied ? UserTexts.copied : UserTexts.copy),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await PdfGenerationUtil.generateAndDownloadSingleUserPdf(
                      context: context,
                      firstName: widget.firstName,
                      lastName: widget.lastName,
                      username: widget.username,
                      email: widget.email,
                      password: widget.password,
                      shareUrl: _linkController.text,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 56),
                  ),
                  icon: const Icon(Icons.picture_as_pdf, size: 20),
                  label: const Text(UserTexts.downloadPdf),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
            hintText: UserTexts.selectNeighborhood,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                    tooltip: UserTexts.selectNeighborhood,
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
