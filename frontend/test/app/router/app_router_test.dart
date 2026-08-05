import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/app_dependencies.dart';
import 'package:sofawatch/app/router/app_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/app/theme/app_theme.dart';
import 'package:sofawatch/core/api/api_client.dart';

import '../../fakes/fake_search_repository.dart';
import '../../fakes/fake_server_configuration_repository.dart';
import '../../fakes/fake_server_connection_tester.dart';

void main() {
  late GoRouter router;

  setUp(() {
    router = createAppRouter(
      apiClient: ApiClient(baseUrl: Uri.parse('https://server.example.com')),
    );
  });

  tearDown(() {
    router.dispose();
  });

  Widget buildTestApp() {
    return AppDependencies(
      serverConfigurationRepository: FakeServerConfigurationRepository(),
      apiClient: ApiClient(baseUrl: Uri.parse('https://server.example.com')),
      searchRepository: FakeSearchRepository(),
      serverConnectionTester: FakeServerConnectionTester(),
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
      ),
    );
  }

  testWidgets('redirects the root route to Home', (WidgetTester tester) async {
    router.go('/');

    await tester.pumpWidget(buildTestApp());

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('home-page-title')),
      findsOneWidget,
    );
  });

  testWidgets('opens show details from a deep-link location', (
    WidgetTester tester,
  ) async {
    router.go('/shows/show-123');

    await tester.pumpWidget(buildTestApp());

    await tester.pumpAndSettle();

    expect(find.text('Show Details'), findsWidgets);

    expect(find.text('show-123'), findsOneWidget);
  });

  testWidgets('opens movie details from a deep-link location', (
    WidgetTester tester,
  ) async {
    router.goNamed(
      AppRoute.movieDetails.name,
      pathParameters: <String, String>{'movieId': 'movie-456'},
    );

    await tester.pumpWidget(buildTestApp());

    await tester.pumpAndSettle();

    expect(find.text('Movie Details'), findsWidgets);

    expect(find.text('movie-456'), findsOneWidget);
  });

  testWidgets('opens episode details from a deep-link location', (
    WidgetTester tester,
  ) async {
    router.go('/episodes/episode-789');

    await tester.pumpWidget(buildTestApp());

    await tester.pumpAndSettle();

    expect(find.text('Episode Details'), findsWidgets);

    expect(find.text('episode-789'), findsOneWidget);
  });

  testWidgets('shows a not-found page for an unknown route', (
    WidgetTester tester,
  ) async {
    router.go('/unknown-route');

    await tester.pumpWidget(buildTestApp());

    await tester.pumpAndSettle();

    expect(find.text('Page not found'), findsOneWidget);

    expect(
      find.byKey(const ValueKey<String>('not-found-location')),
      findsOneWidget,
    );

    expect(find.text('/unknown-route'), findsOneWidget);
  });

  testWidgets('returns Home from the not-found page', (
    WidgetTester tester,
  ) async {
    router.go('/unknown-route');

    await tester.pumpWidget(buildTestApp());

    await tester.pumpAndSettle();

    await tester.tap(find.text('Go to Home'));

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('home-page-title')),
      findsOneWidget,
    );
  });
  // testWidgets('opens the global Search route', (WidgetTester tester) async {
  //   router.goNamed(AppRoute.search.name);

  //   await tester.pumpWidget(buildTestApp());

  //   await tester.pumpAndSettle();

  //   expect(find.byKey(const ValueKey<String>('search-page')), findsOneWidget);

  //   expect(
  //     find.byKey(const ValueKey<String>('search-page-title')),
  //     findsOneWidget,
  //   );

  //   expect(find.text('Search movies and TV shows.'), findsOneWidget);
  // });

  // testWidgets('closes Search and returns to the previous route', (
  //   WidgetTester tester,
  // ) async {
  //   router.go('/home');

  //   await tester.pumpWidget(buildTestApp());

  //   await tester.pumpAndSettle();

  //   expect(
  //     find.byKey(const ValueKey<String>('home-page-title')),
  //     findsOneWidget,
  //   );

  //   router.pushNamed(AppRoute.search.name);

  //   await tester.pumpAndSettle();

  //   expect(find.byKey(const ValueKey<String>('search-page')), findsOneWidget);

  //   await tester.tap(find.byKey(const ValueKey<String>('search-close-button')));

  //   await tester.pumpAndSettle();

  //   expect(find.byKey(const ValueKey<String>('search-page')), findsNothing);

  //   expect(
  //     find.byKey(const ValueKey<String>('home-page-title')),
  //     findsOneWidget,
  //   );
  // });
}
