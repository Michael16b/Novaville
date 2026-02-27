import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/config/app_routes.dart';
import 'package:frontend/config/router.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';

void main() {
  group('authRedirect', () {
    group('when AuthStatus is checking', () {
      test('redirects to /loading with from param when not already there', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.checking,
            currentLocation: AppRoutes.home,
          ),
          '${AppRoutes.loading}?from=${Uri.encodeComponent(AppRoutes.home)}',
        );
      });

      test('stays on /loading (returns null) when already there', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.checking,
            currentLocation: AppRoutes.loading,
          ),
          isNull,
        );
      });

      test('redirects to /loading without from param when on login page', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.checking,
            currentLocation: AppRoutes.login,
          ),
          AppRoutes.loading,
        );
      });

      test('redirects to /loading with from param when on a protected route', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.checking,
            currentLocation: AppRoutes.myAccount,
          ),
          '${AppRoutes.loading}?from=${Uri.encodeComponent(AppRoutes.myAccount)}',
        );
      });
    });

    group('when AuthStatus is authenticating', () {
      test('redirects to /loading with from param when not already there', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.authenticating,
            currentLocation: AppRoutes.home,
          ),
          '${AppRoutes.loading}?from=${Uri.encodeComponent(AppRoutes.home)}',
        );
      });

      test('stays on /loading (returns null) when already there', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.authenticating,
            currentLocation: AppRoutes.loading,
          ),
          isNull,
        );
      });
    });

    group('when AuthStatus is unauthenticated', () {
      test('redirects to /login when on home page', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.unauthenticated,
            currentLocation: AppRoutes.home,
          ),
          AppRoutes.login,
        );
      });

      test('redirects to /login when on a protected route', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.unauthenticated,
            currentLocation: AppRoutes.reports,
          ),
          AppRoutes.login,
        );
      });

      test('stays on /login (returns null) when already on login page', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.unauthenticated,
            currentLocation: AppRoutes.login,
          ),
          isNull,
        );
      });
    });

    group('when AuthStatus is failure', () {
      test('redirects to /login when on a protected route', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.failure,
            currentLocation: AppRoutes.home,
          ),
          AppRoutes.login,
        );
      });

      test('stays on /login (returns null) when already on login page', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.failure,
            currentLocation: AppRoutes.login,
          ),
          isNull,
        );
      });
    });

    group('when AuthStatus is authenticated', () {
      test('returns null when on home page (no redirect needed)', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.authenticated,
            currentLocation: AppRoutes.home,
          ),
          isNull,
        );
      });

      test('returns null when on a protected route', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.authenticated,
            currentLocation: AppRoutes.reports,
          ),
          isNull,
        );
      });

      test('redirects to /home when on login page', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.authenticated,
            currentLocation: AppRoutes.login,
          ),
          AppRoutes.home,
        );
      });

      test('redirects to /home when on loading page with no returnUrl', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.authenticated,
            currentLocation: AppRoutes.loading,
          ),
          AppRoutes.home,
        );
      });

      test('redirects to returnUrl when on loading page with a returnUrl', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.authenticated,
            currentLocation: AppRoutes.loading,
            returnUrl: AppRoutes.myAccount,
          ),
          AppRoutes.myAccount,
        );
      });
    });
  });
}
