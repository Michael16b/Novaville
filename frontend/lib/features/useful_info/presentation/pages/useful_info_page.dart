import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_useful_info.dart';

import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/features/useful_info/application/bloc/useful_info_bloc.dart';
import 'package:frontend/features/useful_info/application/bloc/useful_info_event.dart';
import 'package:frontend/features/useful_info/application/bloc/useful_info_state.dart';
import 'package:frontend/features/useful_info/domain/useful_info.dart';

import '../widgets/opening_hours_table.dart';
import '../widgets/contact_actions.dart';
import 'useful_info_admin_edit_page.dart';

/// Page that shows the municipality's useful information.
///
/// The screen reacts to the [UsefulInfoBloc] state and displays a loading
/// spinner, error message or the information itself. Administrators see an
/// edit button that navigates to the admin form.
class UsefulInfoPage extends StatelessWidget {
  const UsefulInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select<AuthBloc, bool>((bloc) {
      final state = bloc.state;
      if (state.status != AuthStatus.authenticated) return false;
      // Only global administrators are allowed to edit useful info on the
      // server-side (same as `IsAdminUser` permission in the backend).
      return state.user?.isGlobalAdmin == true;
    });

    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: null,
      body: BlocBuilder<UsefulInfoBloc, UsefulInfoState>(
        builder: (context, state) {
          if (state is UsefulInfoInitial) {
            context.read<UsefulInfoBloc>().add(const UsefulInfoRequested());
            return const SizedBox.shrink();
          }

          if (state is UsefulInfoLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is UsefulInfoFailure) {
            return Center(child: Text(state.message));
          }

          final info = (state as UsefulInfoLoaded).info;

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                children: [
                  // Header style "Signalements"
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 35,
                        color: AppColors.primary.withValues(alpha: 1),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        UsefulInfoTexts.title,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 35),
                    child: Text(
                      UsefulInfoTexts.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _SectionCard(
                    title: UsefulInfoTexts.cityHallSection,
                    icon: Icons.location_city_outlined,
                    child: _CityHallBlock(info: info),
                  ),
                  const SizedBox(height: 16),

                  _SectionCard(
                    title: UsefulInfoTexts.openingHoursSection,
                    icon: Icons.schedule_outlined,
                    child: OpeningHoursTable(openingHours: info.openingHours),
                  ),
                  const SizedBox(height: 16),

                  _SectionCard(
                    title: UsefulInfoTexts.contactSection,
                    icon: Icons.phone_outlined,
                    child: ContactActions(
                      phone: info.phone,
                      email: info.email,
                      website: info.website,
                    ),
                  ),
                ],
              ),

              if (isAdmin)
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: () async {
                      // avoid using `context` after `await`
                      final bloc = context.read<UsefulInfoBloc>();
                      final updated = await Navigator.push<UsefulInfo>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              UsefulInfoAdminEditPage(initial: info),
                        ),
                      );

                      if (updated != null && context.mounted) {
                        bloc.add(UsefulInfoSaved(updated));
                      }
                    },
                    child: const Icon(Icons.edit),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor.withOpacity(0.85),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _CityHallBlock extends StatelessWidget {
  final UsefulInfo info;
  const _CityHallBlock({required this.info});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(info.cityHallName, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 6),
        Text(info.addressLine1, style: textStyle),
        if ((info.addressLine2 ?? "").isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(info.addressLine2!, style: textStyle),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text("${info.postalCode} ${info.city}", style: textStyle),
        ),
      ],
    );
  }
}
