import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts.dart';
import 'package:frontend/core/validation_patterns.dart';
import 'package:frontend/design_systems/custom_elevated_flat_button.dart';
import 'package:frontend/design_systems/custom_outlined_button.dart';
import 'package:frontend/design_systems/custom_snack_bar.dart';
import 'package:frontend/design_systems/custom_text_form_field.dart';
import 'package:frontend/features/account/application/bloc/user_profile_bloc.dart';
import 'package:frontend/features/account/data/user_repository_factory.dart';
import 'package:frontend/ui/layouts/secured_layout.dart';

/// Page du compte utilisateur avec formulaire de modification
class MyAccountPage extends StatelessWidget {
  /// Crée la page du compte
  const MyAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SecuredLayout(
      isHomePage: false,
      child: BlocProvider(
        create: (context) => UserProfileBloc(
          repository: createUserRepository(),
        )..add(const UserProfileLoadRequested()),
        child: const _MyAccountView(),
      ),
    );
  }
}

class _MyAccountView extends StatefulWidget {
  const _MyAccountView();

  @override
  State<_MyAccountView> createState() => _MyAccountViewState();
}

class _MyAccountViewState extends State<_MyAccountView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserProfileBloc, UserProfileState>(
      listener: (context, state) {
        if (state.status == UserProfileStatus.loaded && state.user != null) {
          // Remplir les champs du formulaire uniquement au chargement initial
          if (!_initialized) {
            _firstNameController.text = state.user!.firstName;
            _lastNameController.text = state.user!.lastName;
            _usernameController.text = state.user!.username;
            _emailController.text = state.user!.email;
            _initialized = true;
          }

          // Afficher le message de succès uniquement après une mise à jour
          if (state.isUpdate) {
            CustomSnackBar.showSuccess(
              context,
              AppTexts.profileUpdateSuccess,
            );
          }
        } else if (state.status == UserProfileStatus.failure && state.isUpdate) {
          CustomSnackBar.showError(
            context,
            state.error ?? AppTexts.profileUpdateError,
          );
        }
      },
        builder: (context, state) {
          if (state.status == UserProfileStatus.loading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(AppTexts.loadingProfile),
                ],
              ),
            );
          }

          if (state.status == UserProfileStatus.failure && !state.isUpdate) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    state.error ?? AppTexts.errorOccurred,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  CustomElevatedFlatButton(
                    onPressed: () {
                      context.read<UserProfileBloc>().add(
                            const UserProfileLoadRequested(),
                          );
                    },
                    text: AppTexts.retry,
                  ),
                ],
              ),
            );
          }

          if (state.user == null) {
            return const Center(child: Text(AppTexts.noUser));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: _formKey,
                  child: Column(
                    spacing: 24,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.account_circle,
                        size: 80,
                        color: AppColors.primary,
                      ),
                      const Text(
                        AppTexts.myProfile,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // Section Informations personnelles
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          spacing: 16,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.person_outline,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppTexts.personalInformation,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            CustomTextFormField(
                              controller: _firstNameController,
                              labelText: AppTexts.firstName,
                              isRequired: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return AppTexts.firstNameRequired;
                                }
                                return null;
                              },
                            ),
                            CustomTextFormField(
                              controller: _lastNameController,
                              labelText: AppTexts.lastName,
                              isRequired: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return AppTexts.lastNameRequired;
                                }
                                return null;
                              },
                            ),
                            CustomTextFormField(
                              controller: _emailController,
                              labelText: AppTexts.email,
                              keyboardType: TextInputType.emailAddress,
                              isRequired: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return AppTexts.emailRequired;
                                }
                                if (!ValidationPatterns.email.hasMatch(value)) {
                                  return AppTexts.emailInvalid;
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      // Section Informations de connexion
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          spacing: 16,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.lock_outline,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppTexts.connectionInformation,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            CustomTextFormField(
                              controller: _usernameController,
                              labelText: AppTexts.username,
                              isRequired: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return AppTexts.usernameRequired;
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      Row(
                        spacing: 16,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CustomOutlinedButton(
                            onPressed: state.status == UserProfileStatus.updating
                                ? null
                                : () {
                                    // Réinitialiser les champs avec les valeurs d'origine
                                    _firstNameController.text =
                                        state.user!.firstName;
                                    _lastNameController.text = state.user!.lastName;
                                    _usernameController.text = state.user!.username;
                                    _emailController.text = state.user!.email;
                                  },
                            text: AppTexts.cancel,
                          ),
                          CustomElevatedFlatButton(
                            isLoading:
                                state.status == UserProfileStatus.updating,
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                context.read<UserProfileBloc>().add(
                                  UserProfileUpdateRequested(
                                    userId: state.user!.id,
                                    firstName: _firstNameController.text,
                                    lastName: _lastNameController.text,
                                    username: _usernameController.text,
                                    email: _emailController.text,
                                  ),
                                );
                              }
                            },
                            text: AppTexts.save,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
  }
}
