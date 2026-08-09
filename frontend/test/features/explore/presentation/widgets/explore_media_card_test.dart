import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_item.dart';
import 'package:sofawatch/features/explore/presentation/widgets/explore_media_card.dart';
import 'package:sofawatch/features/library/application/cubit/library_item_operation.dart';

void main() {
  group('ExploreMediaCard', () {
    testWidgets('shows title, type, year and rating for a Movie', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          ExploreMediaCard(
            item: _movie,
            operation: const LibraryItemOperation.idle(),
            onAdd: () {},
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('explore-media-title-movie-438631')),
        findsOneWidget,
      );

      expect(find.text('Dune'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('explore-media-type-movie-438631')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('explore-media-year-movie-438631')),
        findsOneWidget,
      );

      expect(find.text('2021'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('explore-media-rating-movie-438631')),
        findsOneWidget,
      );

      expect(find.text('7.8'), findsOneWidget);
    });

    testWidgets('shows title, type, year and rating for a Show', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          ExploreMediaCard(
            item: _show,
            operation: const LibraryItemOperation.idle(),
            onAdd: () {},
          ),
        ),
      );

      expect(find.text('Severance'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('explore-media-type-show-95396')),
        findsOneWidget,
      );

      expect(find.text('2022'), findsOneWidget);
      expect(find.text('8.4'), findsOneWidget);
    });

    testWidgets('shows Add action for a Movie not in Library', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          ExploreMediaCard(
            item: _movie,
            operation: const LibraryItemOperation.idle(),
            onAdd: () {},
          ),
        ),
      );

      expect(
        find.byKey(
          const ValueKey<String>('explore-media-library-add-movie-438631'),
        ),
        findsOneWidget,
      );

      expect(find.byTooltip('Add to Watchlist'), findsOneWidget);

      expect(
        find.byKey(
          const ValueKey<String>('explore-media-library-added-movie-438631'),
        ),
        findsNothing,
      );
    });

    testWidgets('shows Add action for a Show not in Library', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          ExploreMediaCard(
            item: _show,
            operation: const LibraryItemOperation.idle(),
            onAdd: () {},
          ),
        ),
      );

      expect(
        find.byKey(
          const ValueKey<String>('explore-media-library-add-show-95396'),
        ),
        findsOneWidget,
      );

      expect(find.byTooltip('Add to Library'), findsOneWidget);
    });

    testWidgets('uses initial inLibrary state for an already added Movie', (
      WidgetTester tester,
    ) async {
      final ExploreMediaItem addedMovie = ExploreMediaItem(
        mediaType: ExploreMediaType.movie,
        tmdbId: 438631,
        title: 'Dune',
        originalTitle: 'Dune',
        releaseDate: _movieReleaseDate,
        originalLanguage: 'en',
        genreIds: const <int>[878],
        popularity: 95,
        voteAverage: 7.8,
        voteCount: 13000,
        inLibrary: true,
      );

      int calls = 0;

      await tester.pumpWidget(
        _buildTestApp(
          ExploreMediaCard(
            item: addedMovie,
            operation: const LibraryItemOperation.idle(),
            onAdd: () {
              calls++;
            },
          ),
        ),
      );

      expect(
        find.byKey(
          const ValueKey<String>('explore-media-library-added-movie-438631'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('explore-media-library-add-movie-438631'),
        ),
        findsNothing,
      );

      expect(find.byTooltip('Already in Watchlist'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey<String>('explore-media-library-action-movie-438631'),
        ),
      );

      await tester.pump();

      expect(calls, 0);
    });

    testWidgets('uses local Library operation to show Added immediately', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          ExploreMediaCard(
            item: _movie,
            operation: LibraryItemOperation.added(),
          ),
        ),
      );

      expect(
        find.byKey(
          const ValueKey<String>('explore-media-library-added-movie-438631'),
        ),
        findsOneWidget,
      );

      expect(find.byTooltip('Already in Watchlist'), findsOneWidget);
    });

    testWidgets('shows spinner while Movie is being added', (
      WidgetTester tester,
    ) async {
      int calls = 0;

      await tester.pumpWidget(
        _buildTestApp(
          ExploreMediaCard(
            item: _movie,
            operation: const LibraryItemOperation.adding(),
            onAdd: () {
              calls++;
            },
          ),
        ),
      );

      expect(
        find.byKey(
          const ValueKey<String>('explore-media-library-loading-movie-438631'),
        ),
        findsOneWidget,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      expect(find.byTooltip('Adding to Watchlist'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey<String>('explore-media-library-action-movie-438631'),
        ),
      );

      await tester.pump();

      expect(calls, 0);
    });

    testWidgets('invokes Add callback once when idle action is tapped', (
      WidgetTester tester,
    ) async {
      int calls = 0;

      await tester.pumpWidget(
        _buildTestApp(
          ExploreMediaCard(
            item: _movie,
            operation: const LibraryItemOperation.idle(),
            onAdd: () {
              calls++;
            },
          ),
        ),
      );

      await tester.tap(
        find.byKey(
          const ValueKey<String>('explore-media-library-action-movie-438631'),
        ),
      );

      await tester.pump();

      expect(calls, 1);
    });

    testWidgets('exposes correct Added semantics for a Movie', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        _buildTestApp(
          ExploreMediaCard(
            item: _movie,
            operation: const LibraryItemOperation.added(),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Dune is in Watchlist'), findsOneWidget);

      semantics.dispose();
    });

    testWidgets('exposes correct Added semantics for a Show', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        _buildTestApp(
          ExploreMediaCard(
            item: _show,
            operation: const LibraryItemOperation.added(),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Severance is in Library'), findsOneWidget);

      semantics.dispose();
    });

    testWidgets('limits a long title to two lines with ellipsis', (
      WidgetTester tester,
    ) async {
      const ExploreMediaItem longTitleMovie = ExploreMediaItem(
        mediaType: ExploreMediaType.movie,
        tmdbId: 1,
        title:
            'This is a very long Movie title that should not occupy unlimited space',
        originalTitle:
            'This is a very long Movie title that should not occupy unlimited space',
        originalLanguage: 'en',
        genreIds: <int>[],
        popularity: 0,
        voteAverage: 0,
        voteCount: 0,
      );

      await tester.pumpWidget(
        _buildTestApp(
          const ExploreMediaCard(
            item: longTitleMovie,
            operation: LibraryItemOperation.idle(),
          ),
        ),
      );

      final Text title = tester.widget<Text>(
        find.byKey(const ValueKey<String>('explore-media-title-movie-1')),
      );

      expect(title.maxLines, 2);
      expect(title.overflow, TextOverflow.ellipsis);
    });

    testWidgets('shows placeholder when no poster is available', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          ExploreMediaCard(
            item: _movie,
            operation: LibraryItemOperation.idle(),
          ),
        ),
      );

      expect(
        find.byKey(
          const ValueKey<String>('explore-media-placeholder-movie-438631'),
        ),
        findsOneWidget,
      );
    });
  });
}

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

final DateTime _movieReleaseDate = DateTime(2021, 9, 15);

final DateTime _showReleaseDate = DateTime(2022, 2, 17);

final ExploreMediaItem _movie = ExploreMediaItem(
  mediaType: ExploreMediaType.movie,
  tmdbId: 438631,
  title: 'Dune',
  originalTitle: 'Dune',
  releaseDate: _movieReleaseDate,
  originalLanguage: 'en',
  genreIds: const <int>[878],
  popularity: 95,
  voteAverage: 7.8,
  voteCount: 13000,
);

final ExploreMediaItem _show = ExploreMediaItem(
  mediaType: ExploreMediaType.show,
  tmdbId: 95396,
  title: 'Severance',
  originalTitle: 'Severance',
  releaseDate: _showReleaseDate,
  originalLanguage: 'en',
  genreIds: const <int>[18],
  popularity: 120,
  voteAverage: 8.4,
  voteCount: 2100,
);
