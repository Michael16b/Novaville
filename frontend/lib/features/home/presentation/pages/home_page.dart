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
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const ReportsPage(),
                        ),
                      );
                    },
                  ),
                  MenuCard(
                    icon: Icons.how_to_vote,
                    title: AppTexts.surveys,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const SurveysPage(),
                        ),
                      );
                    },
                  ),
                  MenuCard(
                    icon: Icons.calendar_month,
                    title: AppTexts.agenda,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const AgendaPage(),
                        ),
                      );
                    },
                  ),
                  MenuCard(
                    icon: Icons.newspaper,
                    title: AppTexts.news,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const NewsPage(),
                        ),
                      );
                    },
                  ),
                  MenuCard(
                    icon: Icons.account_circle_outlined,
                    title: AppTexts.myAccount,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const MyAccountPage(),
                        ),
                      );
                    },
                  ),
                  MenuCard(
                    icon: Icons.info_outlined,
                    title: AppTexts.usefulInfo,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const UsefulInfoPage(),
                        ),
                      );
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
