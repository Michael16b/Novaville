import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/config/app_routes.dart';
import 'package:frontend/features/account/presentation/pages/my_account_page.dart';
import 'package:frontend/features/agenda/presentation/pages/agenda_page.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/features/auth/presentation/pages/login_page.dart';
import 'package:frontend/features/home/presentation/pages/home_page.dart';
import 'package:frontend/features/news/presentation/pages/news_page.dart';
import 'package:frontend/features/reports/presentation/pages/reports_page.dart';
import 'package:frontend/features/surveys/presentation/pages/surveys_page.dart';
import 'package:frontend/features/useful_info/presentation/pages/useful_info_page.dart';
import 'package:frontend/ui/layouts/secured_layout.dart';
import 'package:go_router/go_router.dart';
/// Returns a [Page] with no transition on web, or the default [MaterialPage]
/// transition on mobile / desktop native platforms.
Page<T> _buildPage<T>({
  required GoRouterState state,
  required Widget child,
}) {
  if (kIsWeb) {
    return NoTransitionPage<T>(key: state.pageKey, child: child);
  }
  return MaterialPage<T>(key: state.pageKey, child: child);
}
/// Pure function containing the authentication redirect logic.
///
/// Returns the path to redirect to, or [null] if no redirect is needed.
/// Extracted as a standalone function so it can be unit-tested independently
/// of [GoRouter].
String? authRedirect({
  required AuthStatus authStatus,
  required String currentLocation,
}) {
  final isOnLoading = currentLocation == AppRoutes.loading;
  final isLoggingIn = currentLocation == AppRoutes.login;
  // While checking / authenticating, show a dedicated loading screen.
  if (authStatus == AuthStatus.checking ||
      authStatus == AuthStatus.authenticating) {
    return isOnLoading ? null : AppRoutes.loading;
  }
  final isAuthenticated = authStatus == AuthStatus.authenticated;
  // Not authenticated → send to login (and away from loading).
  if (!isAuthenticated) {
    return isLoggingIn ? null : AppRoutes.login;
  }
  // Authenticated → leave login / loading pages.
  if (isLoggingIn || isOnLoading) {
    return AppRoutes.home;
  }
  return null;
}

/// Builds and returns the application [GoRouter].
///
/// Receives the [AuthBloc] directly so the router can be created once in
/// [State.didChangeDependencies] without needing a [BuildContext] at build time.
GoRouter buildRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: _AuthBlocListenable(authBloc),
    redirect: (context, state) => authRedirect(
      authStatus: authBloc.state.status,
      currentLocation: state.matchedLocation,
    ),
    routes: [
      // ── Loading route (shown while auth status is being checked) ──────────
      GoRoute(
        path: AppRoutes.loading,
        pageBuilder: (context, state) => _buildPage(
          state: state,
          child: const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
      // ── Public route ──────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) =>
            _buildPage(state: state, child: const LoginPage()),
      ),
      // ── Secured shell — all child routes share the AppBanner layout ───────
      ShellRoute(
        builder: (context, state, child) {
          final isHome = state.matchedLocation == AppRoutes.home;
          return SecuredLayout(isHomePage: isHome, child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) =>
                _buildPage(state: state, child: const HomePage()),
          ),
          GoRoute(
            path: AppRoutes.reports,
            pageBuilder: (context, state) =>
                _buildPage(state: state, child: const ReportsPage()),
          ),
          GoRoute(
            path: AppRoutes.surveys,
            pageBuilder: (context, state) =>
                _buildPage(state: state, child: const SurveysPage()),
          ),
          GoRoute(
            path: AppRoutes.agenda,
            pageBuilder: (context, state) =>
                _buildPage(state: state, child: const AgendaPage()),
          ),
          GoRoute(
            path: AppRoutes.news,
            pageBuilder: (context, state) =>
                _buildPage(state: state, child: const NewsPage()),
          ),
          GoRoute(
            path: AppRoutes.usefulInfo,
            pageBuilder: (context, state) =>
                _buildPage(state: state, child: const UsefulInfoPage()),
          ),
          GoRoute(
            path: AppRoutes.myAccount,
            pageBuilder: (context, state) =>
                _buildPage(state: state, child: const MyAccountPage()),
          ),
        ],
      ),
    ],
  );
}
/// Adapts [AuthBloc] stream to [Listenable] so GoRouter re-evaluates
/// the redirect whenever the authentication state changes.
class _AuthBlocListenable extends ChangeNotifier {
  _AuthBlocListenable(AuthBloc bloc) {
    _subscription = bloc.stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<AuthState> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
