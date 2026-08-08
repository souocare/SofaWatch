import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/search/data/models/search_response_dto.dart';
import 'package:sofawatch/features/search/domain/entities/search_media_type.dart';
import 'package:sofawatch/features/search/domain/models/search_result_page.dart';

void main() {
  group('SearchResponseDto', () {
    test('parses and maps a paginated mixed response', () {
      final SearchResponseDto dto = SearchResponseDto.fromJson(
        <String, dynamic>{
          'page': 1,
          'results': <Map<String, dynamic>>[
            _resultJson(mediaType: 'show', tmdbId: 95396, title: 'Severance'),
            _resultJson(mediaType: 'movie', tmdbId: 438631, title: 'Dune'),
          ],
          'total_pages': 3,
          'total_results': 42,
        },
      );

      final SearchResultPage page = dto.toDomain();

      expect(page.page, 1);
      expect(page.totalPages, 3);
      expect(page.totalResults, 42);
      expect(page.results, hasLength(2));

      expect(page.results[0].mediaType, SearchMediaType.show);

      expect(page.results[1].mediaType, SearchMediaType.movie);
    });

    test('supports an empty response', () {
      final SearchResultPage page = SearchResponseDto.fromJson(
        <String, dynamic>{
          'page': 1,
          'results': <dynamic>[],
          'total_pages': 0,
          'total_results': 0,
        },
      ).toDomain();

      expect(page.isEmpty, isTrue);
      expect(page.hasNextPage, isFalse);
    });

    test('creates an unmodifiable domain result list', () {
      final SearchResultPage page = SearchResponseDto.fromJson(
        <String, dynamic>{
          'page': 1,
          'results': <Map<String, dynamic>>[_resultJson()],
          'total_pages': 1,
          'total_results': 1,
        },
      ).toDomain();

      expect(() => page.results.clear(), throwsUnsupportedError);
    });

    test('rejects a missing results list', () {
      expect(
        () => SearchResponseDto.fromJson(<String, dynamic>{
          'page': 1,
          'total_pages': 0,
          'total_results': 0,
        }),
        throwsFormatException,
      );
    });

    test('rejects a malformed result entry', () {
      expect(
        () => SearchResponseDto.fromJson(<String, dynamic>{
          'page': 1,
          'results': <Object>['invalid'],
          'total_pages': 1,
          'total_results': 1,
        }),
        throwsFormatException,
      );
    });

    test('rejects an invalid page number', () {
      expect(
        () => SearchResponseDto.fromJson(<String, dynamic>{
          'page': 0,
          'results': <dynamic>[],
          'total_pages': 0,
          'total_results': 0,
        }),
        throwsFormatException,
      );
    });

    test('rejects negative totals', () {
      expect(
        () => SearchResponseDto.fromJson(<String, dynamic>{
          'page': 1,
          'results': <dynamic>[],
          'total_pages': -1,
          'total_results': 0,
        }),
        throwsFormatException,
      );
    });
  });
}

Map<String, dynamic> _resultJson({
  String mediaType = 'movie',
  int tmdbId = 438631,
  String title = 'Dune',
}) {
  return <String, dynamic>{
    'media_type': mediaType,
    'tmdb_id': tmdbId,
    'title': title,
    'original_title': title,
    'overview': null,
    'release_date': null,
    'poster_url': null,
    'backdrop_url': null,
    'original_language': 'en',
    'genre_ids': <int>[],
    'popularity': 0,
    'vote_average': 0,
    'vote_count': 0,
    'in_library': false,
  };
}
