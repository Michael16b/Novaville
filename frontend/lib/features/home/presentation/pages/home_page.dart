import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts.dart';
import 'package:frontend/features/home/presentation/widgets/menu_card.dart';

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
              style: TextStyle(
                fontSize: 24,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2,
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
          ],
        ),
      ),
    );
  }
}
