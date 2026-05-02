import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_agenda.dart';
import 'package:frontend/constants/texts/texts_home.dart';
import 'package:frontend/constants/texts/texts_reports.dart';
import 'package:frontend/design_systems/custom_snack_bar.dart';
import 'package:frontend/features/agenda/data/event_repository_factory.dart';
import 'package:frontend/features/agenda/data/models/event_theme.dart';
import 'package:frontend/features/agenda/presentation/widgets/event_form_dialog.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/features/reports/data/report_repository_factory.dart';
import 'package:frontend/features/reports/presentation/widgets/report_form_dialog.dart';

class HomeActionButtons extends StatefulWidget {
  const HomeActionButtons({super.key});

  @override
  State<HomeActionButtons> createState() => _HomeActionButtonsState();
}

class _HomeActionButtonsState extends State<HomeActionButtons> {
  bool _isCreatingReport = false;
  bool _isCreatingEvent = false;

  Future<void> _showCreateReportDialog(BuildContext context) async {
    setState(() {
      _isCreatingReport = true;
    });

    try {
      final reportRepository = createReportRepository();
      if (!mounted) return;

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) => const ReportFormDialog(),
      );

      if (result != null && mounted) {
        await reportRepository.createReport(
          title: result['title'] as String,
          problemType: result['problem_type'] as String,
          description: result['description'] as String,
          address: result['address'] as String,
        );
        if (mounted) {
          CustomSnackBar.showSuccess(context, ReportTexts.createSuccess);
        }
      }
      if (mounted) {
        setState(() {
          _isCreatingReport = false;
        });
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, ReportTexts.error);
        setState(() {
          _isCreatingReport = false;
        });
      }
    }
  }

  Future<void> _showCreateEventDialog(BuildContext context) async {
    setState(() {
      _isCreatingEvent = true;
    });

    try {
      final eventRepository = createEventRepository();
      final themes = await eventRepository.listThemes();
      if (!mounted) return;

      setState(() {
        _isCreatingEvent = false;
      });

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) => const EventFormDialog(),
      );

      if (result != null && mounted) {
        final selectedTheme = result['theme'] as EventTheme?;
        int? themeId;
        if (selectedTheme != null) {
          try {
            themeId = themes
                .firstWhere((t) => t.title == selectedTheme.label)
                .id;
          } catch (e) {
            themeId = null;
          }
        }

        await eventRepository.createEvent(
          title: result['title'] as String,
          description: result['description'] as String,
          startDate: result['start_date'] as DateTime,
          endDate: result['end_date'] as DateTime,
          theme: themeId,
        );
        if (mounted) {
          CustomSnackBar.showSuccess(context, AgendaTexts.createSuccess);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, AgendaTexts.error);
        setState(() {
          _isCreatingEvent = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final isStaff = authState.user?.isStaff ?? false;
    final width = MediaQuery.sizeOf(context).width;
    final useVerticalLayout = width < 768;

    final primaryButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    final secondaryButtonStyle =
        ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          elevation: 1,
          shadowColor: Colors.black12,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith<Color?>((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.pressed)) {
              return AppColors.primary.withOpacity(0.12);
            }
            return null;
          }),
        );

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(
          width: useVerticalLayout ? double.infinity : null,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              AppTextsHome.newPoll,
              style: TextStyle(color: Colors.white),
            ),
            style: primaryButtonStyle,
          ),
        ),
        SizedBox(
          width: useVerticalLayout ? double.infinity : null,
          child: ElevatedButton.icon(
            onPressed: _isCreatingReport
                ? null
                : () => _showCreateReportDialog(context),
            icon: _isCreatingReport
                ? Container(
                    width: 24,
                    height: 24,
                    padding: const EdgeInsets.all(2),
                    child: const CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 3,
                    ),
                  )
                : const Icon(Icons.add, color: AppColors.primary),
            label: const Text(
              AppTextsHome.newReport,
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: secondaryButtonStyle,
          ),
        ),
        if (isStaff)
          SizedBox(
            width: useVerticalLayout ? double.infinity : null,
            child: ElevatedButton.icon(
              onPressed: _isCreatingEvent
                  ? null
                  : () => _showCreateEventDialog(context),
              icon: _isCreatingEvent
                  ? Container(
                      width: 24,
                      height: 24,
                      padding: const EdgeInsets.all(2),
                      child: const CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 3,
                      ),
                    )
                  : const Icon(Icons.add, color: AppColors.primary),
              label: const Text(
                AppTextsHome.addEvent,
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: secondaryButtonStyle,
            ),
          ),
      ],
    );
  }
}
