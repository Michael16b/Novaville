import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:csv/csv.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/features/users/presentation/pages/web_drop_handler.dart';
import 'package:frontend/config/app_routes.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/design_systems/custom_snack_bar.dart';
import 'package:frontend/features/users/data/models/user_role.dart';
import 'package:frontend/features/users/data/user_repository.dart';
import 'package:frontend/features/users/data/user_repository_factory.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BulkUserCreationPage extends StatefulWidget {
  const BulkUserCreationPage({super.key, this.userRepository});

  final IUserRepository? userRepository;

  @override
  State<BulkUserCreationPage> createState() => _BulkUserCreationPageState();
}

enum _CreationMode { manual, csv }

class _BulkUserCreationPageState extends State<BulkUserCreationPage> {
  static const String _draftStorageKey = 'bulk_users_draft_v1';
  final _csvDropZoneKey = GlobalKey();
  final _gridColumnsController = TextEditingController(text: '3');
  final _gridRowsController = TextEditingController(text: '8');

  late final IUserRepository _repository;

  _CreationMode _creationMode = _CreationMode.manual;
  bool _isSubmitting = false;
  bool _isImportingCsv = false;
  bool _isDraggingCsv = false;
  WebDropHandler? _webDropHandler;

  List<_DraftUser> _draftUsers = <_DraftUser>[];
  List<_CreatedCredential> _createdCredentials = <_CreatedCredential>[];
  late List<_ManualUserFormData> _manualCards;

  @override
  void initState() {
    super.initState();
    _repository = widget.userRepository ?? createUserRepository();
    _manualCards = <_ManualUserFormData>[_ManualUserFormData()];
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
    for (final card in _manualCards) {
      card.dispose();
    }
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
          '${loaded.length} utilisateur(s) restauré(s) depuis le cache local.',
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
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la liste en attente'),
        content: const Text(
          'Voulez-vous supprimer tous les utilisateurs en attente de création ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
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

  void _addManualCard() {
    setState(() {
      _manualCards = <_ManualUserFormData>[
        ..._manualCards,
        _ManualUserFormData(),
      ];
    });
  }

  void _removeManualCard(int index) {
    if (_manualCards.length == 1) {
      return;
    }
    final card = _manualCards[index];
    setState(() {
      _manualCards.removeAt(index);
    });
    card.dispose();
  }

  Future<void> _addManualCardsToList() async {
    final errors = <String>[];
    final currentUsernames = _draftUsers
        .map((entry) => entry.username.toLowerCase())
        .toSet();
    final currentEmails = _draftUsers
        .map((entry) => entry.email.toLowerCase())
        .toSet();

    final newUsers = <_DraftUser>[];
    final seenInCardsUsernames = <String>{};
    final seenInCardsEmails = <String>{};

    for (var i = 0; i < _manualCards.length; i++) {
      final card = _manualCards[i];
      final lineLabel = 'Carte ${i + 1}';
      final firstName = card.firstNameController.text.trim();
      final lastName = card.lastNameController.text.trim();
      final username = card.usernameController.text.trim();
      final email = card.emailController.text.trim();

      final isEmpty =
          firstName.isEmpty &&
          lastName.isEmpty &&
          username.isEmpty &&
          email.isEmpty;
      if (isEmpty) {
        continue;
      }

      if (firstName.isEmpty) {
        errors.add('$lineLabel • first_name manquant');
      }
      if (lastName.isEmpty) {
        errors.add('$lineLabel • last_name manquant');
      }
      if (username.isEmpty) {
        errors.add('$lineLabel • username manquant');
      }
      if (email.isEmpty) {
        errors.add('$lineLabel • email manquant');
      }
      if (email.isNotEmpty && !_isValidEmail(email)) {
        errors.add('$lineLabel • email invalide');
      }

      final normalizedUsername = username.toLowerCase();
      final normalizedEmail = email.toLowerCase();
      if (username.isNotEmpty &&
          (currentUsernames.contains(normalizedUsername) ||
              seenInCardsUsernames.contains(normalizedUsername))) {
        errors.add('$lineLabel • username déjà utilisé');
      }
      if (email.isNotEmpty &&
          (currentEmails.contains(normalizedEmail) ||
              seenInCardsEmails.contains(normalizedEmail))) {
        errors.add('$lineLabel • email déjà utilisé');
      }

      if (errors.any((error) => error.startsWith(lineLabel))) {
        continue;
      }

      seenInCardsUsernames.add(normalizedUsername);
      seenInCardsEmails.add(normalizedEmail);
      newUsers.add(
        _DraftUser(
          firstName: firstName,
          lastName: lastName,
          username: username,
          email: email,
          role: card.role,
        ),
      );
    }

    if (errors.isNotEmpty) {
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Validation des cartes impossible'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(child: Text(errors.join('\n'))),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
      return;
    }

    if (newUsers.isEmpty) {
      CustomSnackBar.showError(
        context,
        'Remplissez au moins une carte utilisateur.',
      );
      return;
    }

    for (final card in _manualCards) {
      card.dispose();
    }

    setState(() {
      _draftUsers = <_DraftUser>[..._draftUsers, ...newUsers];
      _manualCards = <_ManualUserFormData>[_ManualUserFormData()];
    });
    await _saveDrafts();
    if (!mounted) {
      return;
    }
    CustomSnackBar.showSuccess(
      context,
      '${newUsers.length} utilisateur(s) ajouté(s) à la liste.',
    );
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
        throw Exception('Fichier CSV illisible');
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
      final rows = const CsvToListConverter(
        shouldParseNumbers: false,
        eol: '\n',
      ).convert(csvContent);

      if (rows.isEmpty) {
        throw Exception('Le fichier CSV est vide.');
      }

      final compilation = _compileCsv(rows);

      if (compilation.errors.isNotEmpty) {
        if (!mounted) {
          return;
        }
        CustomSnackBar.showError(
          context,
          'Compilation CSV échouée (${compilation.errors.length} erreur(s)).',
        );
        await _showCsvCompilationErrors(compilation.errors);
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _draftUsers = <_DraftUser>[..._draftUsers, ...compilation.drafts];
      });
      await _saveDrafts();

      CustomSnackBar.showSuccess(
        context,
        '$sourceLabel: ${compilation.drafts.length} utilisateur(s) importé(s).',
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
      CustomSnackBar.showError(context, 'Déposez un fichier .csv uniquement.');
      return;
    }

    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        CustomSnackBar.showError(context, 'Le fichier CSV est vide.');
        return;
      }
      await _importCsvContent(
        utf8.decode(bytes, allowMalformed: true),
        sourceLabel: file.name,
      );
    } catch (_) {
      CustomSnackBar.showError(
        context,
        'Lecture du fichier déposé impossible.',
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

  _CsvCompilationResult _compileCsv(List<List<dynamic>> rows) {
    final errors = <_CsvValidationError>[];
    final drafts = <_DraftUser>[];

    final headers = rows.first
        .map((cell) => cell.toString().trim().toLowerCase())
        .toList();

    int indexOfHeader(String key) => headers.indexOf(key);

    final firstNameIndex = indexOfHeader('first_name');
    final lastNameIndex = indexOfHeader('last_name');
    final usernameIndex = indexOfHeader('username');
    final emailIndex = indexOfHeader('email');
    final roleIndex = indexOfHeader('role');

    void addHeaderError(String column, String message) {
      errors.add(
        _CsvValidationError(line: 1, column: column, message: message),
      );
    }

    if (firstNameIndex < 0) {
      addHeaderError('first_name', 'Colonne obligatoire manquante');
    }
    if (lastNameIndex < 0) {
      addHeaderError('last_name', 'Colonne obligatoire manquante');
    }
    if (usernameIndex < 0) {
      addHeaderError('username', 'Colonne obligatoire manquante');
    }
    if (emailIndex < 0) {
      addHeaderError('email', 'Colonne obligatoire manquante');
    }

    if (errors.isNotEmpty) {
      return _CsvCompilationResult(drafts: drafts, errors: errors);
    }

    String cellAt(List<dynamic> row, int index) {
      if (index < 0 || index >= row.length) {
        return '';
      }
      return row[index].toString().trim();
    }

    final existingUsernames = _draftUsers
        .map((entry) => entry.username.toLowerCase())
        .toSet();
    final existingEmails = _draftUsers
        .map((entry) => entry.email.toLowerCase())
        .toSet();

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      final lineNumber = i + 1;

      final firstName = cellAt(row, firstNameIndex);
      final lastName = cellAt(row, lastNameIndex);
      final username = cellAt(row, usernameIndex);
      final email = cellAt(row, emailIndex);
      final roleRaw = roleIndex >= 0 ? cellAt(row, roleIndex) : '';

      if (firstName.isEmpty &&
          lastName.isEmpty &&
          username.isEmpty &&
          email.isEmpty &&
          roleRaw.isEmpty) {
        continue;
      }

      void addError(String column, String message) {
        errors.add(
          _CsvValidationError(
            line: lineNumber,
            column: column,
            message: message,
          ),
        );
      }

      if (firstName.isEmpty) {
        addError('first_name', 'Valeur obligatoire manquante');
      }
      if (lastName.isEmpty) {
        addError('last_name', 'Valeur obligatoire manquante');
      }
      if (username.isEmpty) {
        addError('username', 'Valeur obligatoire manquante');
      }
      if (email.isEmpty) {
        addError('email', 'Valeur obligatoire manquante');
      }

      if (email.isNotEmpty && !_isValidEmail(email)) {
        addError('email', 'Format invalide');
      }

      if (username.contains(' ')) {
        addError('username', 'Ne doit pas contenir d\'espace');
      }

      final normalizedUsername = username.toLowerCase();
      final normalizedEmail = email.toLowerCase();

      if (username.isNotEmpty &&
          existingUsernames.contains(normalizedUsername)) {
        addError('username', 'Doublon détecté (liste actuelle/fichier)');
      }
      if (email.isNotEmpty && existingEmails.contains(normalizedEmail)) {
        addError('email', 'Doublon détecté (liste actuelle/fichier)');
      }

      if (roleRaw.isNotEmpty) {
        if (roleRaw != roleRaw.toLowerCase()) {
          addError(
            'role',
            'Le rôle doit être en minuscule (ex: citizen, elected, agent)',
          );
        }

        const allowedRoles = {'citizen', 'elected', 'agent'};
        if (!allowedRoles.contains(roleRaw.toLowerCase())) {
          addError(
            'role',
            'Valeur invalide. Valeurs autorisées: citizen, elected, agent',
          );
        }
      }

      if (errors.any((error) => error.line == lineNumber)) {
        continue;
      }

      existingUsernames.add(normalizedUsername);
      existingEmails.add(normalizedEmail);

      drafts.add(
        _DraftUser(
          firstName: firstName,
          lastName: lastName,
          username: username,
          email: email,
          role: _parseRole(roleRaw),
        ),
      );
    }

    return _CsvCompilationResult(drafts: drafts, errors: errors);
  }

  Future<void> _showCsvCompilationErrors(
    List<_CsvValidationError> errors,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.error),
              const SizedBox(width: 8),
              Text('Compilation CSV échouée (${errors.length})'),
            ],
          ),
          content: SizedBox(
            width: 720,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.highlight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Le fichier contient des erreurs. Corrigez-les puis relancez l\'import.',
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: errors.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final error = errors[index];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.error.withValues(
                            alpha: 0.2,
                          ),
                          child: Text(
                            '${error.line}',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                        title: Text(error.message),
                        subtitle: Text(
                          'Ligne ${error.line} • Colonne ${error.column}',
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  bool _isValidEmail(String value) {
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailPattern.hasMatch(value);
  }

  UserRole _parseRole(String raw) {
    final normalizedRole = raw.trim().toLowerCase();
    final roleValue = normalizedRole.isEmpty ? 'citizen' : normalizedRole;
    switch (roleValue) {
      case 'agent':
        return UserRole.agent;
      case 'elected':
        return UserRole.elected;
      case 'citizen':
      default:
        return UserRole.citizen;
    }
  }

  Future<void> _submitDrafts() async {
    if (_draftUsers.isEmpty) {
      CustomSnackBar.showError(context, 'Ajoutez au moins un utilisateur.');
      return;
    }

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Validation finale'),
        content: Text(
          'Créer définitivement ${_draftUsers.length} utilisateur(s) ? Cette action enverra la liste au serveur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Créer'),
          ),
        ],
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
        '${createdCredentials.length} utilisateur(s) créé(s) avec succès.',
      );
    }

    if (errors.isNotEmpty) {
      CustomSnackBar.showError(
        context,
        '${errors.length} échec(s). Consultez le détail.',
      );
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Erreurs de création'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(child: Text(errors.join('\n'))),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
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

  String _credentialLink(_CreatedCredential credential) {
    final route = Uri(
      path: AppRoutes.credentialsShare,
      queryParameters: {
        'username': credential.username,
        'password': credential.password,
        'name': '${credential.firstName} ${credential.lastName}',
      },
    ).toString();

    final origin = Uri.base.origin;
    return '$origin$route';
  }

  Future<void> _copyCredentialLink(_CreatedCredential credential) async {
    final link = _credentialLink(credential);
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) {
      return;
    }
    CustomSnackBar.showSuccess(context, 'Lien copié dans le presse-papiers.');
  }

  Future<void> _generateSchoolGridPdf() async {
    if (_createdCredentials.isEmpty) {
      CustomSnackBar.showError(context, 'Aucun utilisateur créé à exporter.');
      return;
    }

    final columns = int.tryParse(_gridColumnsController.text.trim()) ?? 3;
    final rows = int.tryParse(_gridRowsController.text.trim()) ?? 8;
    final safeColumns = columns.clamp(1, 8);
    final safeRows = rows.clamp(1, 20);
    final slotsPerPage = safeColumns * safeRows;

    final document = pw.Document();
    final primary = PdfColor.fromInt(AppColors.primary.toARGB32());

    for (
      var start = 0;
      start < _createdCredentials.length;
      start += slotsPerPage
    ) {
      final pageItems = _createdCredentials
          .skip(start)
          .take(slotsPerPage)
          .toList();

      final tableData = <List<String>>[];
      var cursor = 0;
      for (var rowIndex = 0; rowIndex < safeRows; rowIndex++) {
        final rowData = <String>[];
        for (var colIndex = 0; colIndex < safeColumns; colIndex++) {
          if (cursor < pageItems.length) {
            final item = pageItems[cursor];
            rowData.add('${item.username}\n${item.password}');
          } else {
            rowData.add('');
          }
          cursor++;
        }
        tableData.add(rowData);
      }

      document.addPage(
        pw.Page(
          margin: const pw.EdgeInsets.all(20),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Novaville - Identifiants utilisateurs',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: primary,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Expanded(
                  child: pw.Table.fromTextArray(
                    data: tableData,
                    cellAlignment: pw.Alignment.center,
                    headerCount: 0,
                    cellStyle: const pw.TextStyle(fontSize: 11),
                    border: pw.TableBorder.all(color: PdfColors.grey500),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(onLayout: (format) async => document.save());
  }

  Future<void> _generateOneUserPerPagePdf() async {
    if (_createdCredentials.isEmpty) {
      CustomSnackBar.showError(context, 'Aucun utilisateur créé à exporter.');
      return;
    }

    final document = pw.Document();
    final primary = PdfColor.fromInt(AppColors.primary.toARGB32());

    for (final credential in _createdCredentials) {
      document.addPage(
        pw.Page(
          margin: const pw.EdgeInsets.all(40),
          build: (context) {
            return pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: primary, width: 2),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              padding: const pw.EdgeInsets.all(24),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Novaville - Vos identifiants',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: primary,
                    ),
                  ),
                  pw.SizedBox(height: 24),
                  pw.Text(
                    '${credential.firstName} ${credential.lastName}',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  pw.Text('Nom d\'utilisateur: ${credential.username}'),
                  pw.SizedBox(height: 8),
                  pw.Text('Mot de passe: ${credential.password}'),
                ],
              ),
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(onLayout: (format) async => document.save());
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
                  tooltip: 'Retour',
                ),
                Text(
                  'Création multiple d\'utilisateurs',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Préparez vos utilisateurs en saisie manuelle ou via CSV, puis validez la création finale.',
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Liste en attente: ${_draftUsers.length} utilisateur(s)',
                    ),
                    TextButton.icon(
                      onPressed: _draftUsers.isEmpty ? null : _clearDrafts,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Réinitialiser'),
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
                      label: Text('Saisie manuelle'),
                      icon: Icon(Icons.edit),
                    ),
                    ButtonSegment<_CreationMode>(
                      value: _CreationMode.csv,
                      label: Text('Import CSV'),
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
                    ? 'Création en cours...'
                    : 'Valider et créer ${_draftUsers.length} utilisateur(s)',
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
            Row(
              children: [
                Text(
                  'Saisie manuelle',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _addManualCard,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter une carte'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _manualCards.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildManualUserCard(index, _manualCards[index]);
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _addManualCardsToList,
                icon: const Icon(Icons.playlist_add_check),
                label: const Text('Valider les cartes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualUserCard(int index, _ManualUserFormData card) {
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
                decoration: const InputDecoration(labelText: 'Rôle'),
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
                Row(
                  children: [
                    Text(
                      'Utilisateur ${index + 1}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _removeManualCard(index),
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Retirer',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (isCompact) ...[
                  TextField(
                    controller: card.firstNameController,
                    decoration: const InputDecoration(labelText: 'Prénom'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: card.lastNameController,
                    decoration: const InputDecoration(labelText: 'Nom'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: card.usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom d\'utilisateur',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: card.emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
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
                            labelText: 'Prénom',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: card.lastNameController,
                          decoration: const InputDecoration(labelText: 'Nom'),
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
                          decoration: const InputDecoration(
                            labelText: 'Nom d\'utilisateur',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: card.emailController,
                          decoration: const InputDecoration(labelText: 'Email'),
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
            'Glissez-déposez votre fichier CSV ici',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Text('ou', style: Theme.of(context).textTheme.bodySmall),
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
            label: const Text('Sélectionner un fichier'),
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
              'Importer un fichier CSV',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
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
                  'TÉLÉCHARGER UN FICHIER D\'EXEMPLE',
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
              'Utilisateurs en attente',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_draftUsers.isEmpty)
              const Text('Aucun utilisateur en attente.')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  return _buildPendingUserCard(index, _draftUsers[index]);
                },
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemCount: _draftUsers.length,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingUserCard(int index, _DraftUser draft) {
    final allowedRoles = <UserRole>[
      UserRole.citizen,
      UserRole.elected,
      UserRole.agent,
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Utilisateur ${index + 1}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Supprimer',
                  onPressed: () async {
                    setState(() {
                      _draftUsers.removeAt(index);
                    });
                    await _saveDrafts();
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: 260,
                  child: TextFormField(
                    initialValue: draft.firstName,
                    decoration: const InputDecoration(labelText: 'Prénom'),
                    onChanged: (value) {
                      _draftUsers[index] = _draftUsers[index].copyWith(
                        firstName: value,
                      );
                      _saveDrafts();
                    },
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: TextFormField(
                    initialValue: draft.lastName,
                    decoration: const InputDecoration(labelText: 'Nom'),
                    onChanged: (value) {
                      _draftUsers[index] = _draftUsers[index].copyWith(
                        lastName: value,
                      );
                      _saveDrafts();
                    },
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: TextFormField(
                    initialValue: draft.username,
                    decoration: const InputDecoration(labelText: 'Identifiant'),
                    onChanged: (value) {
                      _draftUsers[index] = _draftUsers[index].copyWith(
                        username: value,
                      );
                      _saveDrafts();
                    },
                  ),
                ),
                SizedBox(
                  width: 300,
                  child: TextFormField(
                    initialValue: draft.email,
                    decoration: const InputDecoration(labelText: 'Email'),
                    onChanged: (value) {
                      _draftUsers[index] = _draftUsers[index].copyWith(
                        email: value,
                      );
                      _saveDrafts();
                    },
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<UserRole>(
                    initialValue: draft.role,
                    decoration: const InputDecoration(labelText: 'Rôle'),
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
                      _draftUsers[index] = _draftUsers[index].copyWith(
                        role: value,
                      );
                      _saveDrafts();
                      setState(() {});
                    },
                  ),
                ),
              ],
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
              'Comptes créés et diffusion des identifiants',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _gridColumnsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Colonnes'),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _gridRowsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Lignes'),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _generateSchoolGridPdf,
                  icon: const Icon(Icons.grid_view),
                  label: const Text('PDF type école'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _generateOneUserPerPagePdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF 1 utilisateur/page'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final credential = _createdCredentials[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${credential.firstName} ${credential.lastName}'),
                  subtitle: Text(
                    '${credential.username} • mot de passe: ${credential.password}',
                  ),
                  trailing: TextButton.icon(
                    onPressed: () => _copyCredentialLink(credential),
                    icon: const Icon(Icons.link),
                    label: const Text('Copier lien'),
                  ),
                );
              },
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemCount: _createdCredentials.length,
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualUserFormData {
  _ManualUserFormData() : role = UserRole.citizen;

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  UserRole role;

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
    required this.username,
    required this.password,
  });

  final String firstName;
  final String lastName;
  final String username;
  final String password;
}

class _CsvCompilationResult {
  const _CsvCompilationResult({required this.drafts, required this.errors});

  final List<_DraftUser> drafts;
  final List<_CsvValidationError> errors;
}

class _CsvValidationError {
  const _CsvValidationError({
    required this.line,
    required this.column,
    required this.message,
  });

  final int line;
  final String column;
  final String message;
}
