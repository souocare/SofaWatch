import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/search/domain/entities/search_media_type.dart';
import 'package:sofawatch/features/search/domain/entities/search_result.dart';
import 'package:sofawatch/features/search/presentation/widgets/search_result_row.dart';

void main() {
  group('SearchResultRow', () {
    testWidgets('shows the result title, media type and release year', (
      WidgetTester tester,
    ) async {
      await _pumpResultRow(tester, result: _csiResult);

      expect(find.text('CSI: Crime Scene Investigation'), findsOneWidget);
      expect(find.text('Show'), findsOneWidget);
      expect(find.text('2000'), findsOneWidget);
      expect(find.text('•'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('search-result-title-show-1431')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('search-result-metadata-show-1431')),
        findsOneWidget,
      );
    });

    testWidgets('shows Movie for movie results', (WidgetTester tester) async {
      await _pumpResultRow(tester, result: _duneResult);

      expect(find.text('Dune'), findsOneWidget);
      expect(find.text('Movie'), findsOneWidget);
      expect(find.text('2021'), findsOneWidget);
    });

    testWidgets('omits the release year separator when year is unavailable', (
      WidgetTester tester,
    ) async {
      await _pumpResultRow(tester, result: _resultWithoutReleaseDate);

      expect(find.text('Unknown Show'), findsOneWidget);
      expect(find.text('Show'), findsOneWidget);

      expect(find.text('•'), findsNothing);
    });

    testWidgets('shows the appropriate thumbnail placeholder', (
      WidgetTester tester,
    ) async {
      await _pumpResultRow(tester, result: _csiResult);

      expect(
        find.byKey(const ValueKey<String>('search-result-thumbnail-show-1431')),
        findsOneWidget,
      );

      expect(find.byIcon(Icons.tv_outlined), findsOneWidget);
    });

    testWidgets('calls onPressed when the row is tapped', (
      WidgetTester tester,
    ) async {
      int pressCount = 0;

      await _pumpResultRow(
        tester,
        result: _csiResult,
        onPressed: () {
          pressCount++;
        },
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('search-result-show-1431')),
      );

      await tester.pump();

      expect(pressCount, 1);
    });

    testWidgets('calls the secondary action callback', (
      WidgetTester tester,
    ) async {
      int actionPressCount = 0;

      await _pumpResultRow(
        tester,
        result: _csiResult,
        onActionPressed: () {
          actionPressCount++;
        },
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('search-result-action-show-1431')),
      );

      await tester.pump();

      expect(actionPressCount, 1);
    });

    testWidgets('disables the secondary action when no callback is provided', (
      WidgetTester tester,
    ) async {
      await _pumpResultRow(tester, result: _csiResult);

      final TextButton actionButton = tester.widget<TextButton>(
        find.byKey(const ValueKey<String>('search-result-action-show-1431')),
      );

      expect(actionButton.onPressed, isNull);
    });

    testWidgets(
      'disables the compact secondary action when no callback is provided',
      (WidgetTester tester) async {
        await _pumpResultRow(tester, result: _csiResult, compact: true);

        final IconButton actionButton = tester.widget<IconButton>(
          find.byKey(const ValueKey<String>('search-result-action-show-1431')),
        );

        expect(actionButton.onPressed, isNull);
      },
    );

    testWidgets('uses compact title layout when compact is enabled', (
      WidgetTester tester,
    ) async {
      await _pumpResultRow(tester, result: _csiResult, compact: true);

      final Text title = tester.widget<Text>(
        find.byKey(const ValueKey<String>('search-result-title-show-1431')),
      );

      expect(title.maxLines, 1);
      expect(title.overflow, TextOverflow.ellipsis);
    });

    testWidgets('allows two title lines in the regular layout', (
      WidgetTester tester,
    ) async {
      await _pumpResultRow(tester, result: _csiResult);

      final Text title = tester.widget<Text>(
        find.byKey(const ValueKey<String>('search-result-title-show-1431')),
      );

      expect(title.maxLines, 2);
      expect(title.overflow, TextOverflow.ellipsis);
    });
  });

  testWidgets('shows an add icon in compact mode when not added', (
    WidgetTester tester,
  ) async {
    await _pumpResultRow(tester, result: _csiResult, compact: true);

    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsNothing);
  });

  testWidgets('shows a check icon in compact mode when already added', (
    WidgetTester tester,
  ) async {
    await _pumpResultRow(
      tester,
      result: _csiResult,
      compact: true,
      actionAdded: true,
    );

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsNothing);
  });

  testWidgets('shows an action label in the regular desktop layout', (
    WidgetTester tester,
  ) async {
    await _pumpResultRow(tester, result: _duneResult);

    expect(find.text('Add to Watchlist'), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
  });

  testWidgets('shows Added in the regular layout when already added', (
    WidgetTester tester,
  ) async {
    await _pumpResultRow(tester, result: _duneResult, actionAdded: true);

    expect(find.text('Added'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('Add to Watchlist'), findsNothing);
  });

  testWidgets('shows a loading indicator in compact mode', (
    WidgetTester tester,
  ) async {
    await _pumpResultRow(
      tester,
      result: _csiResult,
      compact: true,
      actionLoading: true,
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsNothing);
    expect(find.byIcon(Icons.check_rounded), findsNothing);
  });

  testWidgets('shows a loading indicator in the regular layout', (
    WidgetTester tester,
  ) async {
    await _pumpResultRow(tester, result: _duneResult, actionLoading: true);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    final TextButton button = tester.widget<TextButton>(
      find.byKey(const ValueKey<String>('search-result-action-movie-438631')),
    );

    expect(button.onPressed, isNull);
  });

  testWidgets('does not invoke the action while loading', (
    WidgetTester tester,
  ) async {
    int actionCount = 0;

    await _pumpResultRow(
      tester,
      result: _csiResult,
      compact: true,
      actionLoading: true,
      onActionPressed: () {
        actionCount++;
      },
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('search-result-action-show-1431')),
    );

    await tester.pump();

    expect(actionCount, 0);
  });

  testWidgets('does not invoke the action when already added', (
    WidgetTester tester,
  ) async {
    int actionCount = 0;

    await _pumpResultRow(
      tester,
      result: _csiResult,
      compact: true,
      actionAdded: true,
      onActionPressed: () {
        actionCount++;
      },
    );

    final IconButton actionButton = tester.widget<IconButton>(
      find.byKey(const ValueKey<String>('search-result-action-show-1431')),
    );

    expect(actionButton.onPressed, isNull);
    expect(actionCount, 0);
  });

  testWidgets('shows the placeholder when the poster is missing', (
    WidgetTester tester,
  ) async {
    await _pumpResultRow(tester, result: _csiResult);

    expect(
      find.byKey(
        const ValueKey<String>('search-result-poster-placeholder-show-1431'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders an Image when a poster url exists', (
    WidgetTester tester,
  ) async {
    await _pumpResultRow(tester, result: _posterResult);

    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('keeps a 2:3 poster aspect ratio', (WidgetTester tester) async {
    await _pumpResultRow(tester, result: _csiResult);

    expect(find.byType(AspectRatio), findsOneWidget);

    final AspectRatio ratio = tester.widget<AspectRatio>(
      find.byType(AspectRatio),
    );

    expect(ratio.aspectRatio, equals(2 / 3));
  });
}

Future<void> _pumpResultRow(
  WidgetTester tester, {
  required SearchResult result,
  VoidCallback? onPressed,
  VoidCallback? onActionPressed,
  bool compact = false,
  bool actionLoading = false,
  bool actionAdded = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 600,
          child: SearchResultRow(
            result: result,
            compact: compact,
            actionLoading: actionLoading,
            actionAdded: actionAdded,
            onPressed: onPressed ?? () {},
            onActionPressed: onActionPressed,
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

const SearchResult _resultWithoutReleaseDate = SearchResult(
  mediaType: SearchMediaType.show,
  tmdbId: 999999,
  title: 'Unknown Show',
  originalTitle: 'Unknown Show',
  originalLanguage: 'en',
  genreIds: <int>[],
  popularity: 0,
  voteAverage: 0,
  voteCount: 0,
);

SearchResult _posterResult = SearchResult(
  mediaType: SearchMediaType.movie,
  tmdbId: 999,
  title: 'Poster Test',
  originalTitle: 'Poster Test',
  originalLanguage: 'en',
  genreIds: <int>[],
  popularity: 1,
  voteAverage: 1,
  voteCount: 1,
  posterUrl: Uri.parse('https://example.com/poster.jpg'),
);
