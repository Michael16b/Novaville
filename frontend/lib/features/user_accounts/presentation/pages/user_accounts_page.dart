import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';

/// User Accounts management page - accessible only to GLOBAL_ADMIN.
///
/// Access control is handled at the router level.
class UserAccountPage extends StatelessWidget {
  /// Creates the user accounts page.
  const UserAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des comptes utilisateurs'),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.user;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display confirmation that user is admin
                Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings, color: Colors.green[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bienvenue ${user?.username ?? "Admin"}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Rôle: ${user?.role?.label ?? "N/A"}',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Liste des utilisateurs',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Fonctionnalité en cours de développement...\n\n'
                      'Ici vous pourrez:\n'
                      '• Voir la liste de tous les utilisateurs\n'
                      '• Modifier les rôles\n'
                      '• Désactiver des comptes\n'
                      '• Gérer les permissions',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}




