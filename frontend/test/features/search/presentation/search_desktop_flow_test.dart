@TestOn('browser')
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/app/app_bootstrap_data.dart';
import 'package:sofawatch/app/theme/tokens/app_breakpoints.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/features/search/domain/entities/search_media_type.dart';
import 'package:sofawatch/features/search/domain/entities/search_result.dart';
import 'package:sofawatch/features/search/domain/models/search_result_page.dart';
import 'package:sofawatch/features/search/presentation/views/search_mobile_view.dart';

import '../../../fakes/fake_search_repository.dart';
import '../../../helpers/details_api_test_helper.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_bootstrap_data.dart';

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

Future<void> pumpDesktopApp(
  WidgetTester tester, {
  Size size = const Size(1280, 900),
  AppBootstrapData? bootstrapData,
}) async {
  await tester.pumpSofaWatchWebApp(
    bootstrapData: bootstrapData,
    surfaceSize: size,
  );
}

Future<void> openSearch(WidgetTester tester) async {
  final Finder searchAction = find.byKey(
    const ValueKey<String>('web-search-action'),
  );

  expect(searchAction, findsOneWidget);

  final IconButton searchButton = tester.widget<IconButton>(searchAction);

  expect(
    searchButton.onPressed,
    isNotNull,
    reason: 'The Web Search action must be enabled before Search opens.',
  );

  await tester.tap(searchAction);

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

void main() {
  // const ValueKey<String> webSearchActionKey = ValueKey<String>(
  //   'web-search-action',
  // );

  const ValueKey<String> modalKey = ValueKey<String>('search-desktop-modal');

  // const ValueKey<String> closeButtonKey = ValueKey<String>(
  //   'search-desktop-close-button',
  // );

  // const ValueKey<String> homePageTitleKey = ValueKey<String>('home-page-title');

  group('Desktop Search modal', () {
    testWidgets('shows the initial guidance before a search', (
      WidgetTester tester,
    ) async {
      await pumpDesktopApp(tester);
      await openSearch(tester);

      expect(
        find.byKey(const ValueKey<String>('search-desktop-placeholder')),
        findsOneWidget,
      );

      expect(find.text('Search for movies and TV shows.'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('search-loading-state')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('search-empty-state')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('search-failure-state')),
        findsNothing,
      );
    });
    testWidgets('autofocuses the Search field', (WidgetTester tester) async {
      await pumpDesktopApp(tester);
      await openSearch(tester);

      final Finder modal = find.byKey(
        const ValueKey<String>('search-desktop-modal'),
      );

      expect(modal, findsOneWidget);

      final Finder editableTextFinder = find.descendant(
        of: modal,
        matching: find.byType(EditableText),
      );

      expect(editableTextFinder, findsOneWidget);

      await tester.pump();

      final EditableText editableText = tester.widget<EditableText>(
        editableTextFinder,
      );

      expect(editableText.focusNode.hasFocus, isTrue);
    });

    testWidgets('closes with the X button', (WidgetTester tester) async {
      await pumpDesktopApp(tester);
      await openSearch(tester);

      expect(find.byKey(modalKey), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('search-desktop-close-button')),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(modalKey), findsNothing);
    });
  });

  testWidgets('closes when the backdrop is clicked', (
    WidgetTester tester,
  ) async {
    await pumpDesktopApp(tester);
    await openSearch(tester);

    final Finder modal = find.byKey(modalKey);

    final Finder backdrop = find.byKey(
      const ValueKey<String>('search-desktop-backdrop'),
    );

    expect(modal, findsOneWidget);
    expect(backdrop, findsOneWidget);

    final Rect backdropRect = tester.getRect(backdrop);
    final Rect modalRect = tester.getRect(modal);

    final Offset outsideModal = Offset(
      backdropRect.left + 16,
      backdropRect.top + 16,
    );

    expect(
      modalRect.contains(outsideModal),
      isFalse,
      reason: 'The backdrop test position must be outside the modal.',
    );

    await tester.tapAt(outsideModal);
    await tester.pumpAndSettle();

    expect(modal, findsNothing);
  });

  testWidgets('does not close when the modal is clicked', (
    WidgetTester tester,
  ) async {
    await pumpDesktopApp(tester);
    await openSearch(tester);

    final Finder modal = find.byKey(modalKey);

    expect(modal, findsOneWidget);

    await tester.tap(modal);
    await tester.pump();

    expect(modal, findsOneWidget);
  });

  testWidgets('closes when Escape is pressed', (WidgetTester tester) async {
    await pumpDesktopApp(tester);
    await openSearch(tester);

    expect(find.byKey(modalKey), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);

    await tester.pumpAndSettle();

    expect(find.byKey(modalKey), findsNothing);
  });

  testWidgets('returns to the route from which Search was opened', (
    WidgetTester tester,
  ) async {
    await pumpDesktopApp(tester);

    await tester.tap(find.text('Shows'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('shows-page-title')),
      findsOneWidget,
    );

    await openSearch(tester);

    expect(find.byKey(modalKey), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('search-desktop-close-button')),
    );

    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('shows-page-title')),
      findsOneWidget,
    );
  });

  testWidgets('uses the mobile Search layout in a narrow browser', (
    WidgetTester tester,
  ) async {
    await pumpDesktopApp(
      tester,
      size: const Size(AppBreakpoints.tablet - 1, 800),
    );

    await openSearch(tester);

    expect(
      find.byKey(const ValueKey<String>('search-desktop-modal')),
      findsNothing,
    );

    expect(find.byType(SearchMobileView), findsOneWidget);
  });
  testWidgets('shows the initial guidance on mobile before a search', (
    WidgetTester tester,
  ) async {
    await pumpDesktopApp(
      tester,
      size: const Size(AppBreakpoints.tablet - 1, 800),
    );

    await openSearch(tester);

    expect(find.byType(SearchMobileView), findsOneWidget);

    expect(
      find.byKey(const ValueKey<String>('search-mobile-placeholder')),
      findsOneWidget,
    );

    expect(find.text('Search for a movie or TV show.'), findsOneWidget);

    expect(
      find.byKey(const ValueKey<String>('search-loading-state')),
      findsNothing,
    );

    expect(
      find.byKey(const ValueKey<String>('search-empty-state')),
      findsNothing,
    );

    expect(
      find.byKey(const ValueKey<String>('search-failure-state')),
      findsNothing,
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

      await pumpDesktopApp(tester, bootstrapData: bootstrapData);

      await openSearch(tester);

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

      await tester.tap(
        find.byKey(const ValueKey<String>('movie-details-close-button')),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(modalKey), findsOneWidget);

      expect(
        requestTracker.movieImportCallCount,
        importsWhileDetailsOpen + 1,
        reason:
            'Returning from Movie Details must refresh the Movie state '
            'in the desktop Search LibraryCubit.',
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
}
