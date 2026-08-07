import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/search/domain/entities/search_media_type.dart';
import 'package:sofawatch/features/search/domain/entities/search_result.dart';
import 'package:sofawatch/features/search/presentation/widgets/search_result_row.dart';
import 'package:sofawatch/features/search/presentation/widgets/search_results_section.dart';

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
}

Future<void> _pumpResultsSection(
  WidgetTester tester, {
  required List<SearchResult> results,
  bool scrollable = false,
  bool compact = false,
  ValueChanged<SearchResult>? onResultPressed,
  ValueChanged<SearchResult>? onResultActionPressed,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 700,
          height: 700,
          child: SearchResultsSection(
            results: results,
            scrollable: scrollable,
            compact: compact,
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
