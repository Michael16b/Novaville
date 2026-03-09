import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_general.dart';
import 'package:frontend/constants/texts/texts_my_account.dart';
import 'package:frontend/core/validation_patterns.dart';
import 'package:frontend/design_systems/custom_elevated_flat_button.dart';
import 'package:frontend/design_systems/custom_snack_bar.dart';
import 'package:frontend/features/users/application/bloc/user_profil_bloc/user_profile_bloc.dart';
import 'package:frontend/features/users/data/user_repository_factory.dart';
import 'package:frontend/ui/widgets/styled_dialog.dart';

/// User account page with a profile edit form.
class MyAccountPage extends StatelessWidget {
  /// Creates the account page.
  const MyAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserProfileBloc(
        repository: createUserRepository(),
      )..add(const UserProfileLoadRequested()),
      child: const _MyAccountView(),
    );
  }
}

class _MyAccountView extends StatefulWidget {
  const _MyAccountView();

  @override
  State<_MyAccountView> createState() => _MyAccountViewState();
}

class _MyAccountViewState extends State<_MyAccountView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
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
    return BlocConsumer<UserProfileBloc, UserProfileState>(
      listener: (context, state) {
        if (state.status == UserProfileStatus.loaded && state.user != null) {
          if (!_initialized) {
            _firstNameController.text = state.user!.firstName;
            _lastNameController.text = state.user!.lastName;
            _usernameController.text = state.user!.username;
            _emailController.text = state.user!.email;
            _initialized = true;
          }

          if (state.isUpdate) {
            CustomSnackBar.showSuccess(
              context,
              AppTextsProfile.profileUpdateSuccess,
            );
          } else if (state.isPasswordUpdate) {
            CustomSnackBar.showSuccess(
              context,
              AppTextsProfile.passwordUpdateSuccess,
            );
          }
        } else if (state.status == UserProfileStatus.failure) {
          if (state.isUpdate) {
            CustomSnackBar.showError(
              context,
              state.error ?? AppTextsProfile.profileUpdateError,
            );
          }
        }
      },
      builder: (context, state) {
        if (state.status == UserProfileStatus.loading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(AppTextsProfile.loadingProfile),
              ],
            ),
          );
        }

        if (state.status == UserProfileStatus.failure &&
            !state.isUpdate &&
            !state.isPasswordUpdate) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  state.error ?? AppTextsGeneral.errorOccurred,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                CustomElevatedFlatButton(
                  onPressed: () {
                    context.read<UserProfileBloc>().add(
                      const UserProfileLoadRequested(),
                    );
                  },
                  text: AppTextsGeneral.retry,
                ),
              ],
            ),
          );
        }

        if (state.user == null) {
          return const Center(child: Text(AppTextsProfile.noUser));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  spacing: 24,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 44,
                        color: AppColors.primary,
                      ),
                    ),
                    const Text(
                      AppTextsProfile.myProfile,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // Personal information section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        spacing: 16,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color:
                                  AppColors.primary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                AppTextsProfile.personalInformation,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          TextFormField(
                            controller: _firstNameController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppTextsProfile.firstNameRequired;
                              }
                              return null;
                            },
                            decoration: const InputDecoration(
                              labelText: '${AppTextsProfile.firstName} *',
                            ),
                          ),
                          TextFormField(
                            controller: _lastNameController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppTextsProfile.lastNameRequired;
                              }
                              return null;
                            },
                            decoration: const InputDecoration(
                              labelText: '${AppTextsProfile.lastName} *',
                            ),
                          ),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppTextsProfile.emailRequired;
                              }
                              if (!ValidationPatterns.email.hasMatch(value)) {
                                return AppTextsProfile.emailInvalid;
                              }
                              return null;
                            },
                            decoration: const InputDecoration(
                              labelText: '${AppTextsProfile.email} *',
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Login information section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        spacing: 16,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color:
                                  AppColors.primary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.lock_outline,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                AppTextsProfile.connectionInformation,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          TextFormField(
                            controller: _usernameController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppTextsProfile.usernameRequired;
                              }
                              return null;
                            },
                            decoration: const InputDecoration(
                              labelText: '${AppTextsProfile.username} *',
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _showChangePasswordDialog(
                                  context,
                                  state.user!.id,
                                ),
                                icon: const Icon(Icons.password),
                                label: const Text(AppTextsProfile.changePassword),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Required fields hint
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 14,
                          color: AppColors.secondaryText,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          AppTextsGeneral.requiredFieldsHint,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                            color: AppColors.secondaryText,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      spacing: 16,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: state.status == UserProfileStatus.updating
                              ? null
                              : () {
                            // Reset fields to their original values
                            _firstNameController.text =
                                state.user!.firstName;
                            _lastNameController.text =
                                state.user!.lastName;
                            _usernameController.text =
                                state.user!.username;
                            _emailController.text = state.user!.email;
                          },
                          icon: const Icon(Icons.refresh_outlined),
                          label: const Text(AppTextsGeneral.reset),
                        ),
                        CustomElevatedFlatButton(
                          isLoading: state.status == UserProfileStatus.updating,
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              context.read<UserProfileBloc>().add(
                                UserProfileUpdateRequested(
                                  userId: state.user!.id,
                                  firstName: _firstNameController.text,
                                  lastName: _lastNameController.text,
                                  username: _usernameController.text,
                                  email: _emailController.text,
                                ),
                              );
                            }
                          },
                          text: AppTextsGeneral.save,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context, int userId) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _ChangePasswordDialog(
        userId: userId,
        bloc: context.read<UserProfileBloc>(),
      ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({
    required this.userId,
    required this.bloc,
  });

  final int userId;
  final UserProfileBloc bloc;

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _passwordValidationMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserProfileBloc, UserProfileState>(
      bloc: widget.bloc,
      listener: (context, state) {
        if (state.status == UserProfileStatus.loaded && state.isPasswordUpdate) {
          Navigator.pop(context);
        } else if (state.status == UserProfileStatus.failure && state.isPasswordUpdate) {
          String errorMessage = AppTextsProfile.passwordUpdateError;
          final error = state.error ?? '';

          if (error.contains('password_fields_required')) {
            errorMessage = AppTextsProfile.passwordFieldsRequired;
          } else if (error.contains('incorrect_password')) {
            errorMessage = AppTextsProfile.passwordIncorrect;
          } else if (error.contains('password_invalid')) {
            errorMessage = AppTextsProfile.passwordValidationFailed;
          } else if (error.contains('forbidden')) {
            errorMessage = AppTextsProfile.passwordForbidden;
          }
          Navigator.pop(context);
          CustomSnackBar.showError(context, errorMessage);
        }
      },
      child: StyledDialog(
        title: AppTextsProfile.changePassword,
        icon: Icons.lock_reset,
        maxWidth: 400,
        actions: [
          StyledDialog.cancelButton(
            label: AppTextsGeneral.cancel,
            onPressed: () => Navigator.pop(context),
          ),
          StyledDialog.primaryButton(
            label: AppTextsGeneral.save,
            icon: Icons.check,
            onPressed: _submit,
          ),
        ],
        body: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                decoration: InputDecoration(
                  labelText: AppTextsProfile.currentPassword,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrent ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppTextsProfile.passwordRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: AppTextsProfile.newPassword,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppTextsProfile.passwordRequired;
                  }
                  if (!ValidationPatterns.password.hasMatch(value)) {
                    setState(() {
                      _passwordValidationMessage = AppTextsProfile.passwordTooWeak;
                    });
                    return null;
                  }
                  setState(() {
                    _passwordValidationMessage = null;
                  });
                  return null;
                },
              ),
              if (_passwordValidationMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Text(
                    _passwordValidationMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.visible,
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: AppTextsProfile.confirmNewPassword,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return AppTextsProfile.passwordRequired;
                  }
                  if (value != _newPasswordController.text) {
                    return AppTextsProfile.passwordsDoNotMatch;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.bloc.add(UserProfilePasswordUpdateRequested(
        userId: widget.userId,
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      ));
    }
  }
}