import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_general.dart';
import 'package:frontend/constants/texts/texts_useful_info.dart';

import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/features/useful_info/application/bloc/useful_info_bloc.dart';
import 'package:frontend/features/useful_info/application/bloc/useful_info_event.dart';
import 'package:frontend/features/useful_info/application/bloc/useful_info_state.dart';
import 'package:frontend/features/useful_info/domain/useful_info.dart';

import 'package:frontend/ui/widgets/page_header.dart';

import '../widgets/opening_hours_table.dart';
import '../widgets/contact_actions.dart';
import 'useful_info_admin_edit_page.dart';

class UsefulInfoPage extends StatelessWidget {
  const UsefulInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.select<AuthBloc, bool>((bloc) {
      final state = bloc.state;
      if (state.status != AuthStatus.authenticated) return false;
      return state.user?.isGlobalAdmin == true;
    });

    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              heroTag: 'useful-info-fab',
              tooltip: AppTextsGeneral.edit,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              onPressed: () async {
                final bloc = context.read<UsefulInfoBloc>();
                final currentState = bloc.state;

                if (currentState is! UsefulInfoLoaded) return;

                final updated = await Navigator.push<UsefulInfo>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        UsefulInfoAdminEditPage(initial: currentState.info),
                  ),
                );

                if (updated != null && context.mounted) {
                  bloc.add(UsefulInfoSaved(updated));
                }
              },
              child: const Icon(Icons.edit_outlined),
            )
          : null,
      body: BlocBuilder<UsefulInfoBloc, UsefulInfoState>(
        builder: (context, state) {
          if (state is UsefulInfoInitial) {
            context.read<UsefulInfoBloc>().add(const UsefulInfoRequested());
            return const SizedBox.shrink();
          }

          if (state is UsefulInfoLoading) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is UsefulInfoFailure) {
            return Center(child: Text(state.message));
          }

          final info = (state as UsefulInfoLoaded).info;
          if (_isInfoEmpty(info)) {
            return const _EmptyState();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PageHeader(
                  title: UsefulInfoTexts.title,
                  description: UsefulInfoTexts.description,
                  icon: Icons.info_outline,
                ),
                const SizedBox(height: 16),

                Column(
                  children: [
                    _SectionCard(
                      title: UsefulInfoTexts.cityHallSection,
                      icon: Icons.location_city_outlined,
                      child: _CityHallBlock(info: info),
                    ),

                    const SizedBox(height: 12),

                    _SectionCard(
                      title: UsefulInfoTexts.openingHoursSection,
                      icon: Icons.schedule_outlined,
                      child: OpeningHoursTable(openingHours: info.openingHours),
                    ),

                    const SizedBox(height: 12),

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
              ],
            ),
          );
        },
      ),
    );
  }
}

bool _isInfoEmpty(UsefulInfo info) {
  final hasContactData =
      (info.phone ?? '').trim().isNotEmpty ||
      (info.email ?? '').trim().isNotEmpty ||
      (info.website ?? '').trim().isNotEmpty;
  final hasAddressData =
      info.cityHallName.trim().isNotEmpty ||
      info.addressLine1.trim().isNotEmpty ||
      (info.addressLine2 ?? '').trim().isNotEmpty ||
      info.postalCode.trim().isNotEmpty ||
      info.city.trim().isNotEmpty;
  final hasOpeningHours = info.openingHours.entries.any(
    (entry) => entry.value.any((slot) => slot.trim().isNotEmpty),
  );
  final hasAdditionalInfo = (info.additionalInfo ?? '').trim().isNotEmpty;

  return !hasContactData &&
      !hasAddressData &&
      !hasOpeningHours &&
      !hasAdditionalInfo;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            UsefulInfoTexts.noUsefulInfo,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            UsefulInfoTexts.noUsefulInfoFound,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
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
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Text(
                  title,
                  style:
                      textTheme.titleSmall ??
                      const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DefaultTextStyle.merge(
              style: textTheme.bodyMedium ?? const TextStyle(fontSize: 14),
              child: child,
            ),
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
        Text(info.cityHallName, style: Theme.of(context).textTheme.titleSmall),
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
