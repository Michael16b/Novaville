import 'package:flutter/material.dart';
import 'package:frontend/config/app_routes.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_home.dart';
import 'package:frontend/features/home/presentation/widgets/menu_card.dart';
import 'package:go_router/go_router.dart';

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
        final crossAxisCount = availableColumns.clamp(1, 3).toInt(); // max 3 columns
        final gridWidth =
            crossAxisCount * itemWidth + (crossAxisCount - 1) * spacing;

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: gridWidth,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
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
                        onTap: () => context.go(AppRoutes.reports),
                      ),
                      MenuCard(
                        icon: Icons.poll_outlined,
                        title: AppTextsHome.surveys,
                        onTap: () => context.go(AppRoutes.surveys),
                      ),
                      MenuCard(
                        icon: Icons.calendar_month_outlined,
                        title: AppTextsHome.agenda,
                        onTap: () => context.go(AppRoutes.agenda),
                      ),
                      MenuCard(
                        icon: Icons.article_outlined,
                        title: AppTextsHome.news,
                        onTap: () => context.go(AppRoutes.news),
                      ),
                      MenuCard(
                        icon: Icons.info_outlined,
                        title: AppTextsHome.usefulInfo,
                        onTap: () => context.go(AppRoutes.usefulInfo),
                      ),
                      MenuCard(
                        icon: Icons.person,
                        title: AppTextsHome.myAccount,
                        onTap: () => context.go(AppRoutes.myAccount),
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
