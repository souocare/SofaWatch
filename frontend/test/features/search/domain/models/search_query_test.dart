import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/search/domain/models/search_media_type_filter.dart';
import 'package:sofawatch/features/search/domain/models/search_query.dart';

void main() {
  group('SearchQuery', () {
    test('normalizes surrounding whitespace from the search term', () {
      const SearchQuery query = SearchQuery(term: '  Dune  ');

      expect(query.normalizedTerm, 'Dune');
      expect(query.isEmpty, isFalse);
      expect(query.isNotEmpty, isTrue);
    });

    test('reports a whitespace-only term as empty', () {
      const SearchQuery query = SearchQuery(term: '   ');

      expect(query.normalizedTerm, isEmpty);
      expect(query.isEmpty, isTrue);
      expect(query.isNotEmpty, isFalse);
    });

    test('uses the expected default values', () {
      const SearchQuery query = SearchQuery(term: 'Dune');

      expect(query.page, 1);
      expect(query.language, isNull);
      expect(query.mediaType, SearchMediaTypeFilter.all);
    });

    test('creates API query parameters', () {
      const SearchQuery query = SearchQuery(
        term: '  Dune  ',
        page: 2,
        language: ' pt-PT ',
        mediaType: SearchMediaTypeFilter.movie,
      );

      expect(query.toQueryParameters(), <String, dynamic>{
        'query': 'Dune',
        'page': 2,
        'media_type': 'movie',
        'language': 'pt-PT',
      });
    });

    test('omits an absent language from the query parameters', () {
      const SearchQuery query = SearchQuery(
        term: 'Severance',
        mediaType: SearchMediaTypeFilter.show,
      );

      expect(query.toQueryParameters(), <String, dynamic>{
        'query': 'Severance',
        'page': 1,
        'media_type': 'show',
      });
    });

    test('omits a whitespace-only language', () {
      const SearchQuery query = SearchQuery(term: 'Dune', language: '   ');

      expect(query.toQueryParameters().containsKey('language'), isFalse);
    });

    test('creates the first page while preserving other values', () {
      const SearchQuery query = SearchQuery(
        term: 'Dune',
        page: 4,
        language: 'pt-PT',
        mediaType: SearchMediaTypeFilter.movie,
      );

      final SearchQuery firstPage = query.firstPage();

      expect(firstPage.term, 'Dune');
      expect(firstPage.page, 1);
      expect(firstPage.language, 'pt-PT');
      expect(firstPage.mediaType, SearchMediaTypeFilter.movie);
    });

    test('creates the next page', () {
      const SearchQuery query = SearchQuery(term: 'Dune', page: 2);

      expect(query.nextPage().page, 3);
    });

    test('can clear the language through copyWith', () {
      const SearchQuery query = SearchQuery(term: 'Dune', language: 'pt-PT');

      final SearchQuery updated = query.copyWith(clearLanguage: true);

      expect(updated.language, isNull);
    });

    test('uses value equality', () {
      const SearchQuery first = SearchQuery(
        term: 'Dune',
        page: 2,
        language: 'pt-PT',
        mediaType: SearchMediaTypeFilter.movie,
      );

      const SearchQuery second = SearchQuery(
        term: 'Dune',
        page: 2,
        language: 'pt-PT',
        mediaType: SearchMediaTypeFilter.movie,
      );

      expect(first, second);
    });
  });
}
