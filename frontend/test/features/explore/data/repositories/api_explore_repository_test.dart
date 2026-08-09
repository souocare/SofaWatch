import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/explore/data/repositories/api_explore_repository.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_item.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_trending_window.dart';

void main() {
  test('loads and maps trending content', () async {
    final Dio dio = Dio();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          expect(options.method, 'GET');
          expect(options.path, '/explore/trending');
          expect(options.queryParameters['window'], 'day');

          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{
                'items': <Map<String, dynamic>>[
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
                  <String, dynamic>{
                    'media_type': 'movie',
                    'tmdb_id': 438631,
                    'title': 'Dune',
                    'original_title': 'Dune',
                    'overview': '',
                    'release_date': '2021-09-15',
                    'poster_url': null,
                    'backdrop_url': null,
                    'original_language': 'en',
                    'genre_ids': <int>[878],
                    'popularity': 95.4,
                    'vote_average': 7.8,
                    'vote_count': 13000,
                  },
                ],
              },
            ),
          );
        },
      ),
    );

    final ApiExploreRepository repository = ApiExploreRepository(
      ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
    );

    final trending = await repository.getTrending(
      window: ExploreTrendingWindow.day,
    );

    expect(trending.items, hasLength(2));

    expect(trending.items.first.title, 'Severance');

    expect(trending.shows, hasLength(1));

    expect(trending.movies, hasLength(1));
  });

  test('forwards the Week window', () async {
    final Dio dio = Dio();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          expect(options.queryParameters['window'], 'week');

          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{'items': <Map<String, dynamic>>[]},
            ),
          );
        },
      ),
    );

    final ApiExploreRepository repository = ApiExploreRepository(
      ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
    );

    await repository.getTrending(window: ExploreTrendingWindow.week);
  });

  test('forwards the trending language parameter', () async {
    final Dio dio = Dio();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          expect(options.queryParameters['window'], 'week');

          expect(options.queryParameters['language'], 'pt-PT');

          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{'items': <Map<String, dynamic>>[]},
            ),
          );
        },
      ),
    );

    final ApiExploreRepository repository = ApiExploreRepository(
      ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
    );

    await repository.getTrending(
      window: ExploreTrendingWindow.week,
      language: 'pt-PT',
    );
  });

  test('maps invalid trending response data to invalidData', () async {
    final Dio dio = Dio();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{'items': 'invalid'},
            ),
          );
        },
      ),
    );

    final ApiExploreRepository repository = ApiExploreRepository(
      ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
    );

    expect(
      repository.getTrending(window: ExploreTrendingWindow.day),
      throwsA(
        isA<AppException>().having(
          (AppException error) => error.type,
          'type',
          AppExceptionType.invalidData,
        ),
      ),
    );
  });

  test('loads and maps Popular TV Shows', () async {
    final Dio dio = Dio();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          expect(options.method, 'GET');

          expect(options.path, '/explore/popular/shows');

          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{
                'items': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'media_type': 'show',
                    'tmdb_id': 1396,
                    'title': 'Breaking Bad',
                    'original_title': 'Breaking Bad',
                    'overview': '',
                    'release_date': '2008-01-20',
                    'poster_url':
                        'https://image.tmdb.org/t/p/w500/breaking-bad.jpg',
                    'backdrop_url': null,
                    'original_language': 'en',
                    'genre_ids': <int>[18],
                    'popularity': 100.0,
                    'vote_average': 9.5,
                    'vote_count': 16000,
                  },
                ],
              },
            ),
          );
        },
      ),
    );

    final ApiExploreRepository repository = ApiExploreRepository(
      ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
    );

    final collection = await repository.getPopularShows();

    expect(collection.items, hasLength(1));

    final ExploreMediaItem item = collection.items.single;

    expect(item.mediaType, ExploreMediaType.show);

    expect(item.tmdbId, 1396);
    expect(item.title, 'Breaking Bad');
    expect(item.releaseYear, 2008);
    expect(item.voteAverage, 9.5);
  });

  test('forwards language when loading Popular TV Shows', () async {
    final Dio dio = Dio();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          expect(options.path, '/explore/popular/shows');

          expect(options.queryParameters['language'], 'pt-PT');

          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{'items': <Map<String, dynamic>>[]},
            ),
          );
        },
      ),
    );

    final ApiExploreRepository repository = ApiExploreRepository(
      ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
    );

    await repository.getPopularShows(language: 'pt-PT');
  });

  test('loads and maps Popular Movies', () async {
    final Dio dio = Dio();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          expect(options.method, 'GET');

          expect(options.path, '/explore/popular/movies');

          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{
                'items': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'media_type': 'movie',
                    'tmdb_id': 157336,
                    'title': 'Interstellar',
                    'original_title': 'Interstellar',
                    'overview': '',
                    'release_date': '2014-11-05',
                    'poster_url':
                        'https://image.tmdb.org/t/p/w500/interstellar.jpg',
                    'backdrop_url': null,
                    'original_language': 'en',
                    'genre_ids': <int>[12, 18, 878],
                    'popularity': 110.0,
                    'vote_average': 8.5,
                    'vote_count': 36000,
                  },
                ],
              },
            ),
          );
        },
      ),
    );

    final ApiExploreRepository repository = ApiExploreRepository(
      ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
    );

    final collection = await repository.getPopularMovies();

    expect(collection.items, hasLength(1));

    final ExploreMediaItem item = collection.items.single;

    expect(item.mediaType, ExploreMediaType.movie);

    expect(item.tmdbId, 157336);
    expect(item.title, 'Interstellar');
    expect(item.releaseYear, 2014);
    expect(item.voteAverage, 8.5);
  });

  test('forwards language when loading Popular Movies', () async {
    final Dio dio = Dio();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          expect(options.path, '/explore/popular/movies');

          expect(options.queryParameters['language'], 'pt-PT');

          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{'items': <Map<String, dynamic>>[]},
            ),
          );
        },
      ),
    );

    final ApiExploreRepository repository = ApiExploreRepository(
      ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
    );

    await repository.getPopularMovies(language: 'pt-PT');
  });

  test('maps invalid Popular Movies response to invalidData', () async {
    final Dio dio = Dio();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          expect(options.path, '/explore/popular/movies');

          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{'items': 'invalid'},
            ),
          );
        },
      ),
    );

    final ApiExploreRepository repository = ApiExploreRepository(
      ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
    );

    expect(
      repository.getPopularMovies(),
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
