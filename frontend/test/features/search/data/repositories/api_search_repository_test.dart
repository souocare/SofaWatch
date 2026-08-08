import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/search/data/repositories/api_search_repository.dart';
import 'package:sofawatch/features/search/domain/entities/search_media_type.dart';
import 'package:sofawatch/features/search/domain/models/search_media_type_filter.dart';
import 'package:sofawatch/features/search/domain/models/search_query.dart';
import 'package:sofawatch/features/search/domain/models/search_result_page.dart';

void main() {
  group('ApiSearchRepository', () {
    late ApiClient apiClient;
    late DioAdapter dioAdapter;
    late ApiSearchRepository repository;

    setUp(() {
      apiClient = ApiClient(
        baseUrl: Uri.parse('https://server.example.com'),
        dio: Dio(),
      );

      dioAdapter = DioAdapter(dio: apiClient.dio, printLogs: false);

      repository = ApiSearchRepository(apiClient);
    });

    test('searches and maps mixed media results', () async {
      dioAdapter.onGet(
        '/search',
        (server) {
          return server.reply(200, <String, dynamic>{
            'page': 1,
            'results': <Map<String, dynamic>>[
              _searchResultJson(
                mediaType: 'show',
                tmdbId: 95396,
                title: 'Severance',
                releaseDate: '2022-02-17',
                posterUrl: 'https://image.tmdb.org/t/p/w500/severance.jpg',
              ),
              _searchResultJson(
                mediaType: 'movie',
                tmdbId: 438631,
                title: 'Dune',
                releaseDate: '2021-09-15',
                posterUrl: 'https://image.tmdb.org/t/p/w500/dune.jpg',
              ),
            ],
            'total_pages': 2,
            'total_results': 25,
          });
        },
        queryParameters: <String, dynamic>{
          'query': 'Dune',
          'page': 1,
          'media_type': 'all',
        },
      );

      final SearchResultPage result = await repository.search(
        const SearchQuery(term: 'Dune'),
      );

      expect(result.page, 1);
      expect(result.totalPages, 2);
      expect(result.totalResults, 25);
      expect(result.results, hasLength(2));

      expect(result.results[0].mediaType, SearchMediaType.show);

      expect(result.results[0].title, 'Severance');

      expect(result.results[1].mediaType, SearchMediaType.movie);

      expect(result.results[1].title, 'Dune');
    });

    test('trims the search term before making the request', () async {
      dioAdapter.onGet(
        '/search',
        (server) {
          return server.reply(200, _emptySearchResponse());
        },
        queryParameters: <String, dynamic>{
          'query': 'Severance',
          'page': 1,
          'media_type': 'all',
        },
      );

      await repository.search(const SearchQuery(term: '  Severance  '));
    });

    test('forwards the movie media type filter', () async {
      dioAdapter.onGet(
        '/search',
        (server) {
          return server.reply(200, _emptySearchResponse());
        },
        queryParameters: <String, dynamic>{
          'query': 'Dune',
          'page': 1,
          'media_type': 'movie',
        },
      );

      await repository.search(
        const SearchQuery(term: 'Dune', mediaType: SearchMediaTypeFilter.movie),
      );
    });

    test('forwards the show media type filter', () async {
      dioAdapter.onGet(
        '/search',
        (server) {
          return server.reply(200, _emptySearchResponse());
        },
        queryParameters: <String, dynamic>{
          'query': 'Severance',
          'page': 1,
          'media_type': 'show',
        },
      );

      await repository.search(
        const SearchQuery(
          term: 'Severance',
          mediaType: SearchMediaTypeFilter.show,
        ),
      );
    });

    test('forwards the requested page', () async {
      dioAdapter.onGet(
        '/search',
        (server) {
          return server.reply(200, <String, dynamic>{
            'page': 3,
            'results': <dynamic>[],
            'total_pages': 3,
            'total_results': 50,
          });
        },
        queryParameters: <String, dynamic>{
          'query': 'Breaking Bad',
          'page': 3,
          'media_type': 'all',
        },
      );

      final SearchResultPage result = await repository.search(
        const SearchQuery(term: 'Breaking Bad', page: 3),
      );

      expect(result.page, 3);
    });

    test('forwards the requested language', () async {
      dioAdapter.onGet(
        '/search',
        (server) {
          return server.reply(200, _emptySearchResponse());
        },
        queryParameters: <String, dynamic>{
          'query': 'Dark',
          'page': 1,
          'media_type': 'all',
          'language': 'pt-PT',
        },
      );

      await repository.search(
        const SearchQuery(term: 'Dark', language: 'pt-PT'),
      );
    });

    test('trims the requested language', () async {
      dioAdapter.onGet(
        '/search',
        (server) {
          return server.reply(200, _emptySearchResponse());
        },
        queryParameters: <String, dynamic>{
          'query': 'Dark',
          'page': 1,
          'media_type': 'all',
          'language': 'pt-PT',
        },
      );

      await repository.search(
        const SearchQuery(term: 'Dark', language: '  pt-PT  '),
      );
    });

    test('omits the language when it is not configured', () async {
      dioAdapter.onGet(
        '/search',
        (server) {
          return server.reply(200, _emptySearchResponse());
        },
        queryParameters: <String, dynamic>{
          'query': 'Dark',
          'page': 1,
          'media_type': 'all',
        },
      );

      await repository.search(const SearchQuery(term: 'Dark'));
    });

    test('propagates AppException from the API client', () async {
      dioAdapter.onGet(
        '/search',
        (server) {
          return server.reply(503, <String, dynamic>{
            'error': <String, dynamic>{
              'code': 'tmdb_unavailable',
              'message': 'The TMDB service is currently unavailable.',
            },
          });
        },
        queryParameters: <String, dynamic>{
          'query': 'Dune',
          'page': 1,
          'media_type': 'all',
        },
      );

      await expectLater(
        repository.search(const SearchQuery(term: 'Dune')),
        throwsA(
          isA<AppException>()
              .having(
                (AppException exception) => exception.code,
                'code',
                'tmdb_unavailable',
              )
              .having(
                (AppException exception) => exception.statusCode,
                'statusCode',
                503,
              ),
        ),
      );
    });

    test('maps malformed response data to invalidData', () async {
      dioAdapter.onGet(
        '/search',
        (server) {
          return server.reply(200, <String, dynamic>{
            'page': 1,
            'results': 'invalid',
            'total_pages': 1,
            'total_results': 1,
          });
        },
        queryParameters: <String, dynamic>{
          'query': 'Dune',
          'page': 1,
          'media_type': 'all',
        },
      );

      await expectLater(
        repository.search(const SearchQuery(term: 'Dune')),
        throwsA(
          isA<AppException>().having(
            (AppException exception) => exception.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('maps a malformed result to invalidData', () async {
      dioAdapter.onGet(
        '/search',
        (server) {
          return server.reply(200, <String, dynamic>{
            'page': 1,
            'results': <Map<String, dynamic>>[
              _searchResultJson(mediaType: 'person'),
            ],
            'total_pages': 1,
            'total_results': 1,
          });
        },
        queryParameters: <String, dynamic>{
          'query': 'Example',
          'page': 1,
          'media_type': 'all',
        },
      );

      await expectLater(
        repository.search(const SearchQuery(term: 'Example')),
        throwsA(
          isA<AppException>().having(
            (AppException exception) => exception.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('maps an invalid image URL to invalidData', () async {
      dioAdapter.onGet(
        '/search',
        (server) {
          return server.reply(200, <String, dynamic>{
            'page': 1,
            'results': <Map<String, dynamic>>[
              _searchResultJson(posterUrl: '/poster.jpg'),
            ],
            'total_pages': 1,
            'total_results': 1,
          });
        },
        queryParameters: <String, dynamic>{
          'query': 'Dune',
          'page': 1,
          'media_type': 'all',
        },
      );

      await expectLater(
        repository.search(const SearchQuery(term: 'Dune')),
        throwsA(
          isA<AppException>().having(
            (AppException exception) => exception.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });
  });
}

Map<String, dynamic> _emptySearchResponse() {
  return <String, dynamic>{
    'page': 1,
    'results': <dynamic>[],
    'total_pages': 0,
    'total_results': 0,
  };
}

Map<String, dynamic> _searchResultJson({
  String mediaType = 'movie',
  int tmdbId = 438631,
  String title = 'Dune',
  String? releaseDate = '2021-09-15',
  String? posterUrl = 'https://image.tmdb.org/t/p/w500/dune.jpg',
}) {
  return <String, dynamic>{
    'media_type': mediaType,
    'tmdb_id': tmdbId,
    'title': title,
    'original_title': title,
    'overview': 'Example overview.',
    'release_date': releaseDate,
    'poster_url': posterUrl,
    'backdrop_url': 'https://image.tmdb.org/t/p/original/backdrop.jpg',
    'original_language': 'en',
    'genre_ids': <int>[18],
    'popularity': 95.4,
    'vote_average': 7.8,
    'vote_count': 13000,
    'in_library': false,
  };
}
