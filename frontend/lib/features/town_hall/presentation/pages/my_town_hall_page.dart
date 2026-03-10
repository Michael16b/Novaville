import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_general.dart';
import 'package:frontend/constants/texts/texts_home.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/features/users/data/models/user_role.dart';

class MyTownHallPage extends StatefulWidget {
  const MyTownHallPage({super.key});

  @override
  State<MyTownHallPage> createState() => _MyTownHallPageState();
}

class _MyTownHallPageState extends State<MyTownHallPage> {
  late TextEditingController _appNameController;
  late TextEditingController _homeTitleController;
  late TextEditingController _homeSubtitleController;
  late Color _primaryColor;
  late Color _secondaryColor;

  @override
  void initState() {
    super.initState();
    _appNameController = TextEditingController(text: AppTextsGeneral.appName);
    _homeTitleController = TextEditingController(text: AppTextsHome.homeTitle);
    _homeSubtitleController =
        TextEditingController(text: AppTextsHome.homeSubtitle);
    _primaryColor = AppColors.primary;
    _secondaryColor = AppColors.secondary;
  }

  @override
  void dispose() {
    _appNameController.dispose();
    _homeTitleController.dispose();
    _homeSubtitleController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    setState(() {
      AppTextsGeneral.appName = _appNameController.text;
      AppTextsHome.homeTitle = _homeTitleController.text;
      AppTextsHome.homeSubtitle = _homeSubtitleController.text;
      AppColors.primary = _primaryColor;
      AppColors.secondary = _secondaryColor;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Modifications enregistrées')),
    );
  }

  void _showColorPicker(bool isPrimary) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
              'Choisir une couleur ${isPrimary ? 'principale' : 'secondaire'}'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: isPrimary ? _primaryColor : _secondaryColor,
              onColorChanged: (color) {
                setState(() {
                  if (isPrimary) {
                    _primaryColor = color;
                  } else {
                    _secondaryColor = color;
                  }
                });
              },
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _resetColors() {
    setState(() {
      _primaryColor = AppColors.primary;
      _secondaryColor = AppColors.secondary;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Couleurs réinitialisées')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final user = state.user;
        if (user == null ||
            (user.role != UserRole.globalAdmin &&
                user.role != UserRole.elected)) {
          return const Scaffold(
            body: Center(
              child: Text('Accès non autorisé'),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.page,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _saveChanges,
            label: const Text('Enregistrer'),
            icon: const Icon(Icons.save),
            backgroundColor: AppColors.primary,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ma Mairie',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: 'Textes de l\'application',
                  children: [
                    TextFormField(
                      controller: _appNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom de l\'application',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _homeTitleController,
                      decoration: const InputDecoration(
                        labelText: 'Titre de la page d\'accueil',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _homeSubtitleController,
                      decoration: const InputDecoration(
                        labelText: 'Sous-titre de la page d\'accueil',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: 'Personnalisation de l\'application',
                  children: [
                    _buildColorPicker(
                      label: 'Couleur principale (Primary)',
                      color: _primaryColor,
                      onPressed: () => _showColorPicker(true),
                    ),
                    const SizedBox(height: 16),
                    _buildColorPicker(
                      label: 'Couleur secondaire (Secondary)',
                      color: _secondaryColor,
                      onPressed: () => _showColorPicker(false),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _resetColors,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réinitialiser les couleurs'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Logo de l\'application',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildLogoDropZone(),
                  ],
                ),
                const SizedBox(height: 80), // Space for FAB
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildColorPicker({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Row(
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.primaryText,
            ),
          ),
        ),
        TextButton(
          onPressed: onPressed,
          child: const Text('Modifier'),
        ),
      ],
    );
  }

  Widget _buildLogoDropZone() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.5),
          style: BorderStyle.solid,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.primary.withValues(alpha: 0.05),
      ),
      child: DragTarget<String>(
        builder: (context, candidateData, rejectedData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 48,
                  color: AppColors.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 12),
                Text(
                  'Glissez et déposez votre logo ici',
                  style: TextStyle(
                    color: AppColors.primary.withValues(alpha: 0.8),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ou cliquez pour sélectionner',
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        },
        onAcceptWithDetails: (details) {
          // TODO: Handle dropped file
        },
      ),
    );
  }
}
