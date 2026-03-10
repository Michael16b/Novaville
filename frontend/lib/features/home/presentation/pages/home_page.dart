import 'package:flutter/material.dart';
import 'package:frontend/constants/texts/texts_home.dart';
import 'package:frontend/features/home/data/dashboard_repository.dart';
import 'package:frontend/features/home/data/dashboard_repository_factory.dart';
import 'package:frontend/features/home/domain/dashboard_stats.dart';
import 'package:frontend/features/home/presentation/widgets/dashboard_stats_widgets.dart';
import 'package:frontend/features/home/presentation/widgets/home_action_buttons.dart';
import 'package:frontend/features/home/presentation/widgets/home_sidebar_panels.dart';
import 'package:frontend/features/home/presentation/widgets/menu_card.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/config/app_routes.dart';
import 'package:frontend/constants/colors.dart';

class HomePage extends StatefulWidget {
  final DashboardRepository? dashboardRepository;

  const HomePage({super.key, this.dashboardRepository});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<DashboardStats> _statsFuture;

  late final DashboardRepository _dashboardRepository;

  @override
  void initState() {
    super.initState();
    _dashboardRepository = widget.dashboardRepository ?? createDashboardRepository();
    _statsFuture = _dashboardRepository.getDashboardStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                maxWidth: constraints.maxWidth,
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- LEFT COLUMN ---
                    Expanded(
                      flex: 7,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildGreeting(),
                          const SizedBox(height: 24),
                          TopStatsRow(statsFuture: _statsFuture),
                          const SizedBox(height: 24),
                          const HomeActionButtons(),
                          const SizedBox(height: 32),
                          _buildCardsGrid(context),
                          const SizedBox(height: 24),
                          BottomStatsBar(statsFuture: _statsFuture),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    // --- RIGHT COLUMN ---
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          const RecentActivityPanel(),
                          const SizedBox(height: 24),
                          UsefulInfoPanel(statsFuture: _statsFuture),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGreeting() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(AppTextsHome.homeTitle, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          ],
        ),
        SizedBox(height: 8),
        Text(AppTextsHome.homeSubtitle, style: TextStyle(fontSize: 24, color: AppColors.textGrey)),
      ],
    );
  }

  Widget _buildCardsGrid(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 240,
          child: Row(
            children: [
              Expanded(
                child: MenuCard(
                  icon: Icons.warning_amber_rounded,
                  title: AppTextsHome.reportsTitle,
                  subtitle: AppTextsHome.reportsSubtitle,
                  onTap: () => context.go(AppRoutes.reports),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: MenuCard(
                  icon: Icons.bar_chart,
                  title: AppTextsHome.surveysTitle,
                  subtitle: AppTextsHome.surveysSubtitle,
                  onTap: () => context.go(AppRoutes.surveys),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: MenuCard(
                  icon: Icons.calendar_month,
                  title: AppTextsHome.agendaTitle,
                  subtitle: AppTextsHome.agendaSubtitle,
                  onTap: () => context.go(AppRoutes.agenda),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 110,
          child: Row(
            children: [
              Expanded(
                child: MenuCard(
                  style: MenuCardStyle.compact,
                  icon: Icons.article_outlined,
                  title: AppTextsHome.newsTitle,
                  subtitle: AppTextsHome.newsSubtitle,
                  onTap: () => context.go(AppRoutes.news),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: MenuCard(
                  style: MenuCardStyle.compact,
                  icon: Icons.info_outline,
                  title: AppTextsHome.infoTitle,
                  subtitle: AppTextsHome.infoSubtitle,
                  onTap: () => context.go(AppRoutes.usefulInfo),
                ),
              ),
              const SizedBox(width: 24),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ],
    );
  }
}