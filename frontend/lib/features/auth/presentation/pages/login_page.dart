import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/constants/form_labels.dart';
import 'package:frontend/constants/texts.dart';
import 'package:frontend/constants/validator_messages.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/design_systems/custom_elevated_button.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/ui/assets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthLoginSubmitted(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        // Nous affichons maintenant l'erreur inline dans le builder (pas de SnackBar ici)
      },
      builder: (context, state) {
        final isLoading =
            state.status == AuthStatus.authenticating ||
            state.status == AuthStatus.checking;
        return Scaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: AppFormLabels.email,
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? AppValidatorMessages.email_required
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: AppFormLabels.password,
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? AppValidatorMessages.password_required
                            : null,
                      ),
                      const SizedBox(height: 12),
                      // Affiche l'erreur d'authentification si elle existe
                      if (state.status == AuthStatus.failure && state.error != null)
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
                        child: CustomElevatedButton(
                          text: AppTexts.login,
                          isLoading: isLoading,
                          onPressed: _submit,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
