import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';

class MyAccountSkeleton extends StatelessWidget {
  const MyAccountSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              Center(
                child: Container(
                  height: 28,
                  width: 180,
                  color: AppColors.primary.withValues(alpha: 0.12),
                  margin: const EdgeInsets.only(bottom: 32),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 18,
                          width: 120,
                          color: AppColors.primary.withValues(alpha: 0.12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 16,
                      width: double.infinity,
                      color: AppColors.textGrey.withValues(alpha: 0.18),
                      margin: const EdgeInsets.only(bottom: 12),
                    ),
                    Container(
                      height: 16,
                      width: double.infinity,
                      color: AppColors.textGrey.withValues(alpha: 0.18),
                      margin: const EdgeInsets.only(bottom: 12),
                    ),
                    Container(
                      height: 16,
                      width: double.infinity,
                      color: AppColors.textGrey.withValues(alpha: 0.18),
                      margin: const EdgeInsets.only(bottom: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 18,
                          width: 120,
                          color: AppColors.primary.withValues(alpha: 0.12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 16,
                      width: double.infinity,
                      color: AppColors.textGrey.withValues(alpha: 0.18),
                      margin: const EdgeInsets.only(bottom: 12),
                    ),
                    Align(
                      child: Container(
                        height: 36,
                        width: 160,
                        color: AppColors.primary.withValues(alpha: 0.12),
                        margin: const EdgeInsets.only(top: 8),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 36,
                    width: 100,
                    color: AppColors.primary.withValues(alpha: 0.12),
                    margin: const EdgeInsets.only(right: 16),
                  ),
                  Container(
                    height: 36,
                    width: 120,
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      color: AppColors.primary.withValues(alpha: 0.12),
                      margin: const EdgeInsets.only(right: 8),
                    ),
                    Container(
                      height: 14,
                      width: 120,
                      color: AppColors.textGrey.withValues(alpha: 0.18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
