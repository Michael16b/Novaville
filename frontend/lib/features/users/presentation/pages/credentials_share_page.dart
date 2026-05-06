import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/config/app_routes.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:frontend/constants/colors.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
      // Step 1: Normalize base64 padding
      final normalized = base64Url.normalize(shareRef.trim());

      // Step 2: Decode from base64
      final decodedBytes = base64Url.decode(normalized);

      // Step 3: Convert bytes to UTF-8 string
      final decodedJson = utf8.decode(decodedBytes);

      // Step 4: Parse JSON
      final decoded = jsonDecode(decodedJson);

      if (decoded is! Map<String, dynamic>) {
        // Invalid JSON structure
        return null;
      }

      String safeString(dynamic value) => value is String ? value : '';

      final firstName = safeString(decoded['first_name']);
      final lastName = safeString(decoded['last_name']);
      final username = safeString(decoded['username']);
      final email = safeString(decoded['email']);
      final password = safeString(
        decoded['temp_password'] ?? decoded['password'],
      );

      final hasAtLeastOneValue =
          firstName.isNotEmpty ||
          lastName.isNotEmpty ||
          username.isNotEmpty ||
          email.isNotEmpty;

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
    } on FormatException catch (e) {
      print('[CredentialsShare] Decode error: $e');
      return null;
    } catch (e) {
      print('[CredentialsShare] Decode error: $e');
      return null;
    }
  }

  Uri _buildRegisterUri(_ShareCredentialData data) {
    final queryParams = <String, String>{};
    if (data.firstName.isNotEmpty) queryParams['first_name'] = data.firstName;
    if (data.lastName.isNotEmpty) queryParams['last_name'] = data.lastName;
    if (data.username.isNotEmpty) queryParams['username'] = data.username;
    if (data.email.isNotEmpty) queryParams['email'] = data.email;
    if (data.password.isNotEmpty) queryParams['temp_password'] = data.password;

    return Uri(
      path: '/set-password',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  Future<_ShareCredentialData?> _loadShareData() async {
    final params = _collectShareParams();

    // Log collected parameters for debugging
    if (params.isEmpty) {
      print('[CredentialsShare] No parameters found in URL');
    } else {
      print('[CredentialsShare] Parameters collected: ${params.keys.toList()}');
    }

    final shareRef = params[BulkUserCreationTexts.shareReferenceKey];

    if (shareRef == null) {
      print(
        '[CredentialsShare] No share_ref parameter found (looking for: ${BulkUserCreationTexts.shareReferenceKey})',
      );
      print('[CredentialsShare] Available keys: ${params.keys.toList()}');
    } else {
      print('[CredentialsShare] Found share_ref (length: ${shareRef.length})');
    }

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

        final path = _buildRegisterUri(data).toString();
        final currentUri = Uri.base;
        final usesHashRouting = currentUri.fragment.startsWith('/');
        final fullUrl = usesHashRouting
            ? '${currentUri.scheme}://${currentUri.authority}${currentUri.path}#$path'
            : currentUri.resolve(path).toString();

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
                            child: const Icon(
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
                      const SizedBox(height: 8),
                      Text(
                        CredentialsShareTexts.registerHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.secondaryText,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
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
                      const SizedBox(height: 24),
                      Center(
                        child: QrImageView(
                          data: fullUrl,
                          version: QrVersions.auto,
                          size: 160.0,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppColors.primary,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => context.go(
                                _buildRegisterUri(data).toString(),
                              ),
                              icon: const Icon(Icons.lock_reset),
                              label: const Text(
                                CredentialsShareTexts.registerCta,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Tooltip(
                            message: CredentialsShareTexts.openInNewTabTooltip,
                            child: IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.primary.withOpacity(
                                  0.1,
                                ),
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.all(12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () async {
                                final uri = Uri.parse(fullUrl);
                                if (await url_launcher.canLaunchUrl(uri)) {
                                  await url_launcher.launchUrl(
                                    uri,
                                    mode: url_launcher
                                        .LaunchMode
                                        .externalApplication,
                                  );
                                }
                              },
                              icon: const Icon(Icons.open_in_new),
                            ),
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
      password: safeString(map['temp_password'] ?? map['password']),
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
