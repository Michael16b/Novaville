import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_bulk_user_creation.dart';
import 'package:frontend/constants/texts/texts_credentials_share.dart';
import 'package:frontend/design_systems/custom_snack_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CredentialsSharePage extends StatefulWidget {
  const CredentialsSharePage({super.key});

  @override
  State<CredentialsSharePage> createState() => _CredentialsSharePageState();
}

class _CredentialsSharePageState extends State<CredentialsSharePage> {
  late final Future<_ShareCredentialData?> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadShareData();
  }

  Future<_ShareCredentialData?> _loadShareData() async {
    final params = GoRouterState.of(context).uri.queryParameters;
    final token = params['token'];

    if (token != null && token.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final key = '${BulkUserCreationTexts.shareTokenPrefix}$token';
      final payload = prefs.getString(key);
      if (payload == null || payload.isEmpty) {
        return null;
      }

      try {
        final decoded = jsonDecode(payload);
        if (decoded is! Map<String, dynamic>) {
          return null;
        }
        return _ShareCredentialData.fromMap(decoded);
      } catch (_) {
        return null;
      }
    }

    return _ShareCredentialData(
      firstName: params['first_name'] ?? '',
      lastName: params['last_name'] ?? '',
      username: params['username'] ?? '',
      email: params['email'] ?? '',
      password: params['password'] ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ShareCredentialData?>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data;
        if (data == null) {
          return Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.warning,
                          size: 36,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          CredentialsShareTexts.unavailableTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        const Text(CredentialsShareTexts.unavailableMessage),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        final fullName = '${data.firstName} ${data.lastName}'.trim();

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
                              child: Icon(
                                Icons.badge,
                                color: AppColors.primary,
                              ),
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
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.secondaryText),
                        ),
                        const SizedBox(height: 16),
                        _CredentialRow(
                          label: CredentialsShareTexts.emailLabel,
                          value: data.email,
                          onCopy: () async {
                            await Clipboard.setData(
                              ClipboardData(text: data.email),
                            );
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
                          value: data.username,
                          onCopy: () async {
                            await Clipboard.setData(
                              ClipboardData(text: data.username),
                            );
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
                          value: data.password,
                          onCopy: () async {
                            await Clipboard.setData(
                              ClipboardData(text: data.password),
                            );
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
                                  email: data.email,
                                  username: data.username,
                                  password: data.password,
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
      },
    );
  }
}

class _ShareCredentialData {
  const _ShareCredentialData({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.password,
  });

  factory _ShareCredentialData.fromMap(Map<String, dynamic> map) {
    String safeString(dynamic value) => value is String ? value : '';

    return _ShareCredentialData(
      firstName: safeString(map['first_name']),
      lastName: safeString(map['last_name']),
      username: safeString(map['username']),
      email: safeString(map['email']),
      password: safeString(map['password']),
    );
  }

  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String password;
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
