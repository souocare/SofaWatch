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
  });
}
