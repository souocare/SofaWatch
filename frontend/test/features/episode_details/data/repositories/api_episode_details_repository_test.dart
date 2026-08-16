import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/episode_details/data/repositories/api_episode_details_repository.dart';
import 'package:sofawatch/features/episode_details/domain/models/episode_details.dart';

void main() {
  group('ApiEpisodeDetailsRepository', () {
    test('loads Episode Details by local Episode ID', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                expect(options.method, 'GET');
                expect(options.path, '/episodes/episode-uuid/details');

                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, dynamic>{
                      'episode': <String, dynamic>{
                        'id': 'episode-uuid',
                        'tmdb_id': 1947648,
                        'episode_number': 4,
                        'title': "Woe's Hollow",
                        'overview': 'An episode overview.',
                        'air_date': '2025-02-07',
                        'runtime': 52,
                        'vote_average': 8.5,
                        'vote_count': 100,
                        'still_url':
                            '/api/v1/images/episodes/episode-uuid/still',
                      },
                      'season': <String, dynamic>{
                        'id': 'season-uuid',
                        'season_number': 2,
                        'title': 'Season 2',
                      },
                      'show': <String, dynamic>{
                        'id': 'show-uuid',
                        'tmdb_id': 95396,
                        'title': 'Severance',
                        'original_title': 'Severance',
                        'first_air_date': '2022-02-18',
                        'poster_url': '/api/v1/images/shows/show-uuid/poster',
                        'backdrop_url':
                            '/api/v1/images/shows/show-uuid/backdrop',
                        'status': 'Returning Series',
                        'vote_average': 8.4,
                      },
                      'progress': <String, dynamic>{
                        'is_watched': true,
                        'watched_at': '2026-08-14T21:30:00Z',
                        'watch_count': 2,
                        'last_watched_at': '2026-08-14T21:30:00Z',
                      },
                    },
                  ),
                );
              },
        ),
      );

      final ApiEpisodeDetailsRepository repository =
          ApiEpisodeDetailsRepository(
            ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
          );

      final EpisodeDetails result = await repository.getById('episode-uuid');

      expect(result.episode.id, 'episode-uuid');
      expect(result.episode.tmdbId, 1947648);
      expect(result.episode.episodeNumber, 4);
      expect(result.episode.title, "Woe's Hollow");

      expect(result.season.id, 'season-uuid');
      expect(result.season.seasonNumber, 2);
      expect(result.season.title, 'Season 2');

      expect(result.show.id, 'show-uuid');
      expect(result.show.tmdbId, 95396);
      expect(result.show.title, 'Severance');

      expect(result.progress.isWatched, isTrue);
      expect(result.progress.watchCount, 2);
    });

    test('maps malformed Episode Details response to invalidData', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                expect(options.method, 'GET');
                expect(options.path, '/episodes/episode-uuid/details');

                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, dynamic>{'episode': 'invalid'},
                  ),
                );
              },
        ),
      );

      final ApiEpisodeDetailsRepository repository =
          ApiEpisodeDetailsRepository(
            ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
          );

      expect(
        repository.getById('episode-uuid'),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('maps missing response body to invalidData', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: null,
                  ),
                );
              },
        ),
      );

      final ApiEpisodeDetailsRepository repository =
          ApiEpisodeDetailsRepository(
            ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
          );

      expect(
        repository.getById('episode-uuid'),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('preserves AppException returned by ApiClient', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    type: DioExceptionType.connectionError,
                    error: StateError('connection failed'),
                  ),
                );
              },
        ),
      );

      final ApiEpisodeDetailsRepository repository =
          ApiEpisodeDetailsRepository(
            ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
          );

      expect(
        repository.getById('episode-uuid'),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.connection,
          ),
        ),
      );
    });
  });
}
