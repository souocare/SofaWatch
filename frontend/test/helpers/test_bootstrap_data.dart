import 'package:dio/dio.dart';

import 'package:sofawatch/app/app_bootstrap_data.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/server/models/server_configuration.dart';

import '../fakes/fake_search_repository.dart';
import '../fakes/fake_server_configuration_repository.dart';
import '../fakes/fake_server_connection_tester.dart';
import '../fixtures/server_configuration_fixture.dart';

AppBootstrapData createTestBootstrapData({
  ServerConfiguration? serverConfiguration,
  bool hasConfiguredServer = true,
  FakeServerConfigurationRepository? serverConfigurationRepository,
  FakeServerConnectionTester? serverConnectionTester,
  FakeSearchRepository? searchRepository,
  ApiClient? apiClient,
}) {
  final ServerConfiguration? resolvedConfiguration = hasConfiguredServer
      ? serverConfiguration ?? createServerConfigurationFixture()
      : null;

  final FakeServerConfigurationRepository resolvedRepository =
      serverConfigurationRepository ??
      FakeServerConfigurationRepository(
        initialConfiguration: resolvedConfiguration,
      );

  final FakeServerConnectionTester resolvedConnectionTester =
      serverConnectionTester ?? FakeServerConnectionTester();

  final FakeSearchRepository resolvedSearchRepository =
      searchRepository ?? FakeSearchRepository();

  final ApiClient resolvedApiClient =
      apiClient ??
      _createDefaultTestApiClient(baseUrl: resolvedConfiguration?.serverUrl);

  return AppBootstrapData(
    serverConfigurationRepository: resolvedRepository,
    apiClient: resolvedApiClient,
    searchRepository: resolvedSearchRepository,
    serverConnectionTester: resolvedConnectionTester,
    initialServerConfiguration: resolvedConfiguration,
  );
}

ApiClient _createDefaultTestApiClient({required Uri? baseUrl}) {
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
          handler.resolve(
            Response<List<dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: const <dynamic>[],
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

        if (path.endsWith('/statistics/summary')) {
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: const <String, dynamic>{
                'shows_watched': 0,
                'episodes': <String, dynamic>{
                  'watch_count': 0,
                  'unique_count': 0,
                  'rewatch_count': 0,
                  'watch_time_minutes': 0,
                  'rewatch_time_minutes': 0,
                },
                'movies': <String, dynamic>{
                  'watch_count': 0,
                  'unique_count': 0,
                  'rewatch_count': 0,
                  'watch_time_minutes': 0,
                  'rewatch_time_minutes': 0,
                },
                'watch_time_minutes': 0,
                'rewatch_time_minutes': 0,
              },
            ),
          );
          return;
        }

        if (path.endsWith('/statistics/activity')) {
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: const <String, dynamic>{
                'start_date': '2026-08-12',
                'end_date': '2026-08-18',
                'days': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'day': '2026-08-12',
                    'episodes_watched': 0,
                    'movies_watched': 0,
                    'episode_watch_time_minutes': 0,
                    'movie_watch_time_minutes': 0,
                    'watch_time_minutes': 0,
                  },
                  <String, dynamic>{
                    'day': '2026-08-13',
                    'episodes_watched': 0,
                    'movies_watched': 0,
                    'episode_watch_time_minutes': 0,
                    'movie_watch_time_minutes': 0,
                    'watch_time_minutes': 0,
                  },
                  <String, dynamic>{
                    'day': '2026-08-14',
                    'episodes_watched': 0,
                    'movies_watched': 0,
                    'episode_watch_time_minutes': 0,
                    'movie_watch_time_minutes': 0,
                    'watch_time_minutes': 0,
                  },
                  <String, dynamic>{
                    'day': '2026-08-15',
                    'episodes_watched': 0,
                    'movies_watched': 0,
                    'episode_watch_time_minutes': 0,
                    'movie_watch_time_minutes': 0,
                    'watch_time_minutes': 0,
                  },
                  <String, dynamic>{
                    'day': '2026-08-16',
                    'episodes_watched': 0,
                    'movies_watched': 0,
                    'episode_watch_time_minutes': 0,
                    'movie_watch_time_minutes': 0,
                    'watch_time_minutes': 0,
                  },
                  <String, dynamic>{
                    'day': '2026-08-17',
                    'episodes_watched': 0,
                    'movies_watched': 0,
                    'episode_watch_time_minutes': 0,
                    'movie_watch_time_minutes': 0,
                    'watch_time_minutes': 0,
                  },
                  <String, dynamic>{
                    'day': '2026-08-18',
                    'episodes_watched': 0,
                    'movies_watched': 0,
                    'episode_watch_time_minutes': 0,
                    'movie_watch_time_minutes': 0,
                    'watch_time_minutes': 0,
                  },
                ],
              },
            ),
          );
          return;
        }

        /*
         * Preserve the previous test behaviour for endpoints that individual
         * tests are not explicitly interested in.
         *
         * Importantly, never allow the default widget-test ApiClient to make
         * a real network request.
         */
        handler.resolve(
          Response<Map<String, dynamic>>(
            requestOptions: options,
            statusCode: 500,
            data: const <String, dynamic>{
              'error': <String, dynamic>{
                'code': 'test_unhandled_request',
                'message': 'Unhandled request in the default test ApiClient.',
              },
            },
          ),
        );
      },
    ),
  );

  return ApiClient(baseUrl: baseUrl, dio: dio);
}
