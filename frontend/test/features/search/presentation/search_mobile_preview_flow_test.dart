import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/app/app_bootstrap_data.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/features/search/domain/entities/search_media_type.dart';
import 'package:sofawatch/features/search/domain/entities/search_result.dart';
import 'package:sofawatch/features/search/domain/models/search_result_page.dart';

import '../../../fakes/fake_search_repository.dart';
import '../../../helpers/details_api_test_helper.dart';
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
  popularity: 95.4,
  voteAverage: 7.8,
  voteCount: 13000,
);

void main() {
  group('Search mobile preview flow', () {
    testWidgets('opens Show preview and restores Search state after closing', (
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

      final ApiClient apiClient = createDetailsTestApiClient();

      final AppBootstrapData bootstrapData = createTestBootstrapData(
        searchRepository: searchRepository,
        apiClient: apiClient,
      );

      await tester.pumpSofaWatchApp(
        bootstrapData: bootstrapData,
        surfaceSize: const Size(390, 844),
      );

      final Finder searchAction = find.byKey(
        const ValueKey<String>('mobile-search-pill-action'),
      );

      expect(searchAction, findsOneWidget);

      await tester.tap(searchAction);

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('search-mobile-view')),
        findsOneWidget,
      );

      final Finder searchField = find.byKey(
        const ValueKey<String>('search-text-field'),
      );

      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'Severance');

      await tester.pump(const Duration(milliseconds: 400));

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('search-result-show-95396')),
        findsOneWidget,
      );

      final TextField fieldBeforePreview = tester.widget<TextField>(
        searchField,
      );

      expect(fieldBeforePreview.controller?.text, 'Severance');

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

      final TextField fieldAfterPreview = tester.widget<TextField>(
        find.byKey(const ValueKey<String>('search-text-field')),
      );

      expect(fieldAfterPreview.controller?.text, 'Severance');

      expect(
        searchRepository.searchCallCount,
        1,
        reason: 'Closing Show Details must not repeat the Search.',
      );
    });
    testWidgets(
      'refreshes Movie library state only after returning from Details',
      (WidgetTester tester) async {
        final FakeSearchRepository searchRepository = FakeSearchRepository(
          result: const SearchResultPage(
            page: 1,
            results: <SearchResult>[_movieResult],
            totalPages: 1,
            totalResults: 1,
          ),
        );

        final DetailsApiRequestTracker requestTracker =
            DetailsApiRequestTracker();

        final ApiClient apiClient = createDetailsTestApiClient(
          requestTracker: requestTracker,
        );

        final AppBootstrapData bootstrapData = createTestBootstrapData(
          searchRepository: searchRepository,
          apiClient: apiClient,
        );

        await tester.pumpSofaWatchApp(
          bootstrapData: bootstrapData,
          surfaceSize: const Size(390, 844),
        );

        await tester.tap(
          find.byKey(const ValueKey<String>('mobile-search-pill-action')),
        );

        await tester.pumpAndSettle();

        final Finder searchField = find.byKey(
          const ValueKey<String>('search-text-field'),
        );

        await tester.enterText(searchField, 'Dune');

        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        final Finder movieResult = find.byKey(
          const ValueKey<String>('search-result-movie-438631'),
        );

        expect(movieResult, findsOneWidget);

        await tester.tap(movieResult);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('movie-details-content')),
          findsOneWidget,
        );

        final int importsWhileDetailsOpen = requestTracker.movieImportCallCount;

        final int lookupsWhileDetailsOpen =
            requestTracker.movieLibraryLookupCallCount;

        expect(requestTracker.importedMovieTmdbIds, everyElement(438631));

        await tester.tap(
          find.byKey(const ValueKey<String>('movie-details-close-button')),
        );

        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('search-mobile-view')),
          findsOneWidget,
        );

        expect(
          requestTracker.movieImportCallCount,
          importsWhileDetailsOpen + 1,
          reason:
              'Returning from Movie Details must refresh the Movie state '
              'in the Search LibraryCubit.',
        );

        expect(
          requestTracker.movieLibraryLookupCallCount,
          lookupsWhileDetailsOpen + 1,
        );

        expect(requestTracker.importedMovieTmdbIds.last, 438631);

        expect(requestTracker.movieLibraryLookupIds.last, 'movie-local-uuid');

        expect(
          searchRepository.searchCallCount,
          1,
          reason: 'Refreshing Movie library state must not repeat the Search.',
        );
      },
    );
  });
}
