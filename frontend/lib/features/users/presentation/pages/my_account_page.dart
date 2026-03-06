import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_general.dart';
import 'package:frontend/constants/texts/texts_my_account.dart';
import 'package:frontend/core/validation_patterns.dart';
import 'package:frontend/design_systems/custom_elevated_flat_button.dart';
import 'package:frontend/design_systems/custom_snack_bar.dart';
import 'package:frontend/features/users/application/bloc/user_profil_bloc/user_profile_bloc.dart';
import 'package:frontend/features/users/data/user_repository_factory.dart';

/// User account page with a profile edit form.
class MyAccountPage extends StatelessWidget {
  /// Creates the account page.
  const MyAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserProfileBloc(
        repository: createUserRepository(),
      )..add(const UserProfileLoadRequested()),
      child: const _MyAccountView(),
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
          // Populate form fields only on the initial load
          if (!_initialized) {
            _firstNameController.text = state.user!.firstName;
            _lastNameController.text = state.user!.lastName;
            _usernameController.text = state.user!.username;
            _emailController.text = state.user!.email;
            _initialized = true;
          }

          // Show success message only after an update
          if (state.isUpdate) {
            CustomSnackBar.showSuccess(
              context,
              AppTextsProfile.profileUpdateSuccess,
            );
          }
        } else if (state.status == UserProfileStatus.failure && state.isUpdate) {
          CustomSnackBar.showError(
            context,
            state.error ?? AppTextsProfile.profileUpdateError,
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
                  Text(AppTextsProfile.loadingProfile),
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
                    state.error ?? AppTextsGeneral.errorOccurred,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  CustomElevatedFlatButton(
                    onPressed: () {
                      context.read<UserProfileBloc>().add(
                            const UserProfileLoadRequested(),
                          );
                    },
                    text: AppTextsGeneral.retry,
                  ),
                ],
              ),
            );
          }

          if (state.user == null) {
            return const Center(child: Text(AppTextsProfile.noUser));
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
                        AppTextsProfile.myProfile,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // Personal information section
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
                            const Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  AppTextsProfile.personalInformation,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            TextFormField(
                              controller: _firstNameController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return AppTextsProfile.firstNameRequired;
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: '${AppTextsProfile.firstName} *',
                              ),
                            ),
                            TextFormField(
                              controller: _lastNameController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return AppTextsProfile.lastNameRequired;
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: '${AppTextsProfile.lastName} *',
                              ),
                            ),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return AppTextsProfile.emailRequired;
                                }
                                if (!ValidationPatterns.email.hasMatch(value)) {
                                  return AppTextsProfile.emailInvalid;
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: '${AppTextsProfile.email} *',
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Login information section
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
                            const Row(
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  AppTextsProfile.connectionInformation,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            TextFormField(
                              controller: _usernameController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return AppTextsProfile.usernameRequired;
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                labelText: '${AppTextsProfile.username} *',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        spacing: 16,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton.icon(
                            onPressed: state.status == UserProfileStatus.updating
                                ? null
                                : () {
                                    // Reset fields to their original values
                                    _firstNameController.text =
                                        state.user!.firstName;
                                    _lastNameController.text = state.user!.lastName;
                                    _usernameController.text = state.user!.username;
                                    _emailController.text = state.user!.email;
                                  },
                            icon: const Icon(Icons.refresh_outlined),
                            label: const Text(AppTextsGeneral.reset),
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
                            text: AppTextsGeneral.save,
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
