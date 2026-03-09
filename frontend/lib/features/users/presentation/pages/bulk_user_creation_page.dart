import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:csv/csv.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/constants/texts/texts_bulk_user_creation.dart';
import 'package:frontend/constants/texts/texts_general.dart';
import 'package:frontend/core/validation_patterns.dart';
import 'package:frontend/features/users/application/services/user_csv_compiler.dart';
import 'package:frontend/features/users/presentation/pages/web_drop_handler.dart';
import 'package:frontend/config/app_routes.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/design_systems/custom_snack_bar.dart';
import 'package:frontend/ui/widgets/styled_dialog.dart';
import 'package:frontend/features/users/data/models/user_role.dart';
import 'package:frontend/features/users/data/user_repository.dart';
import 'package:frontend/features/users/data/user_repository_factory.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';

class BulkUserCreationPage extends StatefulWidget {
  const BulkUserCreationPage({super.key, this.userRepository});

  final IUserRepository? userRepository;

  @override
  State<BulkUserCreationPage> createState() => _BulkUserCreationPageState();
}

enum _CreationMode { manual, csv }

enum _GridMode { auto, manual }

class _GridConfig {
  const _GridConfig({required this.columns, required this.rows});

  final int columns;
  final int rows;
}

class _BulkUserCreationPageState extends State<BulkUserCreationPage> {
  static const String _draftStorageKey = 'bulk_users_draft_v1';
  final _csvDropZoneKey = GlobalKey();
  final _gridColumnsController = TextEditingController(text: '3');
  final _gridRowsController = TextEditingController(text: '8');

  late final IUserRepository _repository;
  final _csvCompiler = const UserCsvCompiler();

  _CreationMode _creationMode = _CreationMode.manual;
  bool _isSubmitting = false;
  bool _isImportingCsv = false;
  bool _isDraggingCsv = false;
  _GridMode _gridMode = _GridMode.auto;
  bool _includeOneUserPdfFromGrouped = false;
  WebDropHandler? _webDropHandler;

  List<_DraftUser> _draftUsers = <_DraftUser>[];
  List<_CreatedCredential> _createdCredentials = <_CreatedCredential>[];
  final _manualCard = _ManualUserFormData();
  int? _editingDraftIndex;
  _ManualUserFormData? _editingDraftCard;

  @override
  void initState() {
    super.initState();
    _repository = widget.userRepository ?? createUserRepository();
    if (kIsWeb) {
      _webDropHandler = WebDropHandler(
        onHover: () {
          if (!mounted) {
            return;
          }
          setState(() {
            _isDraggingCsv = true;
          });
        },
        onLeave: () {
          if (!mounted) {
            return;
          }
          setState(() {
            _isDraggingCsv = false;
          });
        },
        onCsvDropped: (fileName, content) async {
          if (_creationMode != _CreationMode.csv) {
            return;
          }
          await _importCsvContent(content, sourceLabel: fileName);
        },
        shouldAcceptDrop: (x, y) => _isPointInsideCsvDropZone(x, y),
        onError: (message) {
          if (!mounted) {
            return;
          }
          CustomSnackBar.showError(context, message);
        },
      );
      _webDropHandler!.attach();
    }
    _loadDrafts();
  }

  bool _isPointInsideCsvDropZone(double x, double y) {
    if (_creationMode != _CreationMode.csv) {
      return false;
    }

    final zoneContext = _csvDropZoneKey.currentContext;
    if (zoneContext == null) {
      return false;
    }

    final renderObject = zoneContext.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return false;
    }

    final origin = renderObject.localToGlobal(Offset.zero);
    final rect = origin & renderObject.size;
    return rect.contains(Offset(x, y));
  }

  @override
  void dispose() {
    _manualCard.dispose();
    _editingDraftCard?.dispose();
    _webDropHandler?.dispose();
    _gridColumnsController.dispose();
    _gridRowsController.dispose();
    super.dispose();
  }

  Future<void> _loadDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftStorageKey);
    if (raw == null || raw.trim().isEmpty) {
      return;
    }

    try {
      final jsonList = jsonDecode(raw) as List<dynamic>;
      final loaded = jsonList
          .map((item) => _DraftUser.fromJson(item as Map<String, dynamic>))
          .toList();
      if (!mounted) {
        return;
      }
      setState(() {
        _draftUsers = loaded;
      });
      if (loaded.isNotEmpty) {
        CustomSnackBar.showSuccess(
          context,
          BulkUserCreationTexts.restoredFromCache(loaded.length),
        );
      }
    } catch (_) {
      await prefs.remove(_draftStorageKey);
    }
  }

  Future<void> _saveDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(
      _draftUsers.map((draft) => draft.toJson()).toList(),
    );
    await prefs.setString(_draftStorageKey, payload);
  }

  Future<void> _clearDrafts() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => StyledDialog(
        title: BulkUserCreationTexts.clearPendingTitle,
        icon: Icons.warning_amber_rounded,
        accentColor: AppColors.error,
        maxWidth: 420,
        actions: [
          StyledDialog.cancelButton(
            label: AppTextsGeneral.cancel,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          StyledDialog.destructiveButton(
            label: AppTextsGeneral.delete,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
        body: Text(
          BulkUserCreationTexts.clearPendingMessage,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );

    if (shouldClear != true || !mounted) {
      return;
    }

    setState(() {
      _draftUsers = <_DraftUser>[];
    });
    await _saveDrafts();
  }

  List<String> _validateDraftUser(_DraftUser draft, {int? ignoreIndex}) {
    final errors = <String>[];
    final firstName = draft.firstName.trim();
    final lastName = draft.lastName.trim();
    final username = draft.username.trim();
    final email = draft.email.trim();

    if (firstName.isEmpty) {
      errors.add(BulkUserCreationTexts.firstNameMissing);
    }
    if (lastName.isEmpty) {
      errors.add(BulkUserCreationTexts.lastNameMissing);
    }
    if (username.isEmpty) {
      errors.add(BulkUserCreationTexts.usernameMissing);
    }
    if (email.isEmpty) {
      errors.add(BulkUserCreationTexts.emailMissing);
    }
    if (email.isNotEmpty && !_isValidEmail(email)) {
      errors.add(BulkUserCreationTexts.emailInvalid);
    }
    if (username.contains(RegExp(r'\s'))) {
      errors.add(BulkUserCreationTexts.usernameInvalidWhitespace);
    }

    final normalizedUsername = username.toLowerCase();
    final normalizedEmail = email.toLowerCase();

    final hasUsernameDuplicate = _draftUsers.asMap().entries.any((entry) {
      if (ignoreIndex != null && entry.key == ignoreIndex) {
        return false;
      }
      return entry.value.username.toLowerCase() == normalizedUsername;
    });
    if (username.isNotEmpty && hasUsernameDuplicate) {
      errors.add(BulkUserCreationTexts.usernameAlreadyUsed);
    }

    final hasEmailDuplicate = _draftUsers.asMap().entries.any((entry) {
      if (ignoreIndex != null && entry.key == ignoreIndex) {
        return false;
      }
      return entry.value.email.toLowerCase() == normalizedEmail;
    });
    if (email.isNotEmpty && hasEmailDuplicate) {
      errors.add(BulkUserCreationTexts.emailAlreadyUsed);
    }

    return errors;
  }

  Future<void> _addManualCardToList() async {
    final draft = _DraftUser(
      firstName: _manualCard.firstNameController.text.trim(),
      lastName: _manualCard.lastNameController.text.trim(),
      username: _manualCard.usernameController.text.trim(),
      email: _manualCard.emailController.text.trim(),
      role: _manualCard.role,
    );

    final errors = _validateDraftUser(draft);
    if (errors.isNotEmpty) {
      CustomSnackBar.showError(context, errors.join(' • '));
      return;
    }

    setState(() {
      _draftUsers = <_DraftUser>[..._draftUsers, draft];
      _manualCard.clear();
    });
    await _saveDrafts();
    if (!mounted) {
      return;
    }
    CustomSnackBar.showSuccess(context, BulkUserCreationTexts.userAddedToList);
  }

  String _buildUsernameFromNames(String firstName, String lastName) {
    final cleanedFirstName = firstName.trim().toLowerCase();
    final cleanedLastName = lastName.trim().toLowerCase().replaceAll(' ', '');

    if (cleanedFirstName.isEmpty || cleanedLastName.isEmpty) {
      return '';
    }

    return '${cleanedFirstName[0]}$cleanedLastName';
  }

  void _applyAutoUsernameIfNeeded(_ManualUserFormData card) {
    if (card.usernameWasManuallyEdited) {
      return;
    }

    final suggestion = _buildUsernameFromNames(
      card.firstNameController.text,
      card.lastNameController.text,
    );

    if (suggestion == card.usernameController.text.trim()) {
      return;
    }

    card.isProgrammaticUsernameUpdate = true;
    card.usernameController.text = suggestion;
    card.usernameController.selection = TextSelection.collapsed(
      offset: card.usernameController.text.length,
    );
    card.isProgrammaticUsernameUpdate = false;
  }

  void _applyRandomUsernameSuggestion(_ManualUserFormData card) {
    final base = _buildUsernameFromNames(
      card.firstNameController.text,
      card.lastNameController.text,
    );
    final random = Random.secure();
    final suffix = (100 + random.nextInt(900)).toString();
    final suggestion = '${base.isEmpty ? 'user' : base}$suffix';

    card.isProgrammaticUsernameUpdate = true;
    card.usernameController.text = suggestion;
    card.usernameController.selection = TextSelection.collapsed(
      offset: card.usernameController.text.length,
    );
    card.isProgrammaticUsernameUpdate = false;
    card.usernameWasManuallyEdited = true;

    setState(() {});
  }

  void _startEditingDraft(int index) {
    _editingDraftCard?.dispose();
    final draft = _draftUsers[index];
    final editCard = _ManualUserFormData.fromDraft(draft);
    setState(() {
      _editingDraftIndex = index;
      _editingDraftCard = editCard;
    });
  }

  void _cancelEditingDraft() {
    _editingDraftCard?.dispose();
    setState(() {
      _editingDraftCard = null;
      _editingDraftIndex = null;
    });
  }

  Future<void> _saveEditingDraft() async {
    final index = _editingDraftIndex;
    final card = _editingDraftCard;
    if (index == null || card == null) {
      return;
    }

    final updated = _DraftUser(
      firstName: card.firstNameController.text.trim(),
      lastName: card.lastNameController.text.trim(),
      username: card.usernameController.text.trim(),
      email: card.emailController.text.trim(),
      role: card.role,
    );

    final errors = _validateDraftUser(updated, ignoreIndex: index);
    if (errors.isNotEmpty) {
      CustomSnackBar.showError(context, errors.join(' • '));
      return;
    }

    setState(() {
      _draftUsers[index] = updated;
    });
    await _saveDrafts();
    _cancelEditingDraft();
    if (!mounted) {
      return;
    }
    CustomSnackBar.showSuccess(context, BulkUserCreationTexts.userUpdated);
  }

  Future<void> _importCsv() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.single;
      if (file.bytes != null) {
        await _importCsvContent(
          utf8.decode(file.bytes!, allowMalformed: true),
          sourceLabel: file.name,
        );
      } else if (file.path != null) {
        await _importCsvContent(
          await File(file.path!).readAsString(),
          sourceLabel: file.name,
        );
      } else {
        throw Exception(BulkUserCreationTexts.unreadableCsvFile);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      CustomSnackBar.showError(context, error.toString());
    }
  }

  Future<void> _importCsvContent(
    String csvContent, {
    required String sourceLabel,
  }) async {
    setState(() {
      _isImportingCsv = true;
    });

    try {
      final compilation = _csvCompiler.compileFromContent(
        csvContent,
        existingUsernames: _draftUsers
            .map((entry) => entry.username.toLowerCase())
            .toSet(),
        existingEmails: _draftUsers
            .map((entry) => entry.email.toLowerCase())
            .toSet(),
      );

      if (compilation.errors.isNotEmpty) {
        if (!mounted) {
          return;
        }
        CustomSnackBar.showError(
          context,
          BulkUserCreationTexts.csvCompilationFailed(compilation.errors.length),
        );
        await _showCsvCompilationErrors(compilation.errors);
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _draftUsers = <_DraftUser>[
          ..._draftUsers,
          ...compilation.users.map(
            (user) => _DraftUser(
              firstName: user.firstName,
              lastName: user.lastName,
              username: user.username,
              email: user.email,
              role: user.role,
            ),
          ),
        ];
      });
      await _saveDrafts();

      CustomSnackBar.showSuccess(
        context,
        BulkUserCreationTexts.csvImported(
          sourceLabel,
          compilation.users.length,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      CustomSnackBar.showError(context, error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isImportingCsv = false;
        });
      }
    }
  }

  Future<void> _onCsvFilesDropped(DropDoneDetails details) async {
    if (details.files.isEmpty) {
      return;
    }

    final file = details.files.first;
    if (!file.name.toLowerCase().endsWith('.csv')) {
      CustomSnackBar.showError(context, BulkUserCreationTexts.csvOnlyDrop);
      return;
    }

    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        CustomSnackBar.showError(context, BulkUserCreationTexts.csvEmptyFile);
        return;
      }
      await _importCsvContent(
        utf8.decode(bytes, allowMalformed: true),
        sourceLabel: file.name,
      );
    } catch (_) {
      CustomSnackBar.showError(
        context,
        BulkUserCreationTexts.csvDropReadFailed,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDraggingCsv = false;
        });
      }
    }
  }

  Future<void> _downloadCsvExample() async {
    const example =
        'first_name,last_name,username,email,role\n'
        'Jean,Dupont,jdupont,jdupont@novaville.fr,citizen\n';

    await FilePicker.platform.saveFile(
      fileName: 'users_import_example.csv',
      bytes: Uint8List.fromList(utf8.encode(example)),
      type: FileType.custom,
      allowedExtensions: const ['csv'],
    );
  }

  Future<void> _showCsvCompilationErrors(
    List<CsvValidationError> errors,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StyledDialog(
          title: BulkUserCreationTexts.csvCompilationDialogTitle(
            errors.length,
          ),
          icon: Icons.error_outline,
          accentColor: AppColors.error,
          maxWidth: 720,
          actions: [
            StyledDialog.cancelButton(
              label: AppTextsGeneral.close,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
          body: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.highlight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  BulkUserCreationTexts.csvCompilationDialogMessage,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 320,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (var index = 0;
                          index < errors.length;
                          index++) ...[
                        Builder(
                          builder: (context) {
                            final error = errors[index];
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 14,
                                backgroundColor:
                                    AppColors.error.withValues(
                                  alpha: 0.15,
                                ),
                                child: Text(
                                  '${error.line}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              title: Text(error.message),
                              subtitle: Text(
                                BulkUserCreationTexts.csvLineAndColumn(
                                  error.line,
                                  error.column,
                                ),
                              ),
                            );
                          },
                        ),
                        if (index < errors.length - 1)
                          const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isValidEmail(String value) {
    return ValidationPatterns.email.hasMatch(value);
  }

  Future<void> _submitDrafts() async {
    if (_draftUsers.isEmpty) {
      CustomSnackBar.showError(
        context,
        BulkUserCreationTexts.addAtLeastOneUser,
      );
      return;
    }

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (context) => StyledDialog(
        title: BulkUserCreationTexts.finalValidationTitle,
        icon: Icons.check_circle_outline,
        maxWidth: 420,
        actions: [
          StyledDialog.cancelButton(
            label: AppTextsGeneral.cancel,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          StyledDialog.primaryButton(
            label: BulkUserCreationTexts.create,
            icon: Icons.send_outlined,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
        body: Text(
          BulkUserCreationTexts.finalValidationMessage(_draftUsers.length),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );

    if (shouldSubmit != true) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final successfulDrafts = <_DraftUser>[];
    final createdCredentials = <_CreatedCredential>[];
    final errors = <String>[];

    for (final draft in _draftUsers) {
      final generatedPassword = _generatePassword();
      try {
        await _repository.createUser(
          username: draft.username,
          email: draft.email,
          firstName: draft.firstName,
          lastName: draft.lastName,
          password: generatedPassword,
          role: draft.role,
        );

        successfulDrafts.add(draft);
        createdCredentials.add(
          _CreatedCredential(
            firstName: draft.firstName,
            lastName: draft.lastName,
            email: draft.email,
            username: draft.username,
            password: generatedPassword,
          ),
        );
      } catch (error) {
        errors.add('${draft.username}: $error');
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _draftUsers = _draftUsers
          .where((draft) => !successfulDrafts.contains(draft))
          .toList();
      _createdCredentials = <_CreatedCredential>[
        ..._createdCredentials,
        ...createdCredentials,
      ];
      _isSubmitting = false;
    });
    await _saveDrafts();

    if (createdCredentials.isNotEmpty) {
      CustomSnackBar.showSuccess(
        context,
        BulkUserCreationTexts.createdWithSuccess(createdCredentials.length),
      );
    }

    if (errors.isNotEmpty) {
      CustomSnackBar.showError(
        context,
        BulkUserCreationTexts.creationFailures(errors.length),
      );
      await showDialog<void>(
        context: context,
        builder: (context) => StyledDialog(
          title: BulkUserCreationTexts.creationErrorsTitle,
          icon: Icons.error_outline,
          accentColor: AppColors.error,
          maxWidth: 540,
          actions: [
            StyledDialog.cancelButton(
              label: AppTextsGeneral.close,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
          body: Text(
            errors.join('\n'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
  }

  String _generatePassword() {
    const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
    const digits = '23456789';
    const all = '$letters$digits';

    final random = Random.secure();
    final chars = <String>[
      letters[random.nextInt(letters.length)],
      digits[random.nextInt(digits.length)],
    ];

    while (chars.length < 8) {
      chars.add(all[random.nextInt(all.length)]);
    }

    chars.shuffle(random);
    return chars.join();
  }

  String _buildPdfDateSuffix() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final year = now.year.toString();
    return '$day$month$year';
  }

  String _buildPdfFileName(String? suffix) {
    final datePart = _buildPdfDateSuffix();
    final suffixPart = (suffix == null || suffix.isEmpty) ? '' : suffix;
    return '${BulkUserCreationTexts.pdfFileBaseName}${datePart}$suffixPart.pdf';
  }

  _GridConfig _resolveAutoGridConfig(int itemCount) {
    if (itemCount <= 2) {
      return const _GridConfig(columns: 1, rows: 2);
    }
    if (itemCount <= 4) {
      return const _GridConfig(columns: 2, rows: 2);
    }
    if (itemCount <= 6) {
      return const _GridConfig(columns: 2, rows: 3);
    }
    if (itemCount <= 9) {
      return const _GridConfig(columns: 3, rows: 3);
    }
    if (itemCount <= 12) {
      return const _GridConfig(columns: 3, rows: 4);
    }
    if (itemCount <= 16) {
      return const _GridConfig(columns: 4, rows: 4);
    }
    return const _GridConfig(columns: 5, rows: 5);
  }

  String _createCredentialShareLink(_CreatedCredential credential) {
    final payload = jsonEncode({
      'v': 1,
      'first_name': credential.firstName,
      'last_name': credential.lastName,
      'username': credential.username,
      'email': credential.email ?? '',
      'password': credential.password,
    });
    final encodedShareRef = base64Url
        .encode(utf8.encode(payload))
        .replaceAll('=', '');

    final routeUri = Uri(
      path: AppRoutes.credentialsShare,
      queryParameters: {
        BulkUserCreationTexts.shareReferenceKey: encodedShareRef,
      },
    );

    final currentUri = Uri.base;
    final usesHashRouting = currentUri.fragment.startsWith('/');

    if (usesHashRouting) {
      return '${currentUri.scheme}://${currentUri.authority}${currentUri.path}#${routeUri.toString()}';
    }

    return currentUri.resolveUri(routeUri).toString();
  }

  Future<void> _copyCredentialLink(_CreatedCredential credential) async {
    try {
      final link = _createCredentialShareLink(credential);
      await Clipboard.setData(ClipboardData(text: link));
      if (!mounted) {
        return;
      }
      CustomSnackBar.showSuccess(context, BulkUserCreationTexts.linkCopied);
    } catch (_) {
      if (!mounted) {
        return;
      }
      CustomSnackBar.showError(
        context,
        BulkUserCreationTexts.linkGenerationFailed,
      );
    }
  }

  Future<void> _downloadPdfFile({
    required List<int> bytes,
    required String fileName,
  }) async {
    try {
      await FilePicker.platform.saveFile(
        fileName: fileName,
        bytes: Uint8List.fromList(bytes),
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (!mounted) {
        return;
      }
      CustomSnackBar.showSuccess(context, BulkUserCreationTexts.pdfDownloaded);
    } catch (_) {
      if (!mounted) {
        return;
      }
      CustomSnackBar.showError(context, BulkUserCreationTexts.pdfDownloadError);
    }
  }

  Future<pw.MemoryImage?> _loadPdfLogo() async {
    try {
      final logoBytes = await rootBundle.load('assets/images/logo.png');
      return pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  Future<_PdfFontPack?> _loadPdfFonts() async {
    try {
      final regular = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Montserrat-Regular.ttf'),
      );
      final bold = pw.Font.ttf(
        await rootBundle.load('assets/fonts/Montserrat-Bold.ttf'),
      );
      return _PdfFontPack(base: regular, bold: bold);
    } catch (_) {
      return null;
    }
  }

  pw.Widget _buildCredentialPdfCard(
    _CreatedCredential credential, {
    required PdfColor primary,
    required PdfColor accent,
    required PdfColor background,
    pw.MemoryImage? logo,
    bool compact = false,
  }) {
    final titleSize = compact ? 11.0 : 15.0;
    final valueSize = compact ? 9.5 : 11.5;
    final nameSize = compact ? 12.0 : 17.0;

    pw.Widget lineItem(String label, String value) {
      return pw.Container(
        margin: pw.EdgeInsets.only(bottom: compact ? 5 : 8),
        padding: pw.EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 6 : 8,
        ),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: compact ? 54 : 76,
              child: pw.Text(
                label,
                style: pw.TextStyle(
                  fontSize: compact ? 8.5 : 9.5,
                  color: PdfColors.grey700,
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: valueSize,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return pw.Container(
      padding: pw.EdgeInsets.all(compact ? 10 : 14),
      decoration: pw.BoxDecoration(
        color: background,
        borderRadius: pw.BorderRadius.circular(compact ? 10 : 14),
        border: pw.Border.all(color: accent, width: 1.2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              if (logo != null)
                pw.Container(
                  width: compact ? 20 : 30,
                  height: compact ? 20 : 30,
                  margin: pw.EdgeInsets.only(right: compact ? 6 : 10),
                  child: pw.Image(logo),
                ),
              pw.Text(
                BulkUserCreationTexts.pdfBrand,
                style: pw.TextStyle(
                  color: primary,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: titleSize,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: compact ? 6 : 10),
          pw.Text(
            '${credential.firstName} ${credential.lastName}',
            style: pw.TextStyle(
              fontSize: nameSize,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
          pw.SizedBox(height: compact ? 6 : 10),
          lineItem(BulkUserCreationTexts.pdfEmailLabel, credential.email ?? ''),
          lineItem(BulkUserCreationTexts.pdfUsernameLabel, credential.username),
          lineItem(BulkUserCreationTexts.pdfPasswordLabel, credential.password),
        ],
      ),
    );
  }

  Future<void> _generateSchoolGridPdf() async {
    if (_createdCredentials.isEmpty) {
      CustomSnackBar.showError(
        context,
        BulkUserCreationTexts.noCreatedUsersToExport,
      );
      return;
    }

    final gridConfig = _gridMode == _GridMode.auto
        ? _resolveAutoGridConfig(_createdCredentials.length)
        : _GridConfig(
            columns: (int.tryParse(_gridColumnsController.text.trim()) ?? 3)
                .clamp(1, 8),
            rows: (int.tryParse(_gridRowsController.text.trim()) ?? 8).clamp(
              1,
              20,
            ),
          );
    final safeColumns = gridConfig.columns;
    final safeRows = gridConfig.rows;
    final slotsPerPage = safeColumns * safeRows;

    final document = pw.Document();
    final primary = PdfColor.fromInt(AppColors.primary.toARGB32());
    final accent = PdfColor.fromInt(AppColors.secondary.toARGB32());
    final background = PdfColors.white;
    final logo = await _loadPdfLogo();
    final fontPack = await _loadPdfFonts();
    final theme = fontPack == null
        ? null
        : pw.ThemeData.withFont(base: fontPack.base, bold: fontPack.bold);

    final horizontalSpacing = 10.0;
    final cardWidth =
        (PdfPageFormat.a4.availableWidth -
            (horizontalSpacing * (safeColumns - 1))) /
        safeColumns;

    for (
      var start = 0;
      start < _createdCredentials.length;
      start += slotsPerPage
    ) {
      final pageItems = _createdCredentials
          .skip(start)
          .take(slotsPerPage)
          .toList();

      document.addPage(
        pw.Page(
          margin: const pw.EdgeInsets.all(20),
          theme: theme,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  BulkUserCreationTexts.groupedPdfTitle,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: primary,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  BulkUserCreationTexts.groupedPdfSubtitle,
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 12),
                pw.Wrap(
                  spacing: horizontalSpacing,
                  runSpacing: 10,
                  children: [
                    for (final item in pageItems)
                      pw.SizedBox(
                        width: cardWidth,
                        child: _buildCredentialPdfCard(
                          item,
                          primary: primary,
                          accent: accent,
                          background: background,
                          logo: logo,
                          compact: pageItems.length > 4,
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    await _downloadPdfFile(
      bytes: await document.save(),
      fileName: _buildPdfFileName(BulkUserCreationTexts.groupedPdfSuffix),
    );

    if (_includeOneUserPdfFromGrouped) {
      await _generateOneUserPerPagePdf();
    }
  }

  Future<void> _generateOneUserPerPagePdf() async {
    if (_createdCredentials.isEmpty) {
      CustomSnackBar.showError(
        context,
        BulkUserCreationTexts.noCreatedUsersToExport,
      );
      return;
    }

    final document = pw.Document();
    final primary = PdfColor.fromInt(AppColors.primary.toARGB32());
    final accent = PdfColor.fromInt(AppColors.secondary.toARGB32());
    final background = PdfColors.white;
    final logo = await _loadPdfLogo();
    final fontPack = await _loadPdfFonts();
    final theme = fontPack == null
        ? null
        : pw.ThemeData.withFont(base: fontPack.base, bold: fontPack.bold);

    for (final credential in _createdCredentials) {
      document.addPage(
        pw.Page(
          margin: const pw.EdgeInsets.all(28),
          theme: theme,
          build: (context) {
            return pw.Center(
              child: pw.SizedBox(
                width: PdfPageFormat.a4.availableWidth,
                child: _buildCredentialPdfCard(
                  credential,
                  primary: primary,
                  accent: accent,
                  background: background,
                  logo: logo,
                ),
              ),
            );
          },
        ),
      );
    }

    await _downloadPdfFile(
      bytes: await document.save(),
      fileName: _buildPdfFileName(BulkUserCreationTexts.individualPdfSuffix),
    );
  }

  Future<void> _generateSingleUserPdf(_CreatedCredential credential) async {
    final document = pw.Document();
    final primary = PdfColor.fromInt(AppColors.primary.toARGB32());
    final accent = PdfColor.fromInt(AppColors.secondary.toARGB32());
    final background = PdfColors.white;
    final logo = await _loadPdfLogo();
    final fontPack = await _loadPdfFonts();
    final theme = fontPack == null
        ? null
        : pw.ThemeData.withFont(base: fontPack.base, bold: fontPack.bold);

    document.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(28),
        theme: theme,
        build: (context) {
          return pw.Center(
            child: pw.SizedBox(
              width: 460,
              child: _buildCredentialPdfCard(
                credential,
                primary: primary,
                accent: accent,
                background: background,
                logo: logo,
              ),
            ),
          );
        },
      ),
    );

    await _downloadPdfFile(
      bytes: await document.save(),
      fileName:
          '${BulkUserCreationTexts.pdfFileBaseName}${_buildPdfDateSuffix()}${BulkUserCreationTexts.oneUserPdfSuffix}_${credential.username}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: BulkUserCreationTexts.backTooltip,
                ),
                Expanded(
                  child: Text(
                    BulkUserCreationTexts.pageTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(BulkUserCreationTexts.pageSubtitle),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    Text(
                      BulkUserCreationTexts.pendingListCount(
                        _draftUsers.length,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _draftUsers.isEmpty ? null : _clearDrafts,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text(BulkUserCreationTexts.reset),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SegmentedButton<_CreationMode>(
                  segments: const [
                    ButtonSegment<_CreationMode>(
                      value: _CreationMode.manual,
                      label: Text(BulkUserCreationTexts.manualInput),
                      icon: Icon(Icons.edit),
                    ),
                    ButtonSegment<_CreationMode>(
                      value: _CreationMode.csv,
                      label: Text(BulkUserCreationTexts.csvImport),
                      icon: Icon(Icons.upload_file),
                    ),
                  ],
                  selected: {_creationMode},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _creationMode = selection.first;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_creationMode == _CreationMode.manual) _buildManualSection(),
            if (_creationMode == _CreationMode.csv) _buildCsvSection(),
            const SizedBox(height: 12),
            _buildDraftListSection(),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitDrafts,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle),
              label: Text(
                _isSubmitting
                    ? BulkUserCreationTexts.creatingInProgress
                    : BulkUserCreationTexts.validateAndCreate(
                        _draftUsers.length,
                      ),
              ),
            ),
            const SizedBox(height: 18),
            if (_createdCredentials.isNotEmpty) _buildCredentialsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildManualSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              BulkUserCreationTexts.manualSectionTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildEditableUserCard(
              title: BulkUserCreationTexts.newUserTitle,
              card: _manualCard,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _addManualCardToList,
                icon: const Icon(Icons.add),
                label: const Text(BulkUserCreationTexts.addCard),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableUserCard({
    required String title,
    required _ManualUserFormData card,
  }) {
    final allowedRoles = <UserRole>[
      UserRole.citizen,
      UserRole.elected,
      UserRole.agent,
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 900;

            Widget roleField() {
              return DropdownButtonFormField<UserRole>(
                initialValue: card.role,
                decoration: const InputDecoration(
                  labelText: BulkUserCreationTexts.roleLabel,
                ),
                items: allowedRoles
                    .map(
                      (role) => DropdownMenuItem<UserRole>(
                        value: role,
                        child: Text(role.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    card.role = value;
                  });
                },
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                if (isCompact) ...[
                  TextField(
                    controller: card.firstNameController,
                    decoration: const InputDecoration(
                      labelText: BulkUserCreationTexts.firstNameLabel,
                    ),
                    onChanged: (_) {
                      _applyAutoUsernameIfNeeded(card);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: card.lastNameController,
                    decoration: const InputDecoration(
                      labelText: BulkUserCreationTexts.lastNameLabel,
                    ),
                    onChanged: (_) {
                      _applyAutoUsernameIfNeeded(card);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: card.usernameController,
                    decoration: InputDecoration(
                      labelText: BulkUserCreationTexts.usernameLabel,
                      suffixIcon: IconButton(
                        tooltip: BulkUserCreationTexts.randomUsernameTooltip,
                        onPressed: () => _applyRandomUsernameSuggestion(card),
                        icon: const Icon(Icons.casino_outlined),
                      ),
                    ),
                    onChanged: (value) {
                      if (card.isProgrammaticUsernameUpdate) {
                        return;
                      }
                      card.usernameWasManuallyEdited = value.trim().isNotEmpty;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: card.emailController,
                    decoration: const InputDecoration(
                      labelText: BulkUserCreationTexts.emailLabel,
                    ),
                  ),
                  const SizedBox(height: 10),
                  roleField(),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: card.firstNameController,
                          decoration: const InputDecoration(
                            labelText: BulkUserCreationTexts.firstNameLabel,
                          ),
                          onChanged: (_) {
                            _applyAutoUsernameIfNeeded(card);
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: card.lastNameController,
                          decoration: const InputDecoration(
                            labelText: BulkUserCreationTexts.lastNameLabel,
                          ),
                          onChanged: (_) {
                            _applyAutoUsernameIfNeeded(card);
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: card.usernameController,
                          decoration: InputDecoration(
                            labelText: BulkUserCreationTexts.usernameLabel,
                            suffixIcon: IconButton(
                              tooltip:
                                  BulkUserCreationTexts.randomUsernameTooltip,
                              onPressed: () =>
                                  _applyRandomUsernameSuggestion(card),
                              icon: const Icon(Icons.casino_outlined),
                            ),
                          ),
                          onChanged: (value) {
                            if (card.isProgrammaticUsernameUpdate) {
                              return;
                            }
                            card.usernameWasManuallyEdited = value
                                .trim()
                                .isNotEmpty;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: card.emailController,
                          decoration: const InputDecoration(
                            labelText: BulkUserCreationTexts.emailLabel,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: roleField()),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCsvSection() {
    final dropArea = AnimatedContainer(
      key: _csvDropZoneKey,
      duration: const Duration(milliseconds: 150),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: _isDraggingCsv
            ? AppColors.highlight.withValues(alpha: 0.28)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDraggingCsv ? AppColors.primary : AppColors.secondaryText,
          width: _isDraggingCsv ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            _isDraggingCsv
                ? Icons.file_download_done
                : Icons.file_upload_outlined,
            size: 48,
            color: AppColors.primary,
          ),
          const SizedBox(height: 8),
          Text(
            BulkUserCreationTexts.csvDropHere,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Text(
            BulkUserCreationTexts.or,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _isImportingCsv ? null : _importCsv,
            icon: _isImportingCsv
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file),
            label: const Text(BulkUserCreationTexts.selectFile),
          ),
        ],
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              BulkUserCreationTexts.importCsvTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (kIsWeb)
              dropArea
            else
              DropTarget(
                onDragEntered: (_) {
                  setState(() {
                    _isDraggingCsv = true;
                  });
                },
                onDragExited: (_) {
                  setState(() {
                    _isDraggingCsv = false;
                  });
                },
                onDragDone: _onCsvFilesDropped,
                child: dropArea,
              ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _downloadCsvExample,
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  BulkUserCreationTexts.downloadCsvExample,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftListSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              BulkUserCreationTexts.pendingUsersTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_draftUsers.isEmpty)
              const Text(BulkUserCreationTexts.noPendingUsers)
            else
              Column(
                children: [
                  for (var index = 0; index < _draftUsers.length; index++) ...[
                    _buildPendingUserCard(index, _draftUsers[index]),
                    if (index < _draftUsers.length - 1)
                      const SizedBox(height: 10),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingUserCard(int index, _DraftUser draft) {
    final isEditing = _editingDraftIndex == index && _editingDraftCard != null;

    if (isEditing) {
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEditableUserCard(
                title: BulkUserCreationTexts.editUserTitle(index + 1),
                card: _editingDraftCard!,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _cancelEditingDraft,
                    child: const Text(AppTextsGeneral.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _saveEditingDraft,
                    icon: const Icon(Icons.save),
                    label: const Text(AppTextsGeneral.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.highlight,
              child: Icon(Icons.person, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${draft.firstName} ${draft.lastName}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${draft.username} • ${draft.email} • ${draft.role.label}',
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: AppTextsGeneral.edit,
              onPressed: () => _startEditingDraft(index),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: AppTextsGeneral.delete,
              onPressed: () async {
                if (_editingDraftIndex == index) {
                  _cancelEditingDraft();
                }
                setState(() {
                  _draftUsers.removeAt(index);
                  if (_editingDraftIndex != null &&
                      _editingDraftIndex! > index) {
                    _editingDraftIndex = _editingDraftIndex! - 1;
                  }
                });
                await _saveDrafts();
              },
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              BulkUserCreationTexts.credentialsSectionTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DropdownButton<_GridMode>(
                  value: _gridMode,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _gridMode = value;
                    });
                  },
                  items: const [
                    DropdownMenuItem(
                      value: _GridMode.auto,
                      child: Text(BulkUserCreationTexts.gridModeAuto),
                    ),
                    DropdownMenuItem(
                      value: _GridMode.manual,
                      child: Text(BulkUserCreationTexts.gridModeManual),
                    ),
                  ],
                ),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _gridColumnsController,
                    enabled: _gridMode == _GridMode.manual,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: BulkUserCreationTexts.columnsLabel,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _gridRowsController,
                    enabled: _gridMode == _GridMode.manual,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: BulkUserCreationTexts.rowsLabel,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _generateSchoolGridPdf,
                  icon: const Icon(Icons.grid_view),
                  label: const Text(BulkUserCreationTexts.groupedPdfButton),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                BulkUserCreationTexts.includeIndividualPdfOption,
              ),
              value: _includeOneUserPdfFromGrouped,
              onChanged: (value) {
                setState(() {
                  _includeOneUserPdfFromGrouped = value;
                });
              },
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                for (
                  var index = 0;
                  index < _createdCredentials.length;
                  index++
                ) ...[
                  Builder(
                    builder: (context) {
                      final credential = _createdCredentials[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${credential.firstName} ${credential.lastName}',
                        ),
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              tooltip: BulkUserCreationTexts.copyLinkTooltip,
                              onPressed: () => _copyCredentialLink(credential),
                              icon: const Icon(Icons.link),
                            ),
                            IconButton(
                              tooltip:
                                  BulkUserCreationTexts.downloadUserPdfTooltip,
                              onPressed: () =>
                                  _generateSingleUserPdf(credential),
                              icon: const Icon(Icons.picture_as_pdf),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  if (index < _createdCredentials.length - 1)
                    const Divider(height: 1),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualUserFormData {
  _ManualUserFormData()
    : role = UserRole.citizen,
      usernameWasManuallyEdited = false,
      isProgrammaticUsernameUpdate = false;

  _ManualUserFormData.fromDraft(_DraftUser draft)
    : role = draft.role,
      usernameWasManuallyEdited = true,
      isProgrammaticUsernameUpdate = false {
    firstNameController.text = draft.firstName;
    lastNameController.text = draft.lastName;
    usernameController.text = draft.username;
    emailController.text = draft.email;
  }

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  UserRole role;
  bool usernameWasManuallyEdited;
  bool isProgrammaticUsernameUpdate;

  void clear() {
    firstNameController.clear();
    lastNameController.clear();
    usernameController.clear();
    emailController.clear();
    role = UserRole.citizen;
    usernameWasManuallyEdited = false;
    isProgrammaticUsernameUpdate = false;
  }

  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
  }
}

class _DraftUser {
  const _DraftUser({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.role,
  });

  factory _DraftUser.fromJson(Map<String, dynamic> json) {
    return _DraftUser(
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      role: UserRole.fromString(json['role'] as String),
    );
  }

  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final UserRole role;

  _DraftUser copyWith({
    String? firstName,
    String? lastName,
    String? username,
    String? email,
    UserRole? role,
  }) {
    return _DraftUser(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'email': email,
      'role': role.toJson(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _DraftUser &&
        other.username.toLowerCase() == username.toLowerCase() &&
        other.email.toLowerCase() == email.toLowerCase();
  }

  @override
  int get hashCode => Object.hash(username.toLowerCase(), email.toLowerCase());
}

class _CreatedCredential {
  const _CreatedCredential({
    required this.firstName,
    required this.lastName,
    this.email,
    required this.username,
    required this.password,
  });

  final String firstName;
  final String lastName;
  final String? email;
  final String username;
  final String password;
}

class _PdfFontPack {
  const _PdfFontPack({required this.base, required this.bold});

  final pw.Font base;
  final pw.Font bold;
}
