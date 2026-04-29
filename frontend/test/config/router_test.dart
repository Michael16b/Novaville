import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/config/app_routes.dart';
import 'package:frontend/config/router.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';

void main() {
  group('authRedirect', () {
    group('when AuthStatus is checking', () {
      test('Given auth status is checking when current route is not loading then it redirects to loading', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.checking,
            currentLocation: AppRoutes.home,
          ),
          '${AppRoutes.loading}?from=%2F',
        );
      });

      test('Given auth status is checking when current route is already loading then it returns null', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.checking,
            currentLocation: AppRoutes.loading,
          ),
          isNull,
        );
      });

      test('Given auth status is checking when current route is login then it redirects to loading with login as source', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.checking,
            currentLocation: AppRoutes.login,
          ),
          '${AppRoutes.loading}?from=%2Flogin',
        );
      });

      test(
        'Given auth status is checking when a from location is provided then it preserves that destination in the loading redirect',
        () {
          expect(
            authRedirect(
              authStatus: AuthStatus.checking,
              currentLocation: AppRoutes.login,
              fromLocation: AppRoutes.userAccounts,
            ),
            '${AppRoutes.loading}?from=%2Fuser-accounts',
          );
        },
      );
    });

    group('when AuthStatus is authenticating', () {
      test('Given auth status is authenticating when current route is not loading then it redirects to loading', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.authenticating,
            currentLocation: AppRoutes.home,
          ),
          '${AppRoutes.loading}?from=%2F',
        );
      });

      test('Given auth status is authenticating when current route is already loading then it returns null', () {
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
      test('Given auth status is unauthenticated when current route is the public home page then it returns null', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.unauthenticated,
            currentLocation: AppRoutes.home,
          ),
          isNull,
        );
      });

      test('Given auth status is unauthenticated when current route is the public reports page then it returns null', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.unauthenticated,
            currentLocation: AppRoutes.reports,
          ),
          isNull,
        );
      });

      test('Given auth status is unauthenticated when current route is protected then it redirects to login', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.unauthenticated,
            currentLocation: AppRoutes.surveys,
          ),
          '${AppRoutes.login}?from=%2Fsurveys',
        );
      });

      test(
        'Given auth status is unauthenticated when current route is loading and a destination exists then it redirects to login with that destination',
        () {
          expect(
            authRedirect(
              authStatus: AuthStatus.unauthenticated,
              currentLocation: AppRoutes.loading,
              fromLocation: AppRoutes.userAccounts,
            ),
            '${AppRoutes.login}?from=%2Fuser-accounts',
          );
        },
      );

      test('Given auth status is unauthenticated when current route is already login then it returns null', () {
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
      test('Given auth status is failure when current route is public then it returns null', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.failure,
            currentLocation: AppRoutes.home,
          ),
          isNull,
        );
      });

      test('Given auth status is failure when current route is already login then it returns null', () {
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
      test('Given auth status is authenticated when current route is home then it returns null', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.authenticated,
            currentLocation: AppRoutes.home,
          ),
          isNull,
        );
      });

      test('Given auth status is authenticated when current route is already allowed then it returns null', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.authenticated,
            currentLocation: AppRoutes.reports,
          ),
          isNull,
        );
      });

      test('Given auth status is authenticated when current route is login then it redirects to home', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.authenticated,
            currentLocation: AppRoutes.login,
          ),
          AppRoutes.home,
        );
      });

      test('Given auth status is authenticated when current route is loading without a destination then it redirects to home', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.authenticated,
            currentLocation: AppRoutes.loading,
          ),
          AppRoutes.home,
        );
      });

      test(
        'Given auth status is authenticated when current route is loading with a destination then it returns that destination',
        () {
          expect(
            authRedirect(
              authStatus: AuthStatus.authenticated,
              currentLocation: AppRoutes.loading,
              fromLocation: AppRoutes.userAccounts,
            ),
            AppRoutes.userAccounts,
          );
        },
      );
    });

    group('unknown route fallback', () {
      test('Given an unknown URL when unauthenticated then it redirects to home', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.unauthenticated,
            currentLocation: '/does-not-exist',
          ),
          AppRoutes.home,
        );
      });

      test('Given an unknown URL when authenticated then it redirects to home', () {
        expect(
          authRedirect(
            authStatus: AuthStatus.authenticated,
            currentLocation: '/does-not-exist',
          ),
          AppRoutes.home,
        );
      });
    });
  });
}
