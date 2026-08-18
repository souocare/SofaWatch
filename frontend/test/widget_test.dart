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

    expect(find.byKey(const ValueKey<String>('home-page')), findsOneWidget);

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

    expect(find.byKey(const ValueKey<String>('movies-page')), findsOneWidget);

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

    expect(find.byKey(const ValueKey<String>('home-page')), findsOneWidget);

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
      find.byKey(const ValueKey<String>('home-page')),
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

    expect(find.byKey(const ValueKey<String>('home-page')), findsOneWidget);
  });

  testWidgets('opens Episode Details from a Home Premiering Today card', (
    WidgetTester tester,
  ) async {
    final Dio dio = Dio();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          final String path = options.path;

          if (path.endsWith('/library/shows/watch-next')) {
            handler.resolve(
              Response<List<dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: const <dynamic>[],
              ),
            );
            return;
          }

          if (path.endsWith('/library/shows/upcoming')) {
            final String? fromDate =
                options.queryParameters['from_date'] as String?;

            final String? toDate =
                options.queryParameters['to_date'] as String?;

            final bool isTodayRequest =
                fromDate != null && toDate != null && fromDate == toDate;

            handler.resolve(
              Response<List<dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: isTodayRequest
                    ? <dynamic>[
                        <String, dynamic>{
                          'library_entry_id': 'library-entry-1',
                          'library_status': 'watching',
                          'show': <String, dynamic>{
                            'id': 'show-1',
                            'tmdb_id': 95396,
                            'title': 'Severance',
                            'poster_url': null,
                            'backdrop_url': null,
                          },
                          'episode': <String, dynamic>{
                            'id': 'episode-home-1',
                            'tmdb_id': 1000,
                            'season_number': 2,
                            'episode_number': 1,
                            'title': 'Hello, Ms. Cobel',
                            'air_date': fromDate,
                            'runtime': 52,
                            'still_url': null,
                            'is_watched': false,
                          },
                        },
                      ]
                    : const <dynamic>[],
              ),
            );
            return;
          }

          if (path.endsWith('/library/shows/missed-recently')) {
            handler.resolve(
              Response<List<dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: const <dynamic>[],
              ),
            );
            return;
          }

          if (path.endsWith('/library/shows/watch-history')) {
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: const <String, dynamic>{
                  'items': <dynamic>[],
                  'next_cursor': null,
                  'has_more': false,
                },
              ),
            );
            return;
          }

          if (path.endsWith('/statistics/weekly')) {
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: const <String, dynamic>{
                  'week_start': '2026-08-17',
                  'week_end': '2026-08-23',
                  'episodes_watched': 0,
                  'movies_watched': 0,
                  'watch_time_minutes': 0,
                },
              ),
            );
            return;
          }

          if (path.contains('/episodes/episode-home-1')) {
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 404,
                data: const <String, dynamic>{
                  'error': <String, dynamic>{
                    'code': 'episode_not_found',
                    'message': 'Episode not found.',
                  },
                },
              ),
            );
            return;
          }

          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 500,
              data: const <String, dynamic>{
                'error': <String, dynamic>{
                  'code': 'test_unhandled_request',
                  'message': 'Unhandled test request.',
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

    final Finder card = find.byKey(
      const ValueKey<String>('home-premiering-today-episode-home-1'),
    );

    expect(card, findsOneWidget);

    await tester.tap(card);

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('episode-details-page')),
      findsOneWidget,
    );
  });

  testWidgets('opens episode details', (WidgetTester tester) async {
    await tester.pumpSofaWatchApp();

    final BuildContext context = tester.element(
      find.byKey(const ValueKey<String>('home-page')),
    );

    context.pushNamed(
      AppRoute.episodeDetails.name,
      pathParameters: <String, String>{'episodeId': 'episode-456'},
    );

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('episode-details-page')),
      findsOneWidget,
    );
  });
}
