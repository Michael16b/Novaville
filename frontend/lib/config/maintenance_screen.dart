import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';

/// Screen displayed when the backend is restarting or unavailable.
class MaintenanceScreen extends StatelessWidget {
  /// Creates a maintenance screen.
  const MaintenanceScreen({required this.onRetry, super.key});

  /// Callback when the user clicks the retry button.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_sync_outlined,
                  size: 100,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 32),
                Text(
                  'Mise à jour en cours',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Nos serveurs redémarrent pour vous apporter de nouvelles '
                  'fonctionnalités.\n\n'
                  "L'application sera disponible d'ici quelques minutes.",
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer la connexion'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
