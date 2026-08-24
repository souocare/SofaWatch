import 'package:dio/dio.dart';
import 'package:sofawatch/core/api/api_client.dart';

ApiClient createDetailsTestApiClient() {
  final Dio dio = Dio();

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
        final String path = options.path;

        if (path.endsWith('/auth/session')) {
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: const <String, dynamic>{
                'access_token': 'test-access-token',
                'token_type': 'bearer',
                'expires_in': 900,
              },
            ),
          );

          return;
        }

        final RegExp showDetailsPattern = RegExp(r'/shows/tmdb/(\d+)$');

        final RegExp showImportPattern = RegExp(r'/shows/import/tmdb/(\d+)$');

        final RegExp showSeasonsPattern = RegExp(
          r'/shows/show-local-(\d+)/seasons$',
        );

        final RegExp showProgressPattern = RegExp(
          r'/shows/show-local-(\d+)/seasons/progress$',
        );

        final RegExpMatch? showDetailsMatch = showDetailsPattern.firstMatch(
          path,
        );

        if (showDetailsMatch != null) {
          final int tmdbId = int.parse(showDetailsMatch.group(1)!);

          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{
                ..._showDetailsResponse,
                'tmdb_id': tmdbId,
                'title': tmdbId == 95396 ? 'Severance' : 'Show $tmdbId',
                'original_title': tmdbId == 95396
                    ? 'Severance'
                    : 'Show $tmdbId',
              },
            ),
          );

          return;
        }

        final RegExpMatch? showImportMatch = showImportPattern.firstMatch(path);

        if (showImportMatch != null) {
          final int tmdbId = int.parse(showImportMatch.group(1)!);

          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{
                'id': 'show-local-$tmdbId',
                'tmdb_id': tmdbId,
              },
            ),
          );

          return;
        }

        if (showSeasonsPattern.hasMatch(path)) {
          handler.resolve(
            Response<List<dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: const <dynamic>[],
            ),
          );

          return;
        }

        if (showProgressPattern.hasMatch(path)) {
          handler.resolve(
            Response<List<dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: const <dynamic>[],
            ),
          );

          return;
        }

        if (path.endsWith('/movies/tmdb/438631')) {
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: _movieDetailsResponse,
            ),
          );

          return;
        }

        if (path.endsWith('/movies/import/tmdb/438631')) {
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: const <String, dynamic>{
                'id': 'movie-local-uuid',
                'tmdb_id': 438631,
              },
            ),
          );

          return;
        }

        if (path.endsWith('/library/movies/movie-local-uuid')) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response<dynamic>(
                requestOptions: options,
                statusCode: 404,
                data: const <String, dynamic>{
                  'detail': <String, dynamic>{
                    'code': 'library_entry_not_found',
                    'message': 'Library entry not found.',
                  },
                },
              ),
              type: DioExceptionType.badResponse,
            ),
          );

          return;
        }

        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.unknown,
            error: StateError(
              'Unexpected API request in Details test: '
              '${options.method} $path',
            ),
          ),
        );
      },
    ),
  );

  return ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio);
}

const Map<String, dynamic> _showDetailsResponse = <String, dynamic>{
  'tmdb_id': 95396,
  'title': 'Severance',
  'original_title': 'Severance',
  'overview': 'A mysterious workplace thriller.',
  'tagline': 'We work for Lumon.',
  'first_air_date': '2022-02-17',
  'last_air_date': '2025-03-20',
  'poster_url': null,
  'backdrop_url': null,
  'homepage_url': null,
  'genres': <Map<String, dynamic>>[
    <String, dynamic>{'tmdb_id': 18, 'name': 'Drama'},
  ],
  'seasons': <Map<String, dynamic>>[],
  'networks': <Map<String, dynamic>>[],
  'original_language': 'en',
  'episode_run_times': <int>[50],
  'number_of_seasons': 2,
  'number_of_episodes': 19,
  'in_production': true,
  'status': 'Returning Series',
  'show_type': 'Scripted',
  'popularity': 100.0,
  'vote_average': 8.4,
  'vote_count': 3000,
};

const Map<String, dynamic> _movieDetailsResponse = <String, dynamic>{
  'tmdb_id': 438631,
  'title': 'Dune',
  'original_title': 'Dune',
  'overview': 'Paul Atreides travels to Arrakis.',
  'tagline': 'Beyond fear, destiny awaits.',
  'release_date': '2021-09-15',
  'poster_url': null,
  'backdrop_url': null,
  'genres': <Map<String, dynamic>>[
    <String, dynamic>{'tmdb_id': 878, 'name': 'Science Fiction'},
  ],
  'original_language': 'en',
  'runtime': 155,
  'status': 'Released',
  'vote_average': 7.8,
  'vote_count': 13000,
};
