import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/search/domain/entities/search_media_type.dart';
import 'package:sofawatch/features/search/domain/entities/search_result.dart';
import 'package:sofawatch/features/search/domain/models/search_result_page.dart';

void main() {
  group('SearchResultPage', () {
    test('reports whether results are empty', () {
      const SearchResultPage emptyPage = SearchResultPage(
        page: 1,
        results: <SearchResult>[],
        totalPages: 0,
        totalResults: 0,
      );

      expect(emptyPage.isEmpty, isTrue);
      expect(emptyPage.isNotEmpty, isFalse);
    });

    test('reports the next page when one is available', () {
      const SearchResultPage page = SearchResultPage(
        page: 1,
        results: <SearchResult>[],
        totalPages: 3,
        totalResults: 50,
      );

      expect(page.hasNextPage, isTrue);
      expect(page.nextPage, 2);
    });

    test('does not report a next page on the final page', () {
      const SearchResultPage page = SearchResultPage(
        page: 3,
        results: <SearchResult>[],
        totalPages: 3,
        totalResults: 50,
      );

      expect(page.hasNextPage, isFalse);
      expect(page.nextPage, isNull);
    });

    test('appends a later page', () {
      const SearchResult dune = SearchResult(
        mediaType: SearchMediaType.movie,
        tmdbId: 438631,
        title: 'Dune',
        originalTitle: 'Dune',
        originalLanguage: 'en',
        genreIds: <int>[878, 12],
        popularity: 95.4,
        voteAverage: 7.8,
        voteCount: 13000,
      );

      const SearchResult severance = SearchResult(
        mediaType: SearchMediaType.show,
        tmdbId: 95396,
        title: 'Severance',
        originalTitle: 'Severance',
        originalLanguage: 'en',
        genreIds: <int>[18, 9648],
        popularity: 120.5,
        voteAverage: 8.4,
        voteCount: 2100,
      );

      const SearchResultPage firstPage = SearchResultPage(
        page: 1,
        results: <SearchResult>[dune],
        totalPages: 2,
        totalResults: 2,
      );

      const SearchResultPage secondPage = SearchResultPage(
        page: 2,
        results: <SearchResult>[severance],
        totalPages: 2,
        totalResults: 2,
      );

      final SearchResultPage combined = firstPage.append(secondPage);

      expect(combined.page, 2);
      expect(combined.results, <SearchResult>[dune, severance]);
      expect(combined.totalPages, 2);
      expect(combined.totalResults, 2);
      expect(combined.hasNextPage, isFalse);
    });

    test('ignores a page that is not later than the current page', () {
      const SearchResultPage currentPage = SearchResultPage(
        page: 2,
        results: <SearchResult>[],
        totalPages: 3,
        totalResults: 30,
      );

      const SearchResultPage stalePage = SearchResultPage(
        page: 1,
        results: <SearchResult>[],
        totalPages: 3,
        totalResults: 30,
      );

      expect(identical(currentPage.append(stalePage), currentPage), isTrue);
    });

    test('uses value equality', () {
      const SearchResultPage first = SearchResultPage(
        page: 1,
        results: <SearchResult>[],
        totalPages: 0,
        totalResults: 0,
      );

      const SearchResultPage second = SearchResultPage(
        page: 1,
        results: <SearchResult>[],
        totalPages: 0,
        totalResults: 0,
      );

      expect(first, second);
    });
  });
}
