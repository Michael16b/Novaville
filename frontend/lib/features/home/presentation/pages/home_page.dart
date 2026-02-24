import 'package:flutter/material.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_home.dart';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        const itemWidth = 450.0;
        const spacing = 16.0;
        final availableColumns =
            (constraints.maxWidth / (itemWidth + spacing)).floor();
        final crossAxisCount = availableColumns
            .clamp(1, 3)
            .toInt(); // max 3 columns
        final gridWidth =
            crossAxisCount * itemWidth +
            (crossAxisCount - 1) * spacing;

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: gridWidth,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: const [
                      SizedBox(height: 24),
                      Text(
                        AppTextsHome.homeTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        AppTextsHome.homeSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 24, color: AppColors.secondaryText),
                      ),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      childAspectRatio: 1.4,
                    ),
                    delegate: SliverChildListDelegate([
                      MenuCard(
                        icon: Icons.report_problem_outlined,
                        title: AppTextsHome.reports,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => const ReportsPage(),
                            ),
                          );
                        },
                      ),
                      MenuCard(
                        icon: Icons.poll_outlined,
                        title: AppTextsHome.surveys,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => const SurveysPage(),
                            ),
                          );
                        },
                      ),
                      MenuCard(
                        icon: Icons.calendar_today_outlined,
                        title: AppTextsHome.agenda,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => const AgendaPage(),
                            ),
                          );
                        },
                      ),
                      MenuCard(
                        icon: Icons.article_outlined,
                        title: AppTextsHome.news,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => const NewsPage(),
                            ),
                          );
                        },
                      ),
                      MenuCard(
                        icon: Icons.info_outlined,
                        title: AppTextsHome.usefulInfo,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => const UsefulInfoPage(),
                            ),
                          );
                        },
                      ),
                      MenuCard(
                        icon: Icons.account_circle_outlined,
                        title: AppTextsHome.myAccount,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (context) => const MyAccountPage(),
                            ),
                          );
                        },
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
