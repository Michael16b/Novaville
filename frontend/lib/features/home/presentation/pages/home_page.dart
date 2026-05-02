import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/constants/texts/texts_home.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/features/home/data/dashboard_repository.dart';
import 'package:frontend/features/home/data/dashboard_repository_factory.dart';
import 'package:frontend/features/home/domain/dashboard_stats.dart';
import 'package:frontend/features/home/presentation/widgets/dashboard_stats_widgets.dart';
import 'package:frontend/features/home/presentation/widgets/home_sidebar_panels.dart';
import 'package:frontend/features/home/presentation/widgets/menu_card.dart';
import 'package:frontend/ui/assets.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/config/app_routes.dart';
import 'package:frontend/constants/colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.dashboardRepository});
  final DashboardRepository? dashboardRepository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<DashboardStats> _statsFuture;
  late DashboardRepository _dashboardRepository = createDashboardRepository();
  String? _statsAuthKey;

  @override
  void initState() {
    super.initState();
    _dashboardRepository =
        widget.dashboardRepository ?? createDashboardRepository();
    _statsFuture = _dashboardRepository.getDashboardStats();
  }

  String _authKey(AuthState state) {
    if (state.status != AuthStatus.authenticated) {
      return state.status.name;
    }

    final user = state.user;
    return '${state.status.name}:${user?.id ?? 'unknown'}:${user?.role?.value ?? 'none'}';
  }

  void _reloadStatsFor(AuthState state) {
    final authKey = _authKey(state);
    if (_statsAuthKey == authKey) {
      return;
    }

    _statsAuthKey = authKey;
    setState(() {
      _statsFuture = _dashboardRepository.getDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          _authKey(previous) != _authKey(current),
      listener: (context, state) => _reloadStatsFor(state),
      builder: (context, authState) {
        final isAuthenticated = authState.status == AuthStatus.authenticated;

        return Scaffold(
          backgroundColor: AppColors.page,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isMobile = width < 768;
              final showSidebarBelow = width < 1100;
              final horizontalPadding = isMobile
                  ? 16.0
                  : width < 1280
                  ? 24.0
                  : 32.0;

              final mainColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreeting(context, isMobile: isMobile),
                  const SizedBox(height: 48),
                  _buildCardsGrid(context),
                  if (isAuthenticated) ...[
                    const SizedBox(height: 36),
                    BottomStatsBar(statsFuture: _statsFuture),
                  ],
                ],
              );

              final sidebarColumn = Column(
                children: [
                  RecentActivityPanel(statsFuture: _statsFuture),
                  const SizedBox(height: 24),
                  UsefulInfoPanel(statsFuture: _statsFuture),
                ],
              );

              return Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: isMobile ? 220 : 300,
                    child: Opacity(
                      opacity: 0.15,
                      child: Image.asset(
                        AppAssets.home_background,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    padding: EdgeInsets.all(horizontalPadding),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1440),
                        child: showSidebarBelow
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  mainColumn,
                                  const SizedBox(height: 24),
                                  sidebarColumn,
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 7, child: mainColumn),
                                  const SizedBox(width: 32),
                                  Expanded(flex: 3, child: sidebarColumn),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildGreeting(BuildContext context, {required bool isMobile}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          children: [
            Text(
              AppTextsHome.homeTitle,
              style: TextStyle(
                fontSize: isMobile ? 26 : 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          AppTextsHome.homeSubtitle,
          style: TextStyle(
            fontSize: isMobile ? 18 : 24,
            color: AppColors.textGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildCardsGrid(BuildContext context) {
    final isAuthenticated = context.select<AuthBloc, bool>(
      (bloc) => bloc.state.status == AuthStatus.authenticated,
    );

    return FutureBuilder<DashboardStats>(
      future: _statsFuture,
      builder: (context, snapshot) {
        final stats = snapshot.data;
        final pendingReports = stats?.pendingReports.toString() ?? '-';
        final activeSurveys = stats?.activeSurveys.toString() ?? '-';
        final eventsThisWeek = stats?.eventsThisWeek.toString() ?? '-';

        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 900;
            final spacing = isNarrow ? 24.0 : 32.0;
            final availableWidth = constraints.maxWidth;
            final largeColumns = isAuthenticated
                ? (availableWidth >= 720 ? 3 : 1)
                : (availableWidth >= 900 ? 2 : 1);
            final compactColumns = isAuthenticated
                ? (availableWidth >= 900 ? 2 : 1)
                : 1;
            final largeCardWidth =
                (availableWidth - (spacing * (largeColumns - 1))) /
                largeColumns;
            final compactCardWidth = compactColumns == 1
                ? availableWidth
                : (availableWidth - spacing) / 2;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    _buildLargeCardItem(
                      width: largeCardWidth,
                      child: MenuCard(
                        icon: Icons.warning_amber_rounded,
                        title: AppTextsHome.reportsTitle,
                        subtitle: AppTextsHome.reportsSubtitle,
                        statValue: pendingReports,
                        statLabel: AppTextsHome.pendingReports,
                        onTap: () => context.go(AppRoutes.reports),
                      ),
                    ),
                    if (isAuthenticated)
                      _buildLargeCardItem(
                        width: largeCardWidth,
                        child: MenuCard(
                          icon: Icons.bar_chart,
                          title: AppTextsHome.surveysTitle,
                          subtitle: AppTextsHome.surveysSubtitle,
                          statValue: activeSurveys,
                          statLabel: AppTextsHome.activePolls,
                          onTap: () => context.go(AppRoutes.surveys),
                        ),
                      ),
                    _buildLargeCardItem(
                      width: largeCardWidth,
                      child: MenuCard(
                        icon: Icons.calendar_month,
                        title: AppTextsHome.agendaTitle,
                        subtitle: AppTextsHome.agendaSubtitle,
                        statValue: eventsThisWeek,
                        statLabel: AppTextsHome.eventsThisWeek,
                        onTap: () => context.go(AppRoutes.agenda),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing),
                Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    if (isAuthenticated)
                      _buildCompactCardItem(
                        width: compactCardWidth,
                        child: MenuCard(
                          style: MenuCardStyle.compact,
                          icon: Icons.article_outlined,
                          title: AppTextsHome.newsTitle,
                          subtitle: AppTextsHome.newsSubtitle,
                          onTap: () => context.go(AppRoutes.news),
                        ),
                      ),
                    _buildCompactCardItem(
                      width: compactCardWidth,
                      child: MenuCard(
                        style: MenuCardStyle.compact,
                        icon: Icons.info_outline,
                        title: AppTextsHome.infoTitle,
                        subtitle: AppTextsHome.infoSubtitle,
                        onTap: () => context.go(AppRoutes.usefulInfo),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLargeCardItem({required double width, required Widget child}) {
    final height = width < 240
        ? 230.0
        : width < 320
        ? 215.0
        : 220.0;

    return SizedBox(width: width, height: height, child: child);
  }

  Widget _buildCompactCardItem({required double width, required Widget child}) {
    return SizedBox(width: width, height: 110, child: child);
  }
}
