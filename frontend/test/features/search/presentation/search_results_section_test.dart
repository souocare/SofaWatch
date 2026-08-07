import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/search/domain/entities/search_media_type.dart';
import 'package:sofawatch/features/search/domain/entities/search_result.dart';
import 'package:sofawatch/features/search/presentation/widgets/search_result_row.dart';
import 'package:sofawatch/features/search/presentation/widgets/search_results_section.dart';
import 'package:sofawatch/core/errors/app_exception.dart';

void main() {
  group('SearchResultsSection', () {
    testWidgets('does not show Top Results when the list is empty', (
      WidgetTester tester,
    ) async {
      await _pumpResultsSection(tester, results: const <SearchResult>[]);

      expect(
        find.byKey(const ValueKey<String>('search-top-results-title')),
        findsNothing,
      );

      expect(find.byType(SearchResultRow), findsNothing);
    });

    testWidgets('shows the Top Results heading when results exist', (
      WidgetTester tester,
    ) async {
      await _pumpResultsSection(
        tester,
        results: <SearchResult>[_csiResult, _duneResult],
      );

      expect(find.text('Top Results'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('search-top-results-title')),
        findsOneWidget,
      );
    });

    testWidgets('renders every result in the non-scrollable layout', (
      WidgetTester tester,
    ) async {
      await _pumpResultsSection(
        tester,
        results: <SearchResult>[_csiResult, _duneResult],
      );

      expect(find.byType(SearchResultRow), findsNWidgets(2));

      expect(find.text('CSI: Crime Scene Investigation'), findsOneWidget);
      expect(find.text('Dune'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('search-results-column')),
        findsOneWidget,
      );
    });

    testWidgets('adds separators between rows in the non-scrollable layout', (
      WidgetTester tester,
    ) async {
      await _pumpResultsSection(
        tester,
        results: <SearchResult>[_csiResult, _duneResult, _severanceResult],
      );

      // Three rows require exactly two separators.
      expect(find.byType(Divider), findsNWidgets(2));
    });

    testWidgets('does not add a trailing separator', (
      WidgetTester tester,
    ) async {
      await _pumpResultsSection(tester, results: <SearchResult>[_csiResult]);

      expect(find.byType(SearchResultRow), findsOneWidget);
      expect(find.byType(Divider), findsNothing);
    });

    testWidgets('uses the scrollable results layout when requested', (
      WidgetTester tester,
    ) async {
      await _pumpResultsSection(
        tester,
        results: <SearchResult>[_csiResult, _duneResult],
        scrollable: true,
      );

      expect(
        find.byKey(const ValueKey<String>('search-results-scroll-view')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('search-results-column')),
        findsNothing,
      );

      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('passes the pressed result to onResultPressed', (
      WidgetTester tester,
    ) async {
      SearchResult? pressedResult;

      await _pumpResultsSection(
        tester,
        results: <SearchResult>[_csiResult, _duneResult],
        onResultPressed: (SearchResult result) {
          pressedResult = result;
        },
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('search-result-show-1431')),
      );

      await tester.pump();

      expect(pressedResult, _csiResult);
    });

    testWidgets('passes the correct result to the secondary action', (
      WidgetTester tester,
    ) async {
      SearchResult? actionResult;

      await _pumpResultsSection(
        tester,
        results: <SearchResult>[_csiResult, _duneResult],
        onResultActionPressed: (SearchResult result) {
          actionResult = result;
        },
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('search-result-action-movie-438631')),
      );

      await tester.pump();

      expect(actionResult, _duneResult);
    });

    testWidgets('passes compact mode to result rows', (
      WidgetTester tester,
    ) async {
      await _pumpResultsSection(
        tester,
        results: <SearchResult>[_csiResult],
        compact: true,
      );

      final SearchResultRow row = tester.widget<SearchResultRow>(
        find.byType(SearchResultRow),
      );

      expect(row.compact, isTrue);
    });
  });
  testWidgets('shows a loading indicator while loading the next page', (
    WidgetTester tester,
  ) async {
    await _pumpResultsSection(
      tester,
      results: <SearchResult>[_csiResult, _duneResult],
      isLoadingMore: true,
    );

    expect(
      find.byKey(const ValueKey<String>('search-pagination-loading')),
      findsOneWidget,
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Os resultados existentes continuam visíveis.
    expect(find.text('CSI: Crime Scene Investigation'), findsOneWidget);
    expect(find.text('Dune'), findsOneWidget);
  });

  testWidgets('does not show a pagination footer in the idle state', (
    WidgetTester tester,
  ) async {
    await _pumpResultsSection(
      tester,
      results: <SearchResult>[_csiResult, _duneResult],
    );

    expect(
      find.byKey(const ValueKey<String>('search-pagination-loading')),
      findsNothing,
    );

    expect(
      find.byKey(const ValueKey<String>('search-pagination-error')),
      findsNothing,
    );
  });

  testWidgets('shows a non-blocking pagination error', (
    WidgetTester tester,
  ) async {
    await _pumpResultsSection(
      tester,
      results: <SearchResult>[_csiResult, _duneResult],
      paginationError: const AppException.connectionTimeout(),
    );

    expect(
      find.byKey(const ValueKey<String>('search-pagination-error')),
      findsOneWidget,
    );

    expect(find.text('Could not load more results.'), findsOneWidget);

    expect(
      find.byKey(const ValueKey<String>('search-pagination-retry')),
      findsOneWidget,
    );

    // O erro de paginação não substitui a lista.
    expect(find.text('CSI: Crime Scene Investigation'), findsOneWidget);
    expect(find.text('Dune'), findsOneWidget);
  });

  testWidgets('calls onPaginationRetry when Retry is pressed', (
    WidgetTester tester,
  ) async {
    int retryCount = 0;

    await _pumpResultsSection(
      tester,
      results: <SearchResult>[_csiResult, _duneResult],
      paginationError: const AppException.connectionTimeout(),
      onPaginationRetry: () {
        retryCount++;
      },
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('search-pagination-retry')),
    );

    await tester.pump();

    expect(retryCount, 1);
  });

  testWidgets('requests more results when approaching the end of the list', (
    WidgetTester tester,
  ) async {
    int loadMoreCount = 0;

    await _pumpResultsSection(
      tester,
      results: _manyResults,
      scrollable: true,
      surfaceHeight: 320,
      onLoadMore: () {
        loadMoreCount++;
      },
    );

    final Finder scrollView = find.byKey(
      const ValueKey<String>('search-results-scroll-view'),
    );

    expect(scrollView, findsOneWidget);

    await tester.drag(scrollView, const Offset(0, -2000));

    await tester.pump();

    expect(loadMoreCount, greaterThan(0));
  });

  testWidgets('does not request more while pagination is already loading', (
    WidgetTester tester,
  ) async {
    int loadMoreCount = 0;

    await _pumpResultsSection(
      tester,
      results: _manyResults,
      scrollable: true,
      surfaceHeight: 320,
      isLoadingMore: true,
      onLoadMore: () {
        loadMoreCount++;
      },
    );

    await tester.drag(
      find.byKey(const ValueKey<String>('search-results-scroll-view')),
      const Offset(0, -2000),
    );

    await tester.pump();

    expect(loadMoreCount, 0);
  });

  testWidgets('does not automatically load more after a pagination error', (
    WidgetTester tester,
  ) async {
    int loadMoreCount = 0;

    await _pumpResultsSection(
      tester,
      results: _manyResults,
      scrollable: true,
      surfaceHeight: 320,
      paginationError: const AppException.connectionTimeout(),
      onLoadMore: () {
        loadMoreCount++;
      },
    );

    await tester.drag(
      find.byKey(const ValueKey<String>('search-results-scroll-view')),
      const Offset(0, -2000),
    );

    await tester.pump();

    expect(loadMoreCount, 0);
  });
}

Future<void> _pumpResultsSection(
  WidgetTester tester, {
  required List<SearchResult> results,
  bool scrollable = false,
  bool compact = false,
  bool isLoadingMore = false,
  double surfaceHeight = 700,
  AppException? paginationError,
  VoidCallback? onLoadMore,
  VoidCallback? onPaginationRetry,
  ValueChanged<SearchResult>? onResultPressed,
  ValueChanged<SearchResult>? onResultActionPressed,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 700,
          height: surfaceHeight,
          child: SearchResultsSection(
            results: results,
            scrollable: scrollable,
            compact: compact,
            isLoadingMore: isLoadingMore,
            paginationError: paginationError,
            onLoadMore: onLoadMore,
            onPaginationRetry: onPaginationRetry,
            onResultPressed: onResultPressed ?? (_) {},
            onResultActionPressed: onResultActionPressed,
          ),
        ),
      ),
    ),
  );
}

final SearchResult _csiResult = SearchResult(
  mediaType: SearchMediaType.show,
  tmdbId: 1431,
  title: 'CSI: Crime Scene Investigation',
  originalTitle: 'CSI: Crime Scene Investigation',
  originalLanguage: 'en',
  genreIds: const <int>[80, 18, 9648],
  popularity: 120,
  voteAverage: 7.6,
  voteCount: 1200,
  releaseDate: DateTime(2000, 10, 6),
);

final SearchResult _duneResult = SearchResult(
  mediaType: SearchMediaType.movie,
  tmdbId: 438631,
  title: 'Dune',
  originalTitle: 'Dune',
  originalLanguage: 'en',
  genreIds: const <int>[878, 12],
  popularity: 95.4,
  voteAverage: 7.8,
  voteCount: 13000,
  releaseDate: DateTime(2021, 10, 22),
);

final SearchResult _severanceResult = SearchResult(
  mediaType: SearchMediaType.show,
  tmdbId: 95396,
  title: 'Severance',
  originalTitle: 'Severance',
  originalLanguage: 'en',
  genreIds: const <int>[18, 9648],
  popularity: 120.5,
  voteAverage: 8.4,
  voteCount: 2100,
  releaseDate: DateTime(2022, 2, 18),
);

final List<SearchResult> _manyResults = List<SearchResult>.generate(20, (
  int index,
) {
  return SearchResult(
    mediaType: index.isEven ? SearchMediaType.show : SearchMediaType.movie,
    tmdbId: 10000 + index,
    title: 'Search Result $index',
    originalTitle: 'Search Result $index',
    originalLanguage: 'en',
    genreIds: const <int>[],
    popularity: index.toDouble(),
    voteAverage: 7,
    voteCount: 100,
    releaseDate: DateTime(2000 + index),
  );
});
