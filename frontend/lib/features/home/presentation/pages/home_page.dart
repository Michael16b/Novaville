import 'package:flutter/material.dart';
import 'package:frontend/constants/texts/texts_home.dart';
import 'package:frontend/features/home/data/dashboard_repository.dart';
import 'package:frontend/features/home/data/dashboard_repository_factory.dart';
import 'package:frontend/features/home/domain/dashboard_stats.dart';
import 'package:frontend/features/home/presentation/widgets/dashboard_stats_widgets.dart';
import 'package:frontend/features/home/presentation/widgets/home_action_buttons.dart';
import 'package:frontend/features/home/presentation/widgets/home_sidebar_panels.dart';
import 'package:frontend/features/home/presentation/widgets/menu_card.dart';
import 'package:frontend/ui/assets.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/config/app_routes.dart';
import 'package:frontend/constants/colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<DashboardStats> _statsFuture;
  final DashboardRepository _dashboardRepository = createDashboardRepository();

  @override
  void initState() {
    super.initState();
    _statsFuture = _dashboardRepository.getDashboardStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Background
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 300,
                  child: Opacity(
                    opacity: 0.15,
                    child: Image.asset(
                      AppAssets.home_background,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Main content
                SingleChildScrollView(
                  padding: const EdgeInsets.all(32.0),
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
                            TopStatsRow(statsFuture: _statsFuture), // Refactorisé !
                            const SizedBox(height: 24),
                            const HomeActionButtons(), // Refactorisé !
                            const SizedBox(height: 32),
                            _buildCardsGrid(context),
                            const SizedBox(height: 24),
                            BottomStatsBar(statsFuture: _statsFuture), // Refactorisé !
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      // --- RIGHT COLUMN ---
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            const RecentActivityPanel(), // Refactorisé !
                            const SizedBox(height: 24),
                            UsefulInfoPanel(statsFuture: _statsFuture), // Refactorisé !
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // J'ai gardé le Greeting et la Grille ici car ils gèrent la structure
  // de base de la page et la navigation (GoRouter).

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
                  title: AppTextsHome.pollsTitle,
                  subtitle: AppTextsHome.pollsSubtitle,
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