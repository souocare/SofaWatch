import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/explore/data/repositories/api_explore_repository.dart';

void main() {
  test('loads and maps trending content', () async {
    final Dio dio = Dio();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          expect(options.method, 'GET');
          expect(options.path, '/explore/trending');

          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{
                'shows': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'media_type': 'show',
                    'tmdb_id': 95396,
                    'title': 'Severance',
                    'original_title': 'Severance',
                    'overview': '',
                    'release_date': '2022-02-17',
                    'poster_url': null,
                    'backdrop_url': null,
                    'original_language': 'en',
                    'genre_ids': <int>[18],
                    'popularity': 120.5,
                    'vote_average': 8.4,
                    'vote_count': 2100,
                  },
                ],
                'movies': <Map<String, dynamic>>[],
              },
            ),
          );
        },
      ),
    );

    final ApiExploreRepository repository = ApiExploreRepository(
      ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
    );

    final trending = await repository.getTrending();

    expect(trending.shows, hasLength(1));
    expect(trending.shows.single.title, 'Severance');
  });

  test('forwards the language parameter', () async {
    final Dio dio = Dio();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          expect(options.queryParameters['language'], 'pt-PT');

          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{
                'shows': <Map<String, dynamic>>[],
                'movies': <Map<String, dynamic>>[],
              },
            ),
          );
        },
      ),
    );

    final ApiExploreRepository repository = ApiExploreRepository(
      ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
    );

    await repository.getTrending(language: 'pt-PT');
  });

  test('maps invalid response data to invalidData', () async {
    final Dio dio = Dio();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{
                'shows': 'invalid',
                'movies': <Map<String, dynamic>>[],
              },
            ),
          );
        },
      ),
    );

    final ApiExploreRepository repository = ApiExploreRepository(
      ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
    );

    expect(
      repository.getTrending(),
      throwsA(
        isA<AppException>().having(
          (AppException error) => error.type,
          'type',
          AppExceptionType.invalidData,
        ),
      ),
    );
  });
}
