import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/app_dependencies.dart';
import 'package:sofawatch/app/router/app_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/app/theme/app_theme.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/features/search/application/bloc/search_bloc.dart';

import '../../fakes/fake_search_repository.dart';
import '../../fakes/fake_server_configuration_repository.dart';
import '../../fakes/fake_server_connection_tester.dart';

void main() {
  late GoRouter router;
  late ApiClient apiClient;

  setUp(() {
    final Dio dio = Dio();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 500,
              data: <String, dynamic>{
                'error': <String, dynamic>{
                  'code': 'test_error',
                  'message': 'Test failure.',
                },
              },
            ),
          );
        },
      ),
    );

    apiClient = ApiClient(
      baseUrl: Uri.parse('https://server.example.com'),
      dio: dio,
    );

    router = createAppRouter(apiClient: apiClient);
  });

  tearDown(() {
    router.dispose();
  });

  Widget buildTestApp() {
    return AppDependencies(
      serverConfigurationRepository: FakeServerConfigurationRepository(),
      apiClient: apiClient,
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

    expect(find.byKey(const ValueKey<String>('home-page')), findsOneWidget);
  });

  testWidgets('opens show details from a deep-link location', (
    WidgetTester tester,
  ) async {
    router.go('/shows/95396');

    await tester.pumpWidget(buildTestApp());

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('show-details-failure')),
      findsOneWidget,
    );
  });

  testWidgets('opens movie details from a deep-link location', (
    WidgetTester tester,
  ) async {
    router.goNamed(
      AppRoute.movieDetails.name,
      pathParameters: <String, String>{'movieId': '438631'},
    );

    await tester.pumpWidget(buildTestApp());

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('movie-details-failure')),
      findsOneWidget,
    );
  });

  testWidgets('opens episode details from a deep-link location', (
    WidgetTester tester,
  ) async {
    router.go('/episodes/episode-789');

    await tester.pumpWidget(buildTestApp());

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('episode-details-page')),
      findsOneWidget,
    );
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

    expect(find.byKey(const ValueKey<String>('home-page')), findsOneWidget);
  });

  testWidgets('opens the global Search route on mobile', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    router.goNamed(AppRoute.search.name);

    await tester.pumpWidget(buildTestApp());

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('search-mobile-view')),
      findsOneWidget,
    );

    expect(
      find.byKey(const ValueKey<String>('search-mobile-title')),
      findsOneWidget,
    );
  });

  testWidgets('opens the global Search route as a desktop modal', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 844));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    router.go('/home');

    await tester.pumpWidget(buildTestApp());

    await tester.pumpAndSettle();

    router.pushNamed(AppRoute.search.name);

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('search-desktop-modal')),
      findsOneWidget,
    );

    expect(
      find.byKey(const ValueKey<String>('search-text-field')),
      findsOneWidget,
    );
  });

  testWidgets('closes the desktop Search modal and returns to Home', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 844));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    router.go('/home');

    await tester.pumpWidget(buildTestApp());

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('home-page')), findsOneWidget);

    router.pushNamed(AppRoute.search.name);

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('search-desktop-modal')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('search-desktop-close-button')),
    );

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('search-desktop-modal')),
      findsNothing,
    );

    expect(find.byKey(const ValueKey<String>('home-page')), findsOneWidget);
  });

  testWidgets('closes the SearchBloc when the Search route is popped', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));

    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    router.go('/home');

    await tester.pumpWidget(buildTestApp());

    await tester.pumpAndSettle();

    router.pushNamed(AppRoute.search.name);

    await tester.pumpAndSettle();

    final BuildContext searchContext = tester.element(
      find.byKey(const ValueKey<String>('search-mobile-view')),
    );

    final SearchBloc searchBloc = BlocProvider.of<SearchBloc>(searchContext);

    expect(searchBloc.isClosed, isFalse);

    router.pop();

    await tester.pumpAndSettle();

    expect(searchBloc.isClosed, isTrue);

    expect(find.byKey(const ValueKey<String>('home-page')), findsOneWidget);
  });
}
