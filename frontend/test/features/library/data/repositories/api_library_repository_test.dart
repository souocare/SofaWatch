import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/features/library/data/repositories/api_library_repository.dart';
import 'package:sofawatch/features/library/domain/models/library_media_type.dart';

void main() {
  group('ApiLibraryRepository', () {
    test('imports a Show by TMDB ID', () async {
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
                    data: <String, dynamic>{
                      'id': 'show-uuid',
                      'tmdb_id': 95396,
                    },
                  ),
                );
              },
        ),
      );

      final ApiLibraryRepository repository = ApiLibraryRepository(
        ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
      );

      final result = await repository.importShowByTmdbId(95396);

      expect(result.id, 'show-uuid');
      expect(result.tmdbId, 95396);
      expect(result.mediaType, LibraryMediaType.show);
    });

    test('imports a Movie by TMDB ID', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                expect(options.path, '/movies/import/tmdb/438631');

                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, dynamic>{
                      'id': 'movie-uuid',
                      'tmdb_id': 438631,
                    },
                  ),
                );
              },
        ),
      );

      final ApiLibraryRepository repository = ApiLibraryRepository(
        ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
      );

      final result = await repository.importMovieByTmdbId(438631);

      expect(result.id, 'movie-uuid');
      expect(result.mediaType, LibraryMediaType.movie);
    });
  });

  test('adds a Movie to the Library', () async {
    final Dio dio = Dio();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          expect(options.path, '/library/movies/movie-uuid');

          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{
                'id': 'entry-uuid',
                'show_id': null,
                'movie_id': 'movie-uuid',
                'status': 'planning',
                'rating': null,
                'started_at': null,
                'completed_at': null,
                'created_at': '2026-08-08T14:00:00Z',
                'updated_at': '2026-08-08T14:00:00Z',
              },
            ),
          );
        },
      ),
    );

    final ApiLibraryRepository repository = ApiLibraryRepository(
      ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
    );

    final entry = await repository.addMovie('movie-uuid');

    expect(entry.id, 'entry-uuid');
    expect(entry.mediaId, 'movie-uuid');
    expect(entry.mediaType, LibraryMediaType.movie);
  });

  test('removes a Show from the Library', () async {
    final Dio dio = Dio();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          expect(options.method, 'DELETE');

          expect(options.path, '/library/shows/show-uuid');

          handler.resolve(
            Response<void>(requestOptions: options, statusCode: 204),
          );
        },
      ),
    );

    final ApiLibraryRepository repository = ApiLibraryRepository(
      ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
    );

    await repository.removeShow('show-uuid');
  });

  test('removes a Movie from the Library', () async {
    final Dio dio = Dio();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          expect(options.method, 'DELETE');

          expect(options.path, '/library/movies/movie-uuid');

          handler.resolve(
            Response<void>(requestOptions: options, statusCode: 204),
          );
        },
      ),
    );

    final ApiLibraryRepository repository = ApiLibraryRepository(
      ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
    );

    await repository.removeMovie('movie-uuid');
  });
}
