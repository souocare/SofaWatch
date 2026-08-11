import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/movie_details/data/repositories/api_movie_details_repository.dart';
import 'package:sofawatch/features/movie_details/domain/models/movie_details.dart';

void main() {
  group('ApiMovieDetailsRepository', () {
    test('loads and maps Movie details by TMDB ID', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                expect(options.method, 'GET');
                expect(options.path, '/movies/tmdb/550');
                expect(options.queryParameters, isEmpty);

                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, dynamic>{
                      'tmdb_id': 550,
                      'title': 'Fight Club',
                      'original_title': 'Fight Club',
                      'overview': 'Movie overview.',
                      'tagline': 'Mischief. Mayhem. Soap.',
                      'release_date': '1999-10-15',
                      'runtime': 139,
                      'poster_url': 'https://example.com/poster.jpg',
                      'backdrop_url': 'https://example.com/backdrop.jpg',
                      'original_language': 'en',
                      'status': 'Released',
                      'vote_average': 8.4,
                      'vote_count': 30000,
                      'genres': <Map<String, dynamic>>[
                        <String, dynamic>{'name': 'Drama'},
                      ],
                    },
                  ),
                );
              },
        ),
      );

      final ApiMovieDetailsRepository repository = ApiMovieDetailsRepository(
        ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
      );

      final MovieDetails details = await repository.getByTmdbId(550);

      expect(details.tmdbId, 550);
      expect(details.title, 'Fight Club');
      expect(details.originalTitle, 'Fight Club');
      expect(details.overview, 'Movie overview.');
      expect(details.tagline, 'Mischief. Mayhem. Soap.');
      expect(details.releaseDate, DateTime(1999, 10, 15));
      expect(details.releaseYear, 1999);
      expect(details.runtime, 139);
      expect(details.posterUrl, 'https://example.com/poster.jpg');
      expect(details.backdropUrl, 'https://example.com/backdrop.jpg');
      expect(details.originalLanguage, 'en');
      expect(details.status, 'Released');
      expect(details.voteAverage, 8.4);
      expect(details.voteCount, 30000);
      expect(details.genres, <String>['Drama']);
    });

    test('forwards selected language', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                expect(options.method, 'GET');
                expect(options.path, '/movies/tmdb/550');

                expect(options.queryParameters, <String, dynamic>{
                  'language': 'pt-PT',
                });

                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, dynamic>{
                      'tmdb_id': 550,
                      'title': 'Clube de Combate',
                      'original_title': 'Fight Club',
                      'overview': 'Descrição.',
                      'tagline': null,
                      'release_date': '1999-10-15',
                      'runtime': 139,
                      'poster_url': null,
                      'backdrop_url': null,
                      'original_language': 'en',
                      'status': 'Released',
                      'vote_average': 8.4,
                      'vote_count': 30000,
                      'genres': <Map<String, dynamic>>[
                        <String, dynamic>{'name': 'Drama'},
                      ],
                    },
                  ),
                );
              },
        ),
      );

      final ApiMovieDetailsRepository repository = ApiMovieDetailsRepository(
        ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
      );

      final MovieDetails details = await repository.getByTmdbId(
        550,
        language: 'pt-PT',
      );

      expect(details.title, 'Clube de Combate');
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

      final ApiMovieDetailsRepository repository = ApiMovieDetailsRepository(
        ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
      );

      expect(
        repository.getByTmdbId(550),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('maps malformed Movie response to invalidData', () async {
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
                      'tmdb_id': 550,

                      // title intentionally missing.
                      'original_title': 'Fight Club',
                      'genres': <String>[],
                    },
                  ),
                );
              },
        ),
      );

      final ApiMovieDetailsRepository repository = ApiMovieDetailsRepository(
        ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
      );

      expect(
        repository.getByTmdbId(550),
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
