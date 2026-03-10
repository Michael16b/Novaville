import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_bulk_user_creation.dart';
import 'package:frontend/constants/texts/texts_credentials_share.dart';
import 'package:frontend/design_systems/custom_snack_bar.dart';
import 'package:go_router/go_router.dart';

class CredentialsSharePage extends StatefulWidget {
  const CredentialsSharePage({super.key});

  @override
  State<CredentialsSharePage> createState() => _CredentialsSharePageState();
}

class _CredentialsSharePageState extends State<CredentialsSharePage> {
  late final Future<_ShareCredentialData?> _dataFuture;
  bool _futureInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_futureInitialized) {
      return;
    }
    _futureInitialized = true;
    _dataFuture = _loadShareData();
  }

  Map<String, String> _collectShareParams() {
    final collected = <String, String>{};

    void mergeQueryString(String query) {
      if (query.trim().isEmpty) {
        return;
      }
      try {
        final parsed = Uri.splitQueryString(query);
        parsed.forEach((key, value) {
          final existing = collected[key];
          if (existing == null || existing.trim().isEmpty) {
            collected[key] = value;
          }
        });
      } catch (_) {}
    }

    final routerUri = GoRouterState.of(context).uri;
    mergeQueryString(routerUri.query);

    final routerFragment = routerUri.fragment;
    final routerQueryIndex = routerFragment.indexOf('?');
    if (routerQueryIndex >= 0 && routerQueryIndex < routerFragment.length - 1) {
      mergeQueryString(routerFragment.substring(routerQueryIndex + 1));
    }

    final baseUri = Uri.base;
    mergeQueryString(baseUri.query);

    final fragment = baseUri.fragment;
    final queryIndex = fragment.indexOf('?');
    if (queryIndex >= 0 && queryIndex < fragment.length - 1) {
      mergeQueryString(fragment.substring(queryIndex + 1));
    }

    return collected;
  }

  _ShareCredentialData? _decodeShareRef(String? shareRef) {
    if (shareRef == null || shareRef.trim().isEmpty) {
      return null;
    }

    try {
      final normalized = base64Url.normalize(shareRef.trim());
      final decodedJson = utf8.decode(base64Url.decode(normalized));
      final decoded = jsonDecode(decodedJson);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      String safeString(dynamic value) => value is String ? value : '';

      final firstName = safeString(decoded['first_name']);
      final lastName = safeString(decoded['last_name']);
      final username = safeString(decoded['username']);
      final email = safeString(decoded['email']);
      final password = safeString(decoded['password']);

      final hasAtLeastOneValue =
          firstName.isNotEmpty ||
          lastName.isNotEmpty ||
          username.isNotEmpty ||
          email.isNotEmpty ||
          password.isNotEmpty;

      if (!hasAtLeastOneValue) {
        return null;
      }

      return _ShareCredentialData(
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
        password: password,
      );
    } catch (_) {
      return null;
    }
  }

  Future<_ShareCredentialData?> _loadShareData() async {
    final params = _collectShareParams();
    final shareRef = params[BulkUserCreationTexts.shareReferenceKey];
    return _decodeShareRef(shareRef);
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
          backgroundColor: AppColors.white,
          body: Center(
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Icon(
                              Icons.lock_person_rounded,
                              color: AppColors.primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              CredentialsShareTexts.pageTitle,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (fullName.isNotEmpty)
                        Text(
                          fullName,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      if (fullName.isNotEmpty) const SizedBox(height: 6),
                      Text(
                        CredentialsShareTexts.subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
                      if (data.password.isEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          CredentialsShareTexts.noSensitiveData,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.secondaryText),
                        ),
                      ],
                      const SizedBox(height: 18),
                      _CredentialRow(
                        label: CredentialsShareTexts.usernameLabel,
                        value: data.username,
                        onCopy: () async {
                          await Clipboard.setData(
                            ClipboardData(text: data.username),
                          );
                          if (!context.mounted) return;
                          CustomSnackBar.showSuccess(
                            context,
                            CredentialsShareTexts.usernameCopied,
                          );
                        },
                      ),
                      if (data.email.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _CredentialRow(
                          label: CredentialsShareTexts.emailLabel,
                          value: data.email,
                          onCopy: () async {
                            await Clipboard.setData(
                              ClipboardData(text: data.email),
                            );
                            if (!context.mounted) return;
                            CustomSnackBar.showSuccess(
                              context,
                              CredentialsShareTexts.emailCopied,
                            );
                          },
                        ),
                      ],
                      if (data.password.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _CredentialRow(
                          label: CredentialsShareTexts.passwordLabel,
                          value: data.password,
                          onCopy: () async {
                            await Clipboard.setData(
                              ClipboardData(text: data.password),
                            );
                            if (!context.mounted) return;
                            CustomSnackBar.showSuccess(
                              context,
                              CredentialsShareTexts.passwordCopied,
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 24),
                      Center(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            const url = CredentialsShareTexts.novavilleUrl;
                            final uri = Uri.parse(url);
                            if (await url_launcher.canLaunchUrl(uri)) {
                              await url_launcher.launchUrl(
                                uri,
                                mode:
                                    url_launcher.LaunchMode.externalApplication,
                              );
                            } else {
                              CustomSnackBar.showError(
                                context,
                                CredentialsShareTexts.openSiteError,
                              );
                            }
                          },
                          icon: const Icon(Icons.open_in_new),
                          label: const Text(CredentialsShareTexts.openSiteLabel),
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
