import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/features/home/presentation/widgets/home_header.dart';

void main() {
  group('HomeHeader', () {
    testWidgets('shows Good morning before midday', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(now: () => DateTime(2026, 8, 17, 9)),
      );

      await tester.pumpAndSettle();

      expect(find.text('Good morning'), findsOneWidget);
    });

    testWidgets('shows Good afternoon during the afternoon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(now: () => DateTime(2026, 8, 17, 14)),
      );

      await tester.pumpAndSettle();

      expect(find.text('Good afternoon'), findsOneWidget);
    });

    testWidgets('shows Good evening during the evening', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(now: () => DateTime(2026, 8, 17, 20)),
      );

      await tester.pumpAndSettle();

      expect(find.text('Good evening'), findsOneWidget);
    });

    testWidgets('shows the formatted current date', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(now: () => DateTime(2026, 8, 17, 9)),
      );

      await tester.pumpAndSettle();

      expect(find.text('Monday, August 17'), findsOneWidget);
    });

    testWidgets('opens the user menu from the avatar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('home-user-avatar')));

      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);

      expect(find.text('Settings'), findsOneWidget);

      expect(find.text('Log out'), findsOneWidget);
    });

    testWidgets('opens Profile from the user menu', (
      WidgetTester tester,
    ) async {
      final GoRouter router = GoRouter(
        initialLocation: '/',
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (BuildContext context, GoRouterState state) {
              return Scaffold(
                body: HomeHeader(now: () => DateTime(2026, 8, 17, 9)),
              );
            },
          ),
          GoRoute(
            name: AppRoute.profile.name,
            path: '/profile',
            builder: (BuildContext context, GoRouterState state) {
              return const Scaffold(
                body: Text(
                  'Profile test page',
                  key: ValueKey<String>('profile-test-page'),
                ),
              );
            },
          ),
        ],
      );

      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('home-user-avatar')));

      await tester.pumpAndSettle();

      await tester.tap(find.text('Profile'));

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('profile-test-page')),
        findsOneWidget,
      );
    });

    testWidgets('shows temporary Settings feedback', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('home-user-avatar')));

      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));

      await tester.pumpAndSettle();

      expect(find.text('Settings are not available yet.'), findsOneWidget);
    });

    testWidgets('shows temporary Log out feedback', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildTestApp());

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('home-user-avatar')));

      await tester.pumpAndSettle();

      await tester.tap(find.text('Log out'));

      await tester.pumpAndSettle();

      expect(
        find.text(
          'Log out will be available when user accounts are implemented.',
        ),
        findsOneWidget,
      );
    });
  });
}

Widget _buildTestApp({DateTime Function()? now}) {
  final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return Scaffold(
            body: HomeHeader(now: now ?? () => DateTime(2026, 8, 17, 9)),
          );
        },
      ),
      GoRoute(
        name: AppRoute.profile.name,
        path: '/profile',
        builder: (BuildContext context, GoRouterState state) {
          return const Scaffold(body: Text('Profile'));
        },
      ),
    ],
  );

  return MaterialApp.router(routerConfig: router);
}
