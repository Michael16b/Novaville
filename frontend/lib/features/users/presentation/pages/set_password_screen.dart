import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/constants/colors.dart';
import 'package:frontend/design_systems/custom_snack_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/constants/texts/texts_auth.dart';

class SetPasswordScreen extends StatefulWidget {
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? tempPassword;

  const SetPasswordScreen({
    super.key,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.tempPassword,
  });

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late final TextEditingController _usernameController;
  late final TextEditingController _tempPasswordController;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _obscureTempPassword = true;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.username);
    _tempPasswordController = TextEditingController(
      text: widget.tempPassword ?? '',
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _tempPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_tempPasswordController.text.isEmpty) {
      CustomSnackBar.showError(context, AppTextsAuth.activationCodeRequired);
      return;
    }

    setState(() => _isLoading = true);

    try {
      const baseUrl = String.fromEnvironment(
        'FLUTTER_BACKEND_API',
        defaultValue: 'http://localhost:8000',
      );

      final loginResponse = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/token/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text,
          'password': _tempPasswordController.text,
        }),
      );

      if (loginResponse.statusCode != 200) {
        throw Exception(AppTextsAuth.invalidOrExpiredLink);
      }

      final loginData = jsonDecode(loginResponse.body);
      final accessToken = loginData['access'];
      final userId = loginData['user']['id'];

      // Étape 2 : Mettre à jour le mot de passe de l'utilisateur existant
      final updateResponse = await http.patch(
        Uri.parse('$baseUrl/api/v1/users/$userId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'password': _passwordController.text}),
      );

      if (updateResponse.statusCode != 200 &&
          updateResponse.statusCode != 204) {
        String errorMessage = AppTextsAuth.passwordChangeError(
          updateResponse.statusCode,
        );
        try {
          final errorData = jsonDecode(updateResponse.body);
          if (errorData is Map) {
            if (errorData.containsKey('password')) {
              final pwdErrors = errorData['password'];
              if (pwdErrors is List && pwdErrors.isNotEmpty) {
                errorMessage = pwdErrors.first.toString();
              }
            } else if (errorData.containsKey('detail')) {
              errorMessage = errorData['detail'].toString();
            } else if (errorData.isNotEmpty) {
              final firstError = errorData.values.first;
              if (firstError is List && firstError.isNotEmpty) {
                errorMessage = firstError.first.toString();
              }
            }
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }

      if (mounted) {
        CustomSnackBar.showSuccess(context, AppTextsAuth.passwordSetupSuccess);
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        String errMsg = e.toString();
        if (errMsg.startsWith('Exception: ')) {
          errMsg = errMsg.substring(11);
        }
        CustomSnackBar.showError(context, AppTextsAuth.errorPrefix(errMsg));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildInfoField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.secondaryText),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullName = [
      widget.firstName,
      widget.lastName,
    ].where((s) => s != null && s!.trim().isNotEmpty).join(' ');

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 32,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: const Icon(
                              Icons.person_add_rounded,
                              color: AppColors.primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              AppTextsAuth.setPasswordTitle,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        AppTextsAuth.setPasswordDescription,
                        style: TextStyle(color: AppColors.secondaryText),
                      ),
                      const SizedBox(height: 24),

                      // Résumé des informations en lecture seule
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (fullName.isNotEmpty)
                              _buildInfoField(AppTextsAuth.fullName, fullName),

                            // Si le username n'est pas fourni dans l'URL, on laisse l'utilisateur le saisir
                            if (widget.username.isEmpty)
                              TextFormField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  labelText: AppTextsAuth.usernameLabel,
                                  hintText: AppTextsAuth.usernameHint,
                                  border: OutlineInputBorder(),
                                  errorMaxLines: 3,
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? AppTextsAuth.usernameRequired
                                    : null,
                              )
                            else
                              _buildInfoField(
                                AppTextsAuth.usernameLabel,
                                widget.username,
                              ),

                            const SizedBox(height: 12),

                            // Si le tempPassword n'est pas fourni dans l'URL, on demande le code d'activation
                            if (widget.tempPassword == null ||
                                widget.tempPassword!.isEmpty)
                              TextFormField(
                                controller: _tempPasswordController,
                                obscureText: _obscureTempPassword,
                                decoration: InputDecoration(
                                  labelText: AppTextsAuth.activationCodeLabel,
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureTempPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscureTempPassword =
                                          !_obscureTempPassword,
                                    ),
                                  ),
                                  errorMaxLines: 3,
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? AppTextsAuth.activationCodeRequired
                                    : null,
                              ),

                            if (widget.email.isNotEmpty)
                              _buildInfoField(
                                AppTextsAuth.emailLabel,
                                widget.email,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: AppTextsAuth.newPasswordLabel,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          errorMaxLines: 3,
                        ),
                        validator: (value) {
                          if (value == null || value.length < 8) {
                            return AppTextsAuth.passwordTooShort;
                          }
                          // Check if the password contains only digits
                          if (RegExp(r'^[0-9]+$').hasMatch(value)) {
                            return AppTextsAuth.passwordEntirelyNumeric;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: AppTextsAuth.confirmPasswordLabel,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                          ),
                          errorMaxLines: 3,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppTextsAuth.confirmPasswordRequired;
                          }
                          if (value != _passwordController.text) {
                            return AppTextsAuth.passwordsDoNotMatch;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _isLoading ? null : _submit,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(
                          _isLoading
                              ? AppTextsAuth.creationInProgress
                              : AppTextsAuth.validateAndCreateAccount,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
