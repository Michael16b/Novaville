import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/features/users/data/models/user.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/config/app_routes.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_home.dart';
import 'package:frontend/features/home/presentation/pages/home_page.dart';
import 'package:frontend/features/home/presentation/widgets/menu_card.dart';
import 'package:frontend/features/home/data/dashboard_repository.dart';
import 'package:frontend/features/home/domain/dashboard_stats.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/features/reports/application/bloc/reports_bloc/reports_bloc.dart';
import 'package:frontend/features/agenda/application/bloc/agenda_bloc/agenda_bloc.dart';

// --- 1. MOCKS ET FAKES ---
class FakeDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardStats> getDashboardStats() async {
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
      recentActivities: const <RecentActivity>[],
    );
  }
}

class MockAuthBloc extends Mock implements AuthBloc {}
class MockReportsBloc extends Mock implements ReportsBloc {}
class MockAgendaBloc extends Mock implements AgendaBloc {}

class FakeReportsState extends Fake implements ReportsState {}
class FakeAgendaState extends Fake implements AgendaState {}

void main() {
  group('HomePage', () {
    late FakeDashboardRepository fakeRepository;
    late MockAuthBloc mockAuthBloc;
    late MockReportsBloc mockReportsBloc;
    late MockAgendaBloc mockAgendaBloc;

    setUpAll(() {
      registerFallbackValue(FakeReportsState());
      registerFallbackValue(FakeAgendaState());
    });

    setUp(() {
      fakeRepository = FakeDashboardRepository();
      mockAuthBloc = MockAuthBloc();
      mockReportsBloc = MockReportsBloc();
      mockAgendaBloc = MockAgendaBloc();

      when(
        () => mockAuthBloc.state,
      ).thenReturn(
        const AuthState.authenticated(
          user: User(
            id: 1,
            username: 'citizen',
            email: 'citizen@test.com',
            firstName: 'Test',
            lastName: 'Citizen',
            role: null,
          ),
        ),
      );
      when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());

      when(() => mockReportsBloc.state).thenReturn(FakeReportsState());
      when(() => mockReportsBloc.stream).thenAnswer((_) => const Stream.empty());

      when(() => mockAgendaBloc.state).thenReturn(FakeAgendaState());
      when(() => mockAgendaBloc.stream).thenAnswer((_) => const Stream.empty());
    });

    void setLargeScreen(WidgetTester tester) {
      tester.view.physicalSize = const Size(3840, 2160);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    }

    Widget createTestableWidget({required Widget child}) {
      return MaterialApp(
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              BlocProvider<ReportsBloc>.value(value: mockReportsBloc),
              BlocProvider<AgendaBloc>.value(value: mockAgendaBloc),
            ],
            child: child,
          ),
        ),
      );
    }

    void setUnauthenticatedState() {
      when(
        () => mockAuthBloc.state,
      ).thenReturn(const AuthState.unauthenticated());
    }

    testWidgets('renders title and subtitle', (WidgetTester tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(createTestableWidget(
        child: HomePage(dashboardRepository: fakeRepository),
      ));
      await tester.pumpAndSettle();

      expect(find.text(AppTextsHome.homeTitle), findsOneWidget);
      expect(find.text(AppTextsHome.homeSubtitle), findsOneWidget);
    });

    testWidgets('title has correct styling', (WidgetTester tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(createTestableWidget(
        child: HomePage(dashboardRepository: fakeRepository),
      ));
      await tester.pumpAndSettle();

      final titleFinder = find.text(AppTextsHome.homeTitle);
      final Text titleWidget = tester.widget(titleFinder);
      expect(titleWidget.style?.fontSize, 32);
      expect(titleWidget.style?.fontWeight, FontWeight.bold);
      expect(titleWidget.style?.color, AppColors.textDark);
    });

    testWidgets('subtitle has correct styling', (WidgetTester tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(createTestableWidget(
        child: HomePage(dashboardRepository: fakeRepository),
      ));
      await tester.pumpAndSettle();

      final subtitleFinder = find.text(AppTextsHome.homeSubtitle);
      final Text subtitleWidget = tester.widget(subtitleFinder);
      expect(subtitleWidget.style?.fontSize, 24);
      expect(subtitleWidget.style?.color, AppColors.textGrey);
    });

    testWidgets('renders MenuCards for all features', (WidgetTester tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(createTestableWidget(
        child: HomePage(dashboardRepository: fakeRepository),
      ));
      await tester.pumpAndSettle();

      final reportsCard = find.widgetWithText(MenuCard, AppTextsHome.reportsTitle);
      expect(reportsCard, findsOneWidget);
      expect(find.descendant(of: reportsCard, matching: find.byIcon(Icons.warning_amber_rounded)), findsOneWidget);

      final surveysCard = find.widgetWithText(MenuCard, AppTextsHome.surveysTitle);
      expect(surveysCard, findsOneWidget);
      expect(find.descendant(of: surveysCard, matching: find.byIcon(Icons.bar_chart)), findsOneWidget);

      final agendaCard = find.widgetWithText(MenuCard, AppTextsHome.agendaTitle);
      expect(agendaCard, findsOneWidget);
      expect(find.descendant(of: agendaCard, matching: find.byIcon(Icons.calendar_month)), findsOneWidget);

      final newsCard = find.widgetWithText(MenuCard, AppTextsHome.newsTitle);
      expect(newsCard, findsOneWidget);
      expect(find.descendant(of: newsCard, matching: find.byIcon(Icons.article_outlined)), findsOneWidget);

      final infoCard = find.widgetWithText(MenuCard, AppTextsHome.infoTitle);
      expect(infoCard, findsOneWidget);
      expect(find.descendant(of: infoCard, matching: find.byIcon(Icons.info_outline)), findsOneWidget);
    });

    testWidgets('MenuCards are tappable and navigation works', (WidgetTester tester) async {
      setLargeScreen(tester);

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

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          builder: (context, child) {
            return MultiBlocProvider(
              providers: [
                BlocProvider<AuthBloc>.value(value: mockAuthBloc),
                BlocProvider<ReportsBloc>.value(value: mockReportsBloc),
                BlocProvider<AgendaBloc>.value(value: mockAgendaBloc),
              ],
              child: Scaffold(body: child!),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      final cardToTap = find.text(AppTextsHome.reportsTitle);
      await tester.ensureVisible(cardToTap);
      await tester.tap(cardToTap);

      await tester.pumpAndSettle();

      expect(find.text('Reports Page'), findsOneWidget);
    });

    testWidgets('HomePage layout uses Row and Column', (WidgetTester tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(createTestableWidget(
        child: HomePage(dashboardRepository: fakeRepository),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Row), findsWidgets);
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('MenuCard widget count matches expected', (WidgetTester tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(createTestableWidget(
        child: HomePage(dashboardRepository: fakeRepository),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(MenuCard), findsNWidgets(5));
    });

    testWidgets('hides bottom stats bar when user is not authenticated', (
      WidgetTester tester,
    ) async {
      setLargeScreen(tester);
      setUnauthenticatedState();

      await tester.pumpWidget(
        createTestableWidget(
          child: HomePage(dashboardRepository: fakeRepository),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining(AppTextsHome.platformUsagePrefix), findsNothing);
      expect(find.textContaining(AppTextsHome.reportsMonthSuffix), findsNothing);
      expect(find.textContaining(AppTextsHome.pollParticipationPrefix), findsNothing);
    });
  });
}
