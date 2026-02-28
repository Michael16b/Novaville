import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_credentials_share.dart';
import 'package:frontend/design_systems/custom_snack_bar.dart';
import 'package:go_router/go_router.dart';

class CredentialsSharePage extends StatelessWidget {
  const CredentialsSharePage({super.key});

  @override
  Widget build(BuildContext context) {
    final params = GoRouterState.of(context).uri.queryParameters;
    final firstName = params['first_name'] ?? '';
    final lastName = params['last_name'] ?? '';
    final fullName = '$firstName $lastName'.trim();
    final username = params['username'] ?? '';
    final email = params['email'] ?? '';
    final password = params['password'] ?? '';

    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.highlight.withValues(alpha: 0.55),
              AppColors.white,
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.highlight,
                          child: Icon(Icons.badge, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            CredentialsShareTexts.pageTitle,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (fullName.isNotEmpty)
                      Text(
                        fullName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    if (fullName.isNotEmpty) const SizedBox(height: 4),
                    Text(
                      CredentialsShareTexts.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _CredentialRow(
                      label: CredentialsShareTexts.emailLabel,
                      value: email,
                      onCopy: () async {
                        await Clipboard.setData(ClipboardData(text: email));
                        if (!context.mounted) {
                          return;
                        }
                        CustomSnackBar.showSuccess(
                          context,
                          CredentialsShareTexts.emailCopied,
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _CredentialRow(
                      label: CredentialsShareTexts.usernameLabel,
                      value: username,
                      onCopy: () async {
                        await Clipboard.setData(ClipboardData(text: username));
                        if (!context.mounted) {
                          return;
                        }
                        CustomSnackBar.showSuccess(
                          context,
                          CredentialsShareTexts.usernameCopied,
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    _CredentialRow(
                      label: CredentialsShareTexts.passwordLabel,
                      value: password,
                      onCopy: () async {
                        await Clipboard.setData(ClipboardData(text: password));
                        if (!context.mounted) {
                          return;
                        }
                        CustomSnackBar.showSuccess(
                          context,
                          CredentialsShareTexts.passwordCopied,
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(
                            text: CredentialsShareTexts.allCredentialsText(
                              fullName: fullName,
                              email: email,
                              username: username,
                              password: password,
                            ),
                          ),
                        );
                        if (!context.mounted) {
                          return;
                        }
                        CustomSnackBar.showSuccess(
                          context,
                          CredentialsShareTexts.allCopied,
                        );
                      },
                      icon: const Icon(Icons.copy_all),
                      label: const Text(CredentialsShareTexts.copyAllLabel),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  const _CredentialRow({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  final String label;
  final String value;
  final Future<void> Function() onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.secondaryText.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              await onCopy();
            },
            tooltip: CredentialsShareTexts.copyTooltip,
            icon: const Icon(Icons.copy),
          ),
        ],
      ),
    );
  }
}
