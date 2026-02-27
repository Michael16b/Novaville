import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/config/app_routes.dart';
import 'package:frontend/config/router.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';

void main() {
  group('authRedirect', () {
    group('when AuthStatus is checking', () {
      test('redirects to /loading when not already there', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.checking,
            currentLocation: AppRoutes.home,
          ),
          AppRoutes.loading,
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

      test('redirects to /loading from login page', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.checking,
            currentLocation: AppRoutes.login,
          ),
          AppRoutes.loading,
        );
      });
    });

    group('when AuthStatus is authenticating', () {
      test('redirects to /loading when not already there', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.authenticating,
            currentLocation: AppRoutes.home,
          ),
          AppRoutes.loading,
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

      test('redirects to /home when on loading page', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.authenticated,
            currentLocation: AppRoutes.loading,
          ),
          AppRoutes.home,
        );
      });

      test('redirects to savedPath instead of /home when savedPath is provided', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.authenticated,
            currentLocation: AppRoutes.loading,
            savedPath: AppRoutes.myAccount,
          ),
          AppRoutes.myAccount,
        );
      });
    });
  });
}
