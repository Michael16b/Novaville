import 'package:flutter/material.dart';
import 'package:frontend/config/app_routes.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_auth.dart';
import 'package:frontend/constants/texts/texts_form_labels.dart';
import 'package:frontend/constants/texts/texts_general.dart';
import 'package:frontend/constants/texts/texts_validator_messages.dart';
import 'package:frontend/core/validation_patterns.dart';
import 'package:frontend/design_systems/custom_elevated_flat_button.dart';
import 'package:frontend/features/users/data/user_repository.dart';
import 'package:frontend/features/users/data/user_repository_factory.dart';
import 'package:go_router/go_router.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, this.userRepository});

  final IUserRepository? userRepository;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final IUserRepository _repository;
  bool _isSubmitting = false;
  String? _submissionError;

  @override
  void initState() {
    super.initState();
    _repository = widget.userRepository ?? createPublicUserRepository();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });

    try {
      await _repository.createUser(
        username: _usernameController.text.trim(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        password: _passwordController.text,
        address: _addressController.text.trim(),
        email: _emailController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      context.go(AppRoutes.login);
    } catch (e) {
      if (!mounted) {
        return;
      }
      final message = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _submissionError = message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextButton.icon(
                onPressed: _isSubmitting
                    ? null
                    : () => context.go(AppRoutes.home),
                icon: const Icon(Icons.arrow_back),
                label: const Text(AppTextsAuth.backToHome),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 32,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  AppTextsAuth.register,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppTextsAuth.registerDescription,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.secondaryText,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                _buildField(
                                  controller: _firstNameController,
                                  label: AppFormLabels.firstName,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return AppValidatorMessages
                                          .firstNameRequired;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildField(
                                  controller: _lastNameController,
                                  label: AppFormLabels.lastName,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return AppValidatorMessages
                                          .lastNameRequired;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildField(
                                  controller: _addressController,
                                  label: AppFormLabels.address,
                                  maxLines: 2,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return AppValidatorMessages
                                          .addressRequired;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildField(
                                  controller: _emailController,
                                  label: AppFormLabels.email,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    final trimmed = value?.trim() ?? '';
                                    if (trimmed.isEmpty) {
                                      return AppValidatorMessages.emailRequired;
                                    }
                                    if (!ValidationPatterns.email.hasMatch(
                                      trimmed,
                                    )) {
                                      return AppValidatorMessages.emailInvalid;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildField(
                                  controller: _usernameController,
                                  label: AppFormLabels.login,
                                  validator: (value) {
                                    final trimmed = value?.trim() ?? '';
                                    if (trimmed.isEmpty) {
                                      return AppValidatorMessages.loginRequired;
                                    }
                                    if (trimmed.contains(RegExp(r'\s'))) {
                                      return AppValidatorMessages
                                          .loginInvalidWhitespace;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildField(
                                  controller: _passwordController,
                                  label: AppFormLabels.password,
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return AppValidatorMessages
                                          .passwordRequired;
                                    }
                                    if (value.length < 8) {
                                      return AppValidatorMessages
                                          .passwordMinLength;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildField(
                                  controller: _confirmPasswordController,
                                  label: AppFormLabels.confirmPassword,
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return AppValidatorMessages
                                          .confirmPasswordRequired;
                                    }
                                    if (value != _passwordController.text) {
                                      return AppValidatorMessages
                                          .passwordMismatch;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      size: 14,
                                      color: AppColors.secondaryText,
                                    ),
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
                                if (_submissionError != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    _submissionError!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: CustomElevatedFlatButton(
                                    text: AppTextsAuth.register,
                                    isLoading: _isSubmitting,
                                    onPressed: _submit,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: _isSubmitting
                                      ? null
                                      : () => context.go(AppRoutes.login),
                                  icon: const Icon(Icons.login),
                                  label: const Text(AppTextsAuth.login),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    bool obscureText = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      keyboardType: keyboardType,
      onChanged: (_) {
        if (_submissionError != null) {
          setState(() {
            _submissionError = null;
          });
        }
      },
      validator: validator,
      decoration: InputDecoration(
        labelText: '$label *',
        border: const OutlineInputBorder(),
      ),
    );
  }
}
