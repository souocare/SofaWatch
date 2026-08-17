@TestOn('vm')
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/core/api/api_client.dart';

import 'helpers/test_app.dart';
import 'helpers/test_bootstrap_data.dart';

void main() {
  testWidgets('redirects the initial route to Home', (
    WidgetTester tester,
  ) async {
    await tester.pumpSofaWatchApp();

    expect(
      find.byKey(const ValueKey<String>('home-page-title')),
      findsOneWidget,
    );

    expect(
      find.byKey(const ValueKey<String>('mobile-bottom-navigation')),
      findsOneWidget,
    );
  });

  testWidgets('switches between the main tabs', (WidgetTester tester) async {
    await tester.pumpSofaWatchApp();

    await tester.tap(
      find.byKey(const ValueKey<String>('mobile-navigation-shows')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('shows-page-title')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('mobile-navigation-movies')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('movies-page-title')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('mobile-navigation-explore')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('explore-page-title')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('mobile-navigation-profile')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('profile-page-title')),
      findsOneWidget,
    );
  });

  testWidgets('returns to the previously selected branch', (
    WidgetTester tester,
  ) async {
    await tester.pumpSofaWatchApp();

    await tester.tap(
      find.byKey(const ValueKey<String>('mobile-navigation-shows')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('shows-page-title')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('mobile-navigation-home')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('home-page-title')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('mobile-navigation-shows')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('shows-page-title')),
      findsOneWidget,
    );
  });

  testWidgets('shows bottom navigation on mobile platforms', (
    WidgetTester tester,
  ) async {
    await tester.pumpSofaWatchApp();

    expect(
      find.byKey(const ValueKey<String>('mobile-bottom-navigation')),
      findsOneWidget,
    );

    expect(
      find.byKey(const ValueKey<String>('web-top-navigation')),
      findsNothing,
    );
  });

  testWidgets('opens and closes show details', (WidgetTester tester) async {
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

    final ApiClient apiClient = ApiClient(
      baseUrl: Uri.parse('https://server.example.com'),
      dio: dio,
    );

    await tester.pumpSofaWatchApp(
      bootstrapData: createTestBootstrapData(apiClient: apiClient),
    );

    final BuildContext context = tester.element(
      find.byKey(const ValueKey<String>('home-page-title')),
    );

    context.pushNamed(
      AppRoute.showDetails.name,
      pathParameters: <String, String>{'showId': '95396'},
    );

    await tester.pumpAndSettle();

    final Finder details = find.byKey(
      const ValueKey<String>('show-details-failure'),
    );

    expect(details, findsOneWidget);

    final BuildContext detailsContext = tester.element(details);

    GoRouter.of(detailsContext).pop();

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('show-details-failure')),
      findsNothing,
    );

    expect(
      find.byKey(const ValueKey<String>('home-page-title')),
      findsOneWidget,
    );
  });

  testWidgets('opens episode details', (WidgetTester tester) async {
    await tester.pumpSofaWatchApp();

    final BuildContext context = tester.element(
      find.byKey(const ValueKey<String>('home-page-title')),
    );

    context.pushNamed(
      AppRoute.episodeDetails.name,
      pathParameters: <String, String>{'episodeId': 'episode-456'},
    );

    await tester.pumpAndSettle();

    expect(find.text('Episode Details'), findsWidgets);

    expect(find.text('episode-456'), findsOneWidget);
  });
}
