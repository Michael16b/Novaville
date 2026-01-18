import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts.dart';
import 'package:frontend/ui/layouts/secured_layout.dart';

/// Page des signalements
class ReportsPage extends StatelessWidget {
  /// Crée la page des signalements
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SecuredLayout(
      isHomePage: false,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.report_problem_outlined,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                AppTexts.reports,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Page des signalements',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
