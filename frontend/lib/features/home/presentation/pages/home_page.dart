import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts.dart';
import 'package:frontend/features/account/presentation/pages/my_account_page.dart';
import 'package:frontend/features/agenda/presentation/pages/agenda_page.dart';
import 'package:frontend/features/home/presentation/widgets/menu_card.dart';
import 'package:frontend/features/news/presentation/pages/news_page.dart';
import 'package:frontend/features/reports/presentation/pages/reports_page.dart';
import 'package:frontend/features/surveys/presentation/pages/surveys_page.dart';
import 'package:frontend/features/useful_info/presentation/pages/useful_info_page.dart';

/// Home screen of the app that displays a grid of navigation cards
/// linking to core features such as reports, surveys, agenda, news,
/// account, and useful information pages.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              AppTexts.homeTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              AppTexts.homeSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, color: AppColors.secondaryText),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const itemWidth = 550.0;
                  const spacing = 16.0;
                  final availableColumns =
                      (constraints.maxWidth / (itemWidth + spacing)).floor();
                  final crossAxisCount = availableColumns
                      .clamp(1, 3)
                      .toInt(); // max 3 colonnes
                  final gridWidth =
                      crossAxisCount * itemWidth +
                      (crossAxisCount - 1) * spacing;

                  return Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: gridWidth,
                      child: GridView.count(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        childAspectRatio: 1.4,
                        children: [
                          MenuCard(
                            icon: Icons.report_problem_outlined,
                            title: AppTexts.reports,
                            onTap: () {
                              // TODO: Navigation vers Signalements
                            },
                          ),
                          MenuCard(
                            icon: Icons.poll_outlined,
                            title: AppTexts.surveys,
                            onTap: () {
                              // TODO: Navigation vers Sondages
                            },
                          ),
                          MenuCard(
                            icon: Icons.calendar_today_outlined,
                            title: AppTexts.agenda,
                            onTap: () {
                              // TODO: Navigation vers Agenda
                            },
                          ),
                          MenuCard(
                            icon: Icons.article_outlined,
                            title: AppTexts.news,
                            onTap: () {
                              // TODO: Navigation vers Actualités
                            },
                          ),
                          MenuCard(
                            icon: Icons.account_circle_outlined,
                            title: AppTexts.myAccount,
                            onTap: () {
                              // TODO: Navigation vers Mon compte
                            },
                          ),
                          MenuCard(
                            icon: Icons.info_outlined,
                            title: AppTexts.usefulInfo,
                            onTap: () {
                              // TODO: Navigation vers Infos utiles
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
