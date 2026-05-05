import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/constants/colors.dart';
import 'package:frontend/design_systems/custom_snack_bar.dart';
import 'package:go_router/go_router.dart';

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
      CustomSnackBar.showError(
        context,
        'Le code d\'activation ou mot de passe temporaire est requis.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Étape 1 : S'authentifier avec le mot de passe temporaire pour obtenir le JWT
      final loginResponse = await http.post(
        Uri.parse('http://localhost:8000/api/v1/auth/token/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text,
          'password': _tempPasswordController.text,
        }),
      );

      if (loginResponse.statusCode != 200) {
        throw Exception(
          'Le lien est invalide ou le mot de passe temporaire a expiré.',
        );
      }

      final loginData = jsonDecode(loginResponse.body);
      final accessToken = loginData['access'];
      final userId = loginData['user']['id'];

      // Étape 2 : Mettre à jour le mot de passe de l'utilisateur existant
      final updateResponse = await http.patch(
        Uri.parse('http://localhost:8000/api/v1/users/$userId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'password': _passwordController.text}),
      );

      if (updateResponse.statusCode != 200 &&
          updateResponse.statusCode != 204) {
        throw Exception(
          'Erreur lors du changement de mot de passe (${updateResponse.statusCode})',
        );
      }

      if (mounted) {
        CustomSnackBar.showSuccess(
          context,
          'Mot de passe configuré avec succès !',
        );
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, 'Erreur : $e');
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
                              'Définir mon mot de passe',
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
                        'Vérifiez vos informations et choisissez un mot de passe pour finaliser la création de votre compte.',
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
                              _buildInfoField('Nom complet', fullName),

                            // Si le username n'est pas fourni dans l'URL, on laisse l'utilisateur le saisir
                            if (widget.username.isEmpty)
                              TextFormField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  labelText: 'Nom d\'utilisateur',
                                  hintText: 'Saisissez votre identifiant',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'L\'identifiant est requis'
                                    : null,
                              )
                            else
                              _buildInfoField(
                                'Nom d\'utilisateur',
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
                                  labelText:
                                      'Code d\'activation (mot de passe reçu)',
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
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Le code d\'activation est requis'
                                    : null,
                              ),

                            if (widget.email.isNotEmpty)
                              _buildInfoField('Email', widget.email),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Nouveau mot de passe',
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
                        ),
                        validator: (value) => value != null && value.length >= 8
                            ? null
                            : 'Le mot de passe doit contenir au moins 8 caractères',
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirmer le mot de passe',
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
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez confirmer le mot de passe';
                          }
                          if (value != _passwordController.text) {
                            return 'Les mots de passe ne correspondent pas';
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
                              ? 'Création en cours...'
                              : 'Valider et créer mon compte',
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
