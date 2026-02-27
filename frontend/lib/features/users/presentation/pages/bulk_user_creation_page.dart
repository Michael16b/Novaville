import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  final _manualFormKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _gridColumnsController = TextEditingController(text: '3');
  final _gridRowsController = TextEditingController(text: '8');

  late final IUserRepository _repository;

  _CreationMode _creationMode = _CreationMode.manual;
  UserRole _selectedRole = UserRole.citizen;
  bool _isSubmitting = false;
  bool _isImportingCsv = false;

  List<_DraftUser> _draftUsers = <_DraftUser>[];
  List<_CreatedCredential> _createdCredentials = <_CreatedCredential>[];

  @override
  void initState() {
    super.initState();
    _repository = widget.userRepository ?? createUserRepository();
    _loadDrafts();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
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
          'Brouillon restauré (${loaded.length} utilisateurs).',
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
        title: const Text('Supprimer le brouillon'),
        content: const Text(
          'Voulez-vous supprimer tous les utilisateurs en brouillon ?',
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

  void _addManualDraft() {
    if (!_manualFormKey.currentState!.validate()) {
      return;
    }

    final draft = _DraftUser(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      role: _selectedRole,
    );

    final alreadyExists = _draftUsers.any(
      (entry) =>
          entry.username.toLowerCase() == draft.username.toLowerCase() ||
          entry.email.toLowerCase() == draft.email.toLowerCase(),
    );

    if (alreadyExists) {
      CustomSnackBar.showError(
        context,
        'Un brouillon avec ce nom d\'utilisateur ou cet email existe déjà.',
      );
      return;
    }

    setState(() {
      _draftUsers = <_DraftUser>[..._draftUsers, draft];
      _firstNameController.clear();
      _lastNameController.clear();
      _usernameController.clear();
      _emailController.clear();
    });
    _saveDrafts();
  }

  Future<void> _importCsv() async {
    setState(() {
      _isImportingCsv = true;
    });

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
      String csvContent;
      if (file.bytes != null) {
        csvContent = utf8.decode(file.bytes!, allowMalformed: true);
      } else if (file.path != null) {
        csvContent = await File(file.path!).readAsString();
      } else {
        throw Exception('Fichier CSV illisible');
      }

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
        'Compilation réussie : ${compilation.drafts.length} utilisateur(s) importé(s).',
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
        addError('username', 'Doublon détecté (brouillon/fichier)');
      }
      if (email.isNotEmpty && existingEmails.contains(normalizedEmail)) {
        addError('email', 'Doublon détecté (brouillon/fichier)');
      }

      if (roleRaw.isNotEmpty) {
        if (roleRaw != roleRaw.toLowerCase()) {
          addError(
            'role',
            'Le rôle doit être en minuscule (ex: citizen, elected, agent, global_admin)',
          );
        }

        const allowedRoles = {'citizen', 'elected', 'agent', 'global_admin'};
        if (!allowedRoles.contains(roleRaw.toLowerCase())) {
          addError(
            'role',
            'Valeur invalide. Valeurs autorisées: citizen, elected, agent, global_admin',
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
      case 'global_admin':
        return UserRole.globalAdmin;
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
              'Préparez vos comptes en brouillon (sauvegarde locale automatique), puis validez la création finale.',
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Brouillon local: ${_draftUsers.length} utilisateur(s)',
                    ),
                    TextButton.icon(
                      onPressed: _draftUsers.isEmpty ? null : _clearDrafts,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Vider'),
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
        child: Form(
          key: _manualFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ajouter un utilisateur au brouillon',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 260,
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(labelText: 'Prénom'),
                      validator: _requiredValidator,
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Nom'),
                      validator: _requiredValidator,
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom d\'utilisateur',
                      ),
                      validator: _requiredValidator,
                    ),
                  ),
                  SizedBox(
                    width: 320,
                    child: TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) {
                          return 'Champ obligatoire';
                        }
                        if (!text.contains('@')) {
                          return 'Email invalide';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: DropdownButtonFormField<UserRole>(
                      initialValue: _selectedRole,
                      decoration: const InputDecoration(labelText: 'Rôle'),
                      items: UserRole.values
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
                          _selectedRole = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _addManualDraft,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter au brouillon'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCsvSection() {
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
            const Text(
              'Colonnes obligatoires: first_name,last_name,username,email\n'
              'Colonne optionnelle: role (citizen|elected|agent|global_admin) en minuscule.\n'
              'Aucune colonne mot de passe: il est généré automatiquement (8 caractères lettres/chiffres).',
            ),
            const SizedBox(height: 8),
            SelectableText(
              'Exemple:\nfirst_name,last_name,username,email,role\nJean,Dupont,jdupont,jdupont@novaville.fr,citizen',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isImportingCsv ? null : _importCsv,
              icon: _isImportingCsv
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: const Text('Importer le CSV'),
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
              'Utilisateurs en brouillon',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (_draftUsers.isEmpty)
              const Text('Aucun utilisateur en brouillon.')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final draft = _draftUsers[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.highlight,
                      child: Icon(Icons.person, color: AppColors.primary),
                    ),
                    title: Text('${draft.firstName} ${draft.lastName}'),
                    subtitle: Text(
                      '${draft.username} • ${draft.email} • ${draft.role.label}',
                    ),
                    trailing: IconButton(
                      onPressed: () async {
                        setState(() {
                          _draftUsers.removeAt(index);
                        });
                        await _saveDrafts();
                      },
                      icon: const Icon(Icons.delete_outline),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemCount: _draftUsers.length,
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

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Champ obligatoire';
    }
    return null;
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
