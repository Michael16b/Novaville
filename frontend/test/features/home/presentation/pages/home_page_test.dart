import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/config/app_routes.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_home.dart';
import 'package:frontend/features/home/presentation/pages/home_page.dart';
import 'package:frontend/features/home/presentation/widgets/menu_card.dart';
import 'package:frontend/features/home/data/dashboard_repository.dart';
import 'package:frontend/features/home/domain/dashboard_stats.dart';
import 'package:go_router/go_router.dart';

// --- 1. CRÉATION DU FAUX REPOSITORY POUR LES TESTS ---
class FakeDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardStats> getDashboardStats() async {
    // Renvoie des données statiques instantanément
    return DashboardStats(
      totalCitizens: 1200,
      reportsThisMonth: 45,
      pollParticipationRate: 68,
      pendingReports: 12,
      activeSurveys: 3,
      eventsThisWeek: 2,
      unresolvedReportsRoads: 5,
      unresolvedReportsCleanliness: 4,
      unresolvedReportsLighting: 3,
    );
  }
}

void main() {
  group('HomePage', () {
    // Instance de notre faux repository
    late FakeDashboardRepository fakeRepository;

    setUp(() {
      fakeRepository = FakeDashboardRepository();
    });

    // Petit widget helper pour éviter de répéter MaterialApp à chaque fois
    Widget createTestableWidget() {
      return MaterialApp(
        // On injecte notre faux repository ici !
        home: HomePage(dashboardRepository: fakeRepository),
      );
    }

    testWidgets('renders title and subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle(); // Attend la fin du chargement du FakeRepository

      expect(find.text(AppTextsHome.homeTitle), findsOneWidget);
      expect(find.text(AppTextsHome.homeSubtitle), findsOneWidget);
    });

    testWidgets('title has correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      final titleFinder = find.text(AppTextsHome.homeTitle);
      final Text titleWidget = tester.widget(titleFinder);
      expect(titleWidget.style?.fontSize, 32);
      expect(titleWidget.style?.fontWeight, FontWeight.bold);
      expect(titleWidget.style?.color, AppColors.textDark);
    });

    testWidgets('subtitle has correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      final subtitleFinder = find.text(AppTextsHome.homeSubtitle);
      final Text subtitleWidget = tester.widget(subtitleFinder);
      expect(subtitleWidget.style?.fontSize, 24);
      expect(subtitleWidget.style?.color, AppColors.textGrey);
    });

    testWidgets('renders MenuCards for all features', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      final reportsCardFinder = find.text(AppTextsHome.reportsTitle);
      await tester.ensureVisible(reportsCardFinder);

      expect(reportsCardFinder, findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      expect(find.text(AppTextsHome.surveysTitle), findsOneWidget);
      expect(find.byIcon(Icons.bar_chart), findsOneWidget);

      expect(find.text(AppTextsHome.agendaTitle), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month), findsOneWidget);

      expect(find.text(AppTextsHome.newsTitle), findsOneWidget);
      expect(find.byIcon(Icons.article_outlined), findsOneWidget);

      expect(find.text(AppTextsHome.infoTitle), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('MenuCards are tappable and navigation works', (WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => HomePage(dashboardRepository: fakeRepository),
          ),
          GoRoute(
            path: AppRoutes.reports,
            builder: (context, state) => const Scaffold(body: Text('Reports Page')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final cardToTap = find.text(AppTextsHome.reportsTitle);
      await tester.ensureVisible(cardToTap);
      await tester.tap(cardToTap);

      await tester.pumpAndSettle(); // Attend la fin de la transition de page

      expect(find.text('Reports Page'), findsOneWidget);
    });

    testWidgets('HomePage layout uses Row and Column', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      expect(find.byType(Row), findsWidgets);
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('MenuCard widget count matches expected', (WidgetTester tester) async {
      await tester.pumpWidget(createTestableWidget());
      await tester.pumpAndSettle();

      // 3 larges + 2 compacts
      expect(find.byType(MenuCard), findsNWidgets(5));
    });
  });
}