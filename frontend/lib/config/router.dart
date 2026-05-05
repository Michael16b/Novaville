import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend/config/app_routes.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/features/agenda/presentation/pages/agenda_page.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/features/auth/presentation/pages/login_page.dart';
import 'package:frontend/features/auth/presentation/pages/register_page.dart';
import 'package:frontend/features/home/presentation/pages/home_page.dart';
import 'package:frontend/features/news/presentation/pages/news_page.dart';
import 'package:frontend/features/reports/presentation/pages/reports_page.dart';
import 'package:frontend/features/surveys/presentation/pages/surveys_page.dart';
import 'package:frontend/features/useful_info/presentation/pages/useful_info_page_provider.dart';
import 'package:frontend/features/town_hall/presentation/pages/town_hall_page.dart';
import 'package:frontend/features/users/data/models/user_role.dart';
import 'package:frontend/features/users/presentation/pages/bulk_user_creation_page.dart';
import 'package:frontend/features/users/presentation/pages/credentials_share_page.dart';
import 'package:frontend/features/users/presentation/pages/my_account_page.dart';
import 'package:frontend/features/users/presentation/pages/set_password_screen.dart';
import 'package:frontend/features/users/presentation/pages/user_accounts_page.dart';
import 'package:frontend/ui/layouts/secured_layout.dart';
import 'package:go_router/go_router.dart';

/// Returns a [Page] with no transition on web, or the default [MaterialPage]
/// transition on mobile / desktop native platforms.
Page<T> _buildPage<T>({required GoRouterState state, required Widget child}) {
  if (kIsWeb) {
    return NoTransitionPage<T>(key: state.pageKey, child: child);
  }
  return MaterialPage<T>(key: state.pageKey, child: child);
}

/// Pure function containing the authentication redirect logic.
///
/// Returns the path to redirect to, or `null` if no redirect is needed.
/// Extracted as a standalone function so it can be unit-tested independently
/// of [GoRouter].
String? authRedirect({
  required AuthStatus authStatus,
  required String currentLocation,
  String? fromLocation,
}) {
  const knownRoutes = <String>{
    AppRoutes.home,
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.loading,
    AppRoutes.reports,
    AppRoutes.surveys,
    AppRoutes.agenda,
    AppRoutes.news,
    AppRoutes.usefulInfo,
    AppRoutes.usefulInfoEdit,
    AppRoutes.myAccount,
    AppRoutes.townHall,
    AppRoutes.userAccounts,
    AppRoutes.bulkUserCreation,
    AppRoutes.credentialsShare,
    '/set-password',
  };
  const publicRoutes = <String>{
    AppRoutes.home,
    AppRoutes.register,
    AppRoutes.reports,
    AppRoutes.agenda,
    AppRoutes.usefulInfo,
    '/set-password',
  };
  final normalizedLocation =
      currentLocation.endsWith('/') && currentLocation.length > 1
      ? currentLocation.substring(0, currentLocation.length - 1)
      : currentLocation;
  final isOnLoading = currentLocation == AppRoutes.loading;
  final isLoggingIn = currentLocation == AppRoutes.login;
  final isPublicRoute = publicRoutes.contains(normalizedLocation);
  final isCredentialsShare =
      normalizedLocation == AppRoutes.credentialsShare ||
      normalizedLocation.startsWith('${AppRoutes.credentialsShare}/');
  final isKnownRoute =
      knownRoutes.contains(normalizedLocation) || isCredentialsShare;

  // Unknown URL => always fallback to home instead of login.
  if (!isKnownRoute) {
    return AppRoutes.home;
  }

  if (isCredentialsShare) {
    return null;
  }

  final intendedLocation = (fromLocation != null && fromLocation.isNotEmpty)
      ? fromLocation
      : currentLocation;
  // While checking / authenticating, show a dedicated loading screen.
  if (authStatus == AuthStatus.checking ||
      authStatus == AuthStatus.authenticating) {
    if (isOnLoading) {
      return null;
    }
    final encodedFrom = Uri.encodeQueryComponent(intendedLocation);
    return '${AppRoutes.loading}?from=$encodedFrom';
  }
  final isAuthenticated = authStatus == AuthStatus.authenticated;
  // Not authenticated → send to login (and away from loading).
  if (!isAuthenticated) {
    if (isCredentialsShare || isLoggingIn || isPublicRoute) {
      return null;
    }
    final encodedFrom = Uri.encodeQueryComponent(intendedLocation);
    return '${AppRoutes.login}?from=$encodedFrom';
  }
  // Authenticated → leave login / loading pages.
  if (isLoggingIn || isOnLoading) {
    if (intendedLocation == AppRoutes.login ||
        intendedLocation == AppRoutes.loading) {
      return AppRoutes.home;
    }
    return intendedLocation;
  }
  return null;
}

/// Check if user has required role for a protected route.
///
/// Returns the path to redirect to (home), or `null` if access is allowed.
String? roleRedirect({
  required UserRole? userRole,
  required UserRole requiredRole,
}) {
  if (userRole != requiredRole) {
    return AppRoutes.home; // Redirect to home if user doesn't have the role
  }
  return null; // Allow access
}

/// Check if user has any of the required roles for a protected route.
///
/// Returns the path to redirect to (home), or `null` if access is allowed.
String? anyRoleRedirect({
  required UserRole? userRole,
  required List<UserRole> allowedRoles,
}) {
  if (userRole == null || !allowedRoles.contains(userRole)) {
    return AppRoutes.home;
  }
  return null; // Allow access
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
      fromLocation: state.uri.queryParameters['from'],
    ),
    routes: [
      // ── Loading route (shown while auth status is being checked) ──────────
      GoRoute(
        path: AppRoutes.loading,
        pageBuilder: (context, state) => _buildPage(
          state: state,
          child: const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
        ),
      ),
      // ── Public route ──────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) =>
            NoTransitionPage(key: state.pageKey, child: const LoginPage()),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) =>
            NoTransitionPage(key: state.pageKey, child: const RegisterPage()),
      ),
      GoRoute(
        path: '/set-password',
        pageBuilder: (context, state) {
          final query = state.uri.queryParameters;
          return NoTransitionPage(
            key: state.pageKey,
            child: SetPasswordScreen(
              username: query['username'] ?? '',
              email: query['email'] ?? '',
              firstName: query['first_name'],
              lastName: query['last_name'],
              tempPassword: query['temp_password'],
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.credentialsShare,
        pageBuilder: (context, state) =>
            _buildPage(state: state, child: const CredentialsSharePage()),
      ),
      // ── Secured shell — all child routes share the AppBanner layout ───────
      ShellRoute(
        pageBuilder: (context, state, child) => NoTransitionPage(
          key: state.pageKey,
          child: SecuredLayout(
            currentLocation: state.matchedLocation,
            child: child,
          ),
        ),
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
            path: AppRoutes.townHall,
            redirect: (context, state) => anyRoleRedirect(
              userRole: authBloc.state.user?.role,
              allowedRoles: [UserRole.elected, UserRole.globalAdmin],
            ),
            pageBuilder: (context, state) =>
                _buildPage(state: state, child: const TownHallPage()),
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
                _buildPage(state: state, child: const UsefulInfoPageProvider()),
          ),
          GoRoute(
            path: AppRoutes.usefulInfoEdit,
            pageBuilder: (context, state) => _buildPage(
              state: state,
              child: const UsefulInfoPageProvider(startInEditMode: true),
            ),
          ),
          GoRoute(
            path: AppRoutes.myAccount,
            pageBuilder: (context, state) =>
                _buildPage(state: state, child: const MyAccountPage()),
          ),
          GoRoute(
            path: AppRoutes.userAccounts,
            redirect: (context, state) => roleRedirect(
              userRole: authBloc.state.user?.role,
              requiredRole: UserRole.globalAdmin,
            ),
            pageBuilder: (context, state) =>
                _buildPage(state: state, child: const UserAccountsPage()),
          ),
          GoRoute(
            path: AppRoutes.bulkUserCreation,
            redirect: (context, state) => roleRedirect(
              userRole: authBloc.state.user?.role,
              requiredRole: UserRole.globalAdmin,
            ),
            pageBuilder: (context, state) =>
                _buildPage(state: state, child: const BulkUserCreationPage()),
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
    _subscription = bloc.stream.listen(
      (_) => notifyListeners(),
      onError: (error) => notifyListeners(),
    );
  }
  late final StreamSubscription<AuthState> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
