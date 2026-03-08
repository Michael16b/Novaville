import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_form_labels.dart';
import 'package:frontend/constants/texts/texts_auth.dart';
import 'package:frontend/constants/texts/texts_general.dart';
import 'package:frontend/constants/texts/texts_validator_messages.dart';
import 'package:frontend/design_systems/custom_elevated_flat_button.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/ui/assets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthLoginSubmitted(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        // Errors are displayed inline in the builder (no SnackBar here)
      },
      builder: (context, state) {
        final isLoading =
            state.status == AuthStatus.authenticating ||
                state.status == AuthStatus.checking;
        return Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 32,
                      maxWidth: 400,
                    ),
                    child: Center(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              AppAssets.login_logo,
                              height: 300,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _usernameController,
                              keyboardType: TextInputType.name,
                              textInputAction: TextInputAction.next,
                              validator: (v) => (v == null || v.isEmpty)
                                  ? AppValidatorMessages.usernameRequired
                                  : null,
                              decoration: const InputDecoration(
                                labelText: '${AppFormLabels.username} *',
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              validator: (v) => (v == null || v.isEmpty)
                                  ? AppValidatorMessages.passwordRequired
                                  : null,
                              decoration: const InputDecoration(
                                labelText: '${AppFormLabels.password} *',
                              ),
                            ),
                            const SizedBox(height: 12),
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
                            const SizedBox(height: 12),
                            // Display the authentication error if present
                            if (state.status == AuthStatus.failure &&
                                state.error != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  state.error!,
                                  style: const TextStyle(color: AppColors.error),
                                ),
                              ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: CustomElevatedFlatButton(
                                text: AppTextsAuth.login,
                                isLoading: isLoading,
                                onPressed: _submit,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
