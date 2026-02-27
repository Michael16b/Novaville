import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/design_systems/custom_snack_bar.dart';
import 'package:go_router/go_router.dart';

class CredentialsSharePage extends StatelessWidget {
  const CredentialsSharePage({super.key});

  @override
  Widget build(BuildContext context) {
    final params = GoRouterState.of(context).uri.queryParameters;
    final username = params['username'] ?? '';
    final password = params['password'] ?? '';
    final name = params['name'] ?? '';

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Novaville - Identifiants',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (name.isNotEmpty) Text('Utilisateur: $name'),
                  const SizedBox(height: 6),
                  Text('Nom d\'utilisateur: $username'),
                  const SizedBox(height: 6),
                  Text('Mot de passe: $password'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(
                              text:
                                  'Nom d\'utilisateur: $username\nMot de passe: $password',
                            ),
                          );
                          if (!context.mounted) {
                            return;
                          }
                          CustomSnackBar.showSuccess(
                            context,
                            'Identifiants copiés dans le presse-papiers.',
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Copier'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
