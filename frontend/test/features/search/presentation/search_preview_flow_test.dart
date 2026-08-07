@TestOn('browser')
library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/app/app_bootstrap_data.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/features/search/domain/entities/search_media_type.dart';
import 'package:sofawatch/features/search/domain/entities/search_result.dart';
import 'package:sofawatch/features/search/domain/models/search_result_page.dart';

import '../../../fakes/fake_search_repository.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_bootstrap_data.dart';

const SearchResult _showResult = SearchResult(
  mediaType: SearchMediaType.show,
  tmdbId: 95396,
  title: 'Severance',
  originalTitle: 'Severance',
  originalLanguage: 'en',
  genreIds: <int>[18, 9648],
  popularity: 100,
  voteAverage: 8.4,
  voteCount: 3000,
);

const SearchResult _movieResult = SearchResult(
  mediaType: SearchMediaType.movie,
  tmdbId: 438631,
  title: 'Dune',
  originalTitle: 'Dune',
  originalLanguage: 'en',
  genreIds: <int>[878, 12],
  popularity: 100,
  voteAverage: 7.8,
  voteCount: 13000,
);

void main() {
  group('Search preview flow', () {
    testWidgets('opens the Show preview for a Show result', (
      WidgetTester tester,
    ) async {
      final FakeSearchRepository searchRepository = FakeSearchRepository(
        result: const SearchResultPage(
          page: 1,
          results: <SearchResult>[_showResult],
          totalPages: 1,
          totalResults: 1,
        ),
      );

      await _pumpApp(tester, searchRepository: searchRepository);

      await _openSearchAndQuery(tester, query: 'Severance');

      await tester.tap(
        find.byKey(const ValueKey<String>('search-result-show-95396')),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('show-details-content')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('show-details-title')),
        findsOneWidget,
      );

      expect(find.text('Severance'), findsWidgets);
    });

    testWidgets('opens the Movie preview for a Movie result', (
      WidgetTester tester,
    ) async {
      final FakeSearchRepository searchRepository = FakeSearchRepository(
        result: const SearchResultPage(
          page: 1,
          results: <SearchResult>[_movieResult],
          totalPages: 1,
          totalResults: 1,
        ),
      );

      await _pumpApp(tester, searchRepository: searchRepository);

      await _openSearchAndQuery(tester, query: 'Dune');

      await tester.tap(
        find.byKey(const ValueKey<String>('search-result-movie-438631')),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('movie-details-content')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('movie-details-title')),
        findsOneWidget,
      );

      expect(find.text('Dune'), findsWidgets);
    });

    testWidgets('restores Search query and results after closing a preview', (
      WidgetTester tester,
    ) async {
      final FakeSearchRepository searchRepository = FakeSearchRepository(
        result: const SearchResultPage(
          page: 1,
          results: <SearchResult>[_showResult],
          totalPages: 1,
          totalResults: 1,
        ),
      );

      await _pumpApp(tester, searchRepository: searchRepository);

      await _openSearchAndQuery(tester, query: 'Severance');

      expect(
        find.byKey(const ValueKey<String>('search-result-show-95396')),
        findsOneWidget,
      );

      final TextField searchFieldBeforePreview = tester.widget<TextField>(
        find.byKey(const ValueKey<String>('search-text-field')),
      );

      expect(searchFieldBeforePreview.controller?.text, 'Severance');

      await tester.tap(
        find.byKey(const ValueKey<String>('search-result-show-95396')),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('show-details-content')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('show-details-close-button')),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('search-desktop-modal')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('search-result-show-95396')),
        findsOneWidget,
      );

      final TextField searchFieldAfterPreview = tester.widget<TextField>(
        find.byKey(const ValueKey<String>('search-text-field')),
      );

      expect(searchFieldAfterPreview.controller?.text, 'Severance');

      expect(
        searchRepository.searchCallCount,
        1,
        reason: 'Closing the preview must not trigger the same Search again.',
      );
    });

    testWidgets('restores the Search scroll position after closing a preview', (
      WidgetTester tester,
    ) async {
      final List<SearchResult> results = List<SearchResult>.generate(20, (
        int index,
      ) {
        return SearchResult(
          mediaType: SearchMediaType.show,
          tmdbId: 95396 + index,
          title: index == 10 ? 'Severance' : 'Show $index',
          originalTitle: index == 10 ? 'Severance' : 'Show $index',
          originalLanguage: 'en',
          genreIds: const <int>[18],
          popularity: 100,
          voteAverage: 8,
          voteCount: 100,
        );
      }, growable: false);

      final FakeSearchRepository searchRepository = FakeSearchRepository(
        result: SearchResultPage(
          page: 1,
          results: results,
          totalPages: 1,
          totalResults: results.length,
        ),
      );

      await _pumpApp(tester, searchRepository: searchRepository);

      await _openSearchAndQuery(tester, query: 'Show');

      final Finder scrollable = find.byKey(
        const ValueKey<String>('search-desktop-scrollable-content'),
      );

      expect(scrollable, findsOneWidget);

      await tester.drag(scrollable, const Offset(0, -500));

      await tester.pumpAndSettle();

      final ScrollableState scrollableStateBefore = tester
          .state<ScrollableState>(
            find.descendant(of: scrollable, matching: find.byType(Scrollable)),
          );

      final double offsetBefore = scrollableStateBefore.position.pixels;

      expect(offsetBefore, greaterThan(0));

      final Finder targetResult = find.byKey(
        const ValueKey<String>('search-result-show-95406'),
      );

      await tester.ensureVisible(targetResult);
      await tester.pumpAndSettle();

      final ScrollableState stateBeforePreview = tester.state<ScrollableState>(
        find.descendant(of: scrollable, matching: find.byType(Scrollable)),
      );

      final double expectedOffset = stateBeforePreview.position.pixels;

      await tester.tap(targetResult);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('show-details-content')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('show-details-close-button')),
      );

      await tester.pumpAndSettle();

      final ScrollableState scrollableStateAfter = tester
          .state<ScrollableState>(
            find.descendant(
              of: find.byKey(
                const ValueKey<String>('search-desktop-scrollable-content'),
              ),
              matching: find.byType(Scrollable),
            ),
          );

      expect(scrollableStateAfter.position.pixels, closeTo(expectedOffset, 1));
    });

    testWidgets(
      'opens preview as a page on mobile and restores Search when closed',
      (WidgetTester tester) async {
        final FakeSearchRepository searchRepository = FakeSearchRepository(
          result: const SearchResultPage(
            page: 1,
            results: <SearchResult>[_showResult],
            totalPages: 1,
            totalResults: 1,
          ),
        );

        await _pumpApp(
          tester,
          searchRepository: searchRepository,
          size: const Size(390, 844),
        );

        await _openSearchAndQuery(tester, query: 'Severance');

        expect(
          find.byKey(const ValueKey<String>('search-mobile-view')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const ValueKey<String>('search-result-show-95396')),
        );

        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('show-details-content')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const ValueKey<String>('show-details-close-button')),
        );

        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('search-mobile-view')),
          findsOneWidget,
        );

        expect(
          find.byKey(const ValueKey<String>('search-result-show-95396')),
          findsOneWidget,
        );
      },
    );
  });
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required FakeSearchRepository searchRepository,
  Size size = const Size(1280, 900),
}) async {
  final Dio dio = Dio();

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
        if (options.path.endsWith('/shows/tmdb/95396')) {
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: _showDetailsResponse,
            ),
          );
          return;
        }

        if (options.path.endsWith('/movies/tmdb/438631')) {
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: _movieDetailsResponse,
            ),
          );
          return;
        }

        handler.next(options);
      },
    ),
  );

  final ApiClient apiClient = ApiClient(
    baseUrl: Uri.parse('http://localhost:8000'),
    dio: dio,
  );

  final AppBootstrapData bootstrapData = createTestBootstrapData(
    searchRepository: searchRepository,
    apiClient: apiClient,
  );

  await tester.pumpSofaWatchWebApp(
    bootstrapData: bootstrapData,
    surfaceSize: const Size(1280, 900),
  );
}

Future<void> _openSearchAndQuery(
  WidgetTester tester, {
  required String query,
}) async {
  await tester.tap(find.byKey(const ValueKey<String>('web-search-action')));

  await tester.pumpAndSettle();

  final Finder searchField = find.byKey(
    const ValueKey<String>('search-text-field'),
  );

  expect(searchField, findsOneWidget);

  await tester.enterText(searchField, query);

  await tester.pump(const Duration(milliseconds: 400));

  await tester.pumpAndSettle();
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
  'genres': <Map<String, dynamic>>[
    <String, dynamic>{'tmdb_id': 18, 'name': 'Drama'},
  ],
  'original_language': 'en',
  'number_of_seasons': 2,
  'number_of_episodes': 19,
  'in_production': true,
  'status': 'Returning Series',
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
