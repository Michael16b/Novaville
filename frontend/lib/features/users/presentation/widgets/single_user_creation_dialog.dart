import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/config/app_routes.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_bulk_user_creation.dart';
import 'package:frontend/constants/texts/texts_general.dart';
import 'package:frontend/constants/texts/texts_user_accounts.dart';
import 'package:frontend/core/validation_patterns.dart';
import 'package:frontend/design_systems/custom_snack_bar.dart';
import 'package:frontend/features/reports/data/models/neighborhood.dart';
import 'package:frontend/features/users/data/models/user_role.dart';
import 'package:frontend/features/users/data/user_repository.dart';
import 'package:frontend/ui/widgets/styled_dialog.dart';

class SingleUserCreationDialog extends StatefulWidget {
  const SingleUserCreationDialog({
    required this.userRepository,
    required this.neighborhoods,
    super.key,
  });

  final IUserRepository userRepository;
  final List<Neighborhood> neighborhoods;

  @override
  State<SingleUserCreationDialog> createState() =>
      _SingleUserCreationDialogState();
}

class _SingleUserCreationDialogState extends State<SingleUserCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();

  UserRole _selectedRole = UserRole.citizen;
  int? _selectedNeighborhoodId;
  bool _isSubmitting = false;
  bool _usernameWasManuallyEdited = false;
  bool _isProgrammaticUsernameUpdate = false;

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
      title: UserTexts.addUser,
      icon: Icons.person_add_alt_1,
      maxWidth: 500,
      actions: [
        StyledDialog.cancelButton(
          label: AppTextsGeneral.cancel,
          onPressed: () => Navigator.pop(context),
        ),
        StyledDialog.primaryButton(
          label: AppTextsGeneral.create,
          icon: _isSubmitting ? null : Icons.send_outlined,
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
                        onChanged: (_) => _applyAutoUsernameIfNeeded(),
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
                        onChanged: (_) => _applyAutoUsernameIfNeeded(),
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
              decoration: InputDecoration(
                hintText: BulkUserCreationTexts.usernameLabel,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: BulkUserCreationTexts.randomUsernameTooltip,
                  onPressed: _applyRandomUsernameSuggestion,
                  icon: const Icon(Icons.casino_outlined),
                ),
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
              onChanged: (value) {
                if (_isProgrammaticUsernameUpdate) return;
                _usernameWasManuallyEdited = value.trim().isNotEmpty;
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

  void _applyAutoUsernameIfNeeded() {
    if (_usernameWasManuallyEdited) return;

    final suggestion = _buildUsernameFromNames(
      _firstNameController.text,
      _lastNameController.text,
    );

    if (suggestion == _usernameController.text.trim()) return;

    _isProgrammaticUsernameUpdate = true;
    _usernameController.text = suggestion;
    _usernameController.selection = TextSelection.collapsed(
      offset: _usernameController.text.length,
    );
    _isProgrammaticUsernameUpdate = false;
  }

  void _applyRandomUsernameSuggestion() {
    final base = _buildUsernameFromNames(
      _firstNameController.text,
      _lastNameController.text,
    );
    final random = Random.secure();
    final suffix = (100 + random.nextInt(900)).toString();
    final suggestion = '${base.isEmpty ? 'user' : base}$suffix';

    _isProgrammaticUsernameUpdate = true;
    _usernameController.text = suggestion;
    _usernameController.selection = TextSelection.collapsed(
      offset: _usernameController.text.length,
    );
    _isProgrammaticUsernameUpdate = false;
    _usernameWasManuallyEdited = true;
  }

  String _buildUsernameFromNames(String firstName, String lastName) {
    final cleanedFirstName = firstName.trim().toLowerCase();
    final cleanedLastName = lastName.trim().toLowerCase().replaceAll(' ', '');

    if (cleanedFirstName.isEmpty || cleanedLastName.isEmpty) return '';

    return '${cleanedFirstName[0]}$cleanedLastName';
  }

  String _generatePassword() {
    const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
    const digits = '23456789';
    const all = '$letters$digits';

    final random = Random.secure();
    final chars = <String>[
      letters[random.nextInt(letters.length)],
      digits[random.nextInt(digits.length)],
    ];

    while (chars.length < 8) {
      chars.add(all[random.nextInt(all.length)]);
    }

    chars.shuffle(random);
    return chars.join();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final password = _generatePassword();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    try {
      await widget.userRepository.createUser(
        username: username,
        email: email,
        firstName: firstName,
        lastName: lastName,
        password: password,
        role: _selectedRole,
        neighborhoodId: _selectedNeighborhoodId,
      );

      if (!mounted) return;

      Navigator.pop(context); // Close creation dialog

      // Show credentials dialog
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _CredentialsDialog(
          firstName: firstName,
          lastName: lastName,
          username: username,
          password: password,
          email: email,
        ),
      );
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
      title: UserTexts.userCreatedSuccess,
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
            UserTexts.userCreatedSuccessMessage,
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
