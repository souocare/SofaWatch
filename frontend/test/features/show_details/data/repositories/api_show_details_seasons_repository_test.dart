import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/show_details/data/repositories/api_show_details_seasons_repository.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_episode.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_local_season.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_season_progress.dart';

void main() {
  group('ApiShowDetailsSeasonsRepository', () {
    test('imports the Show and resolves local Seasons', () async {
      final Dio dio = Dio();

      int requestIndex = 0;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                requestIndex++;

                if (requestIndex == 1) {
                  expect(options.method, 'POST');

                  expect(options.path, '/shows/import/tmdb/95396');

                  handler.resolve(
                    Response<Map<String, dynamic>>(
                      requestOptions: options,
                      statusCode: 200,
                      data: <String, dynamic>{
                        'id': 'show-uuid',
                        'tmdb_id': 95396,
                        'title': 'Severance',
                      },
                    ),
                  );

                  return;
                }

                expect(requestIndex, 2);

                expect(options.method, 'GET');

                expect(options.path, '/shows/show-uuid/seasons');

                handler.resolve(
                  Response<List<dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <Map<String, dynamic>>[
                      <String, dynamic>{
                        'id': 'season-1-uuid',
                        'tmdb_id': 134792,
                        'season_number': 1,
                        'title': 'Season 1',
                      },
                      <String, dynamic>{
                        'id': 'season-2-uuid',
                        'tmdb_id': 368201,
                        'season_number': 2,
                        'title': 'Season 2',
                      },
                    ],
                  ),
                );
              },
        ),
      );

      final ApiShowDetailsSeasonsRepository repository =
          ApiShowDetailsSeasonsRepository(
            ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
          );

      final List<ShowDetailsLocalSeason> seasons = await repository
          .resolveLocalSeasons(showTmdbId: 95396);

      expect(requestIndex, 2);

      expect(seasons, <ShowDetailsLocalSeason>[
        const ShowDetailsLocalSeason(
          id: 'season-1-uuid',
          tmdbId: 134792,
          seasonNumber: 1,
        ),
        const ShowDetailsLocalSeason(
          id: 'season-2-uuid',
          tmdbId: 368201,
          seasonNumber: 2,
        ),
      ]);
    });

    test('maps invalid imported Show response to invalidData', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                expect(options.path, '/shows/import/tmdb/95396');

                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, dynamic>{'tmdb_id': 95396},
                  ),
                );
              },
        ),
      );

      final ApiShowDetailsSeasonsRepository repository =
          ApiShowDetailsSeasonsRepository(
            ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
          );

      expect(
        repository.resolveLocalSeasons(showTmdbId: 95396),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('maps invalid local Seasons response to invalidData', () async {
      final Dio dio = Dio();

      int requestIndex = 0;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                requestIndex++;

                if (requestIndex == 1) {
                  expect(options.path, '/shows/import/tmdb/95396');

                  handler.resolve(
                    Response<Map<String, dynamic>>(
                      requestOptions: options,
                      statusCode: 200,
                      data: <String, dynamic>{
                        'id': 'show-uuid',
                        'tmdb_id': 95396,
                      },
                    ),
                  );

                  return;
                }

                expect(options.path, '/shows/show-uuid/seasons');

                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, dynamic>{'invalid': true},
                  ),
                );
              },
        ),
      );

      final ApiShowDetailsSeasonsRepository repository =
          ApiShowDetailsSeasonsRepository(
            ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
          );

      expect(
        repository.resolveLocalSeasons(showTmdbId: 95396),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('maps malformed local Season data to invalidData', () async {
      final Dio dio = Dio();

      int requestIndex = 0;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                requestIndex++;

                if (requestIndex == 1) {
                  handler.resolve(
                    Response<Map<String, dynamic>>(
                      requestOptions: options,
                      statusCode: 200,
                      data: <String, dynamic>{
                        'id': 'show-uuid',
                        'tmdb_id': 95396,
                      },
                    ),
                  );

                  return;
                }

                handler.resolve(
                  Response<List<dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <Map<String, dynamic>>[
                      <String, dynamic>{
                        'id': '',
                        'tmdb_id': 134792,
                        'season_number': 1,
                      },
                    ],
                  ),
                );
              },
        ),
      );

      final ApiShowDetailsSeasonsRepository repository =
          ApiShowDetailsSeasonsRepository(
            ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
          );

      expect(
        repository.resolveLocalSeasons(showTmdbId: 95396),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('loads and maps Season Episodes', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                expect(options.method, 'GET');

                expect(options.path, '/seasons/season-1-uuid/episodes');

                handler.resolve(
                  Response<List<dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <Map<String, dynamic>>[
                      <String, dynamic>{
                        'id': 'episode-1-uuid',
                        'tmdb_id': 1947647,
                        'episode_number': 1,
                        'title': 'Good News About Hell',
                        'overview': 'Episode overview.',
                        'air_date': '2022-02-18',
                        'runtime': 57,
                        'vote_average': 8.1,
                        'vote_count': 42,
                        'still_url': 'https://example.com/episode-1.jpg',
                      },
                      <String, dynamic>{
                        'id': 'episode-2-uuid',
                        'tmdb_id': 1947648,
                        'episode_number': 2,
                        'title': 'Half Loop',
                        'overview': null,
                        'air_date': null,
                        'runtime': null,
                        'vote_average': 8.2,
                        'vote_count': 38,
                        'still_url': null,
                      },
                    ],
                  ),
                );
              },
        ),
      );

      final ApiShowDetailsSeasonsRepository repository =
          ApiShowDetailsSeasonsRepository(
            ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
          );

      final List<ShowDetailsEpisode> episodes = await repository.getEpisodes(
        seasonId: 'season-1-uuid',
      );

      expect(episodes, hasLength(2));

      final ShowDetailsEpisode first = episodes.first;

      expect(first.id, 'episode-1-uuid');

      expect(first.tmdbId, 1947647);

      expect(first.episodeNumber, 1);

      expect(first.title, 'Good News About Hell');

      expect(first.overview, 'Episode overview.');

      expect(first.airDate, DateTime(2022, 2, 18));

      expect(first.runtime, 57);

      expect(first.voteAverage, 8.1);

      expect(first.voteCount, 42);

      expect(first.stillUrl, 'https://example.com/episode-1.jpg');

      final ShowDetailsEpisode second = episodes[1];

      expect(second.id, 'episode-2-uuid');

      expect(second.episodeNumber, 2);

      expect(second.title, 'Half Loop');

      expect(second.overview, isNull);

      expect(second.airDate, isNull);

      expect(second.runtime, isNull);

      expect(second.stillUrl, isNull);
    });

    test('supports a Season without Episodes', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                expect(options.path, '/seasons/season-1-uuid/episodes');

                handler.resolve(
                  Response<List<dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <dynamic>[],
                  ),
                );
              },
        ),
      );

      final ApiShowDetailsSeasonsRepository repository =
          ApiShowDetailsSeasonsRepository(
            ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
          );

      final List<ShowDetailsEpisode> episodes = await repository.getEpisodes(
        seasonId: 'season-1-uuid',
      );

      expect(episodes, isEmpty);
    });

    test('maps malformed Episode data to invalidData', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.resolve(
                  Response<List<dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <Map<String, dynamic>>[
                      <String, dynamic>{
                        'id': 'episode-1-uuid',
                        'tmdb_id': 1947647,
                        'episode_number': 1,
                        // title intentionally missing.
                        'vote_average': 8.1,
                        'vote_count': 42,
                      },
                    ],
                  ),
                );
              },
        ),
      );

      final ApiShowDetailsSeasonsRepository repository =
          ApiShowDetailsSeasonsRepository(
            ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
          );

      expect(
        repository.getEpisodes(seasonId: 'season-1-uuid'),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('maps invalid Episode date to invalidData', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.resolve(
                  Response<List<dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <Map<String, dynamic>>[
                      <String, dynamic>{
                        'id': 'episode-1-uuid',
                        'tmdb_id': 1947647,
                        'episode_number': 1,
                        'title': 'Good News About Hell',
                        'overview': null,
                        'air_date': 'invalid-date',
                        'runtime': 57,
                        'vote_average': 8.1,
                        'vote_count': 42,
                        'still_url': null,
                      },
                    ],
                  ),
                );
              },
        ),
      );

      final ApiShowDetailsSeasonsRepository repository =
          ApiShowDetailsSeasonsRepository(
            ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
          );

      expect(
        repository.getEpisodes(seasonId: 'season-1-uuid'),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('loads and maps Season progress', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                expect(options.method, 'GET');

                expect(options.path, '/seasons/season-1-uuid/progress');

                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, dynamic>{
                      'season_id': 'season-1-uuid',
                      'watched_episodes': 6,
                      'total_episodes': 9,
                      'progress_percentage': 66.67,
                      'aired_episodes': 8,
                      'watched_aired_episodes': 6,
                      'aired_progress_percentage': 75.0,
                      'caught_up': false,
                    },
                  ),
                );
              },
        ),
      );

      final ApiShowDetailsSeasonsRepository repository =
          ApiShowDetailsSeasonsRepository(
            ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
          );

      final ShowDetailsSeasonProgress progress = await repository
          .getSeasonProgress(seasonId: 'season-1-uuid');

      expect(progress.seasonId, 'season-1-uuid');

      expect(progress.watchedEpisodes, 6);

      expect(progress.totalEpisodes, 9);

      expect(progress.progressPercentage, 66.67);

      expect(progress.airedEpisodes, 8);

      expect(progress.watchedAiredEpisodes, 6);

      expect(progress.airedProgressPercentage, 75.0);

      expect(progress.airedProgressValue, 0.75);

      expect(progress.caughtUp, isFalse);
    });

    test('maps a caught up Season progress', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, dynamic>{
                      'season_id': 'season-2-uuid',
                      'watched_episodes': 8,
                      'total_episodes': 10,
                      'progress_percentage': 80.0,
                      'aired_episodes': 8,
                      'watched_aired_episodes': 8,
                      'aired_progress_percentage': 100.0,
                      'caught_up': true,
                    },
                  ),
                );
              },
        ),
      );

      final ApiShowDetailsSeasonsRepository repository =
          ApiShowDetailsSeasonsRepository(
            ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
          );

      final ShowDetailsSeasonProgress progress = await repository
          .getSeasonProgress(seasonId: 'season-2-uuid');

      expect(progress.watchedEpisodes, 8);

      expect(progress.totalEpisodes, 10);

      expect(progress.airedEpisodes, 8);

      expect(progress.watchedAiredEpisodes, 8);

      expect(progress.airedProgressPercentage, 100);

      expect(progress.airedProgressValue, 1);

      expect(progress.caughtUp, isTrue);
    });

    test('maps progress for a Season with no aired Episodes', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, dynamic>{
                      'season_id': 'season-3-uuid',
                      'watched_episodes': 0,
                      'total_episodes': 10,
                      'progress_percentage': 0.0,
                      'aired_episodes': 0,
                      'watched_aired_episodes': 0,
                      'aired_progress_percentage': 0.0,
                      'caught_up': true,
                    },
                  ),
                );
              },
        ),
      );

      final ApiShowDetailsSeasonsRepository repository =
          ApiShowDetailsSeasonsRepository(
            ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
          );

      final ShowDetailsSeasonProgress progress = await repository
          .getSeasonProgress(seasonId: 'season-3-uuid');

      expect(progress.hasAiredEpisodes, isFalse);

      expect(progress.airedProgressValue, 0);

      expect(progress.watchedAiredEpisodes, 0);

      expect(progress.airedEpisodes, 0);
    });

    test('maps invalid Season progress response to invalidData', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, dynamic>{
                      'season_id': 'season-1-uuid',
                      'watched_episodes': 6,
                      'total_episodes': 9,

                      // Invalid according to the backend contract.
                      'progress_percentage': 150.0,

                      'aired_episodes': 8,
                      'watched_aired_episodes': 6,
                      'aired_progress_percentage': 75.0,
                      'caught_up': false,
                    },
                  ),
                );
              },
        ),
      );

      final ApiShowDetailsSeasonsRepository repository =
          ApiShowDetailsSeasonsRepository(
            ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
          );

      expect(
        repository.getSeasonProgress(seasonId: 'season-1-uuid'),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });
  });
}
