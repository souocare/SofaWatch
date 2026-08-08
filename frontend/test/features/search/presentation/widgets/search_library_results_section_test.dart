import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/library/application/cubit/library_cubit.dart';
import 'package:sofawatch/features/library/domain/models/imported_library_media.dart';
import 'package:sofawatch/features/library/domain/models/library_entry.dart';
import 'package:sofawatch/features/library/domain/models/library_media_type.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/library/domain/repositories/library_repository.dart';
import 'package:sofawatch/features/search/domain/entities/search_media_type.dart';
import 'package:sofawatch/features/search/domain/entities/search_result.dart';
import 'package:sofawatch/features/search/presentation/widgets/search_library_results_section.dart';

void main() {
  group('SearchLibraryResultsSection', () {
    testWidgets('adds a Show to the Library and keeps the result visible', (
      WidgetTester tester,
    ) async {
      final _FakeLibraryRepository repository = _FakeLibraryRepository();

      await _pumpWidget(
        tester,
        repository: repository,
        results: const <SearchResult>[_showResult],
      );

      final Finder row = find.byKey(
        const ValueKey<String>('search-result-show-95396'),
      );

      final Finder action = find.byKey(
        const ValueKey<String>('search-result-action-show-95396'),
      );

      expect(row, findsOneWidget);
      expect(action, findsOneWidget);

      await tester.tap(action);

      await tester.pump();

      expect(repository.importedShowTmdbIds, <int>[95396]);

      await tester.pumpAndSettle();

      expect(repository.addedShowIds, <String>['show-uuid']);

      expect(
        row,
        findsOneWidget,
        reason: 'Adding a Show must not remove the Search result.',
      );

      expect(find.text('Added'), findsOneWidget);
    });

    testWidgets(
      'shows an existing Library Show as Added without making a request',
      (WidgetTester tester) async {
        final _FakeLibraryRepository repository = _FakeLibraryRepository();

        await _pumpWidget(
          tester,
          repository: repository,
          results: const <SearchResult>[_addedShowResult],
        );

        expect(find.text('Added'), findsOneWidget);

        final Finder action = find.byKey(
          const ValueKey<String>('search-result-action-show-95396'),
        );

        final TextButton button = tester.widget<TextButton>(action);

        expect(button.onPressed, isNull);

        expect(repository.importedShowTmdbIds, isEmpty);

        expect(repository.addedShowIds, isEmpty);
      },
    );

    testWidgets('does not enable the Movie Library action yet', (
      WidgetTester tester,
    ) async {
      final _FakeLibraryRepository repository = _FakeLibraryRepository();

      await _pumpWidget(
        tester,
        repository: repository,
        results: const <SearchResult>[_movieResult],
      );

      final Finder action = find.byKey(
        const ValueKey<String>('search-result-action-movie-438631'),
      );

      final TextButton button = tester.widget<TextButton>(action);

      expect(button.onPressed, isNull);

      expect(repository.importedMovieTmdbIds, isEmpty);
    });
  });
}

Future<void> _pumpWidget(
  WidgetTester tester, {
  required _FakeLibraryRepository repository,
  required List<SearchResult> results,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: BlocProvider<LibraryCubit>(
          create: (_) => LibraryCubit(repository),
          child: SearchLibraryResultsSection(
            results: results,
            scrollable: false,
            onResultPressed: (_) {},
          ),
        ),
      ),
    ),
  );

  await tester.pump();
}

const SearchResult _showResult = SearchResult(
  mediaType: SearchMediaType.show,
  tmdbId: 95396,
  title: 'Severance',
  originalTitle: 'Severance',
  originalLanguage: 'en',
  genreIds: <int>[18],
  popularity: 100,
  voteAverage: 8.4,
  voteCount: 100,
);

const SearchResult _addedShowResult = SearchResult(
  mediaType: SearchMediaType.show,
  tmdbId: 95396,
  title: 'Severance',
  originalTitle: 'Severance',
  originalLanguage: 'en',
  genreIds: <int>[18],
  popularity: 100,
  voteAverage: 8.4,
  voteCount: 100,
  inLibrary: true,
);

const SearchResult _movieResult = SearchResult(
  mediaType: SearchMediaType.movie,
  tmdbId: 438631,
  title: 'Dune',
  originalTitle: 'Dune',
  originalLanguage: 'en',
  genreIds: <int>[878],
  popularity: 100,
  voteAverage: 7.8,
  voteCount: 100,
);

final class _FakeLibraryRepository implements LibraryRepository {
  final List<int> importedShowTmdbIds = <int>[];
  final List<int> importedMovieTmdbIds = <int>[];

  final List<String> addedShowIds = <String>[];
  final List<String> addedMovieIds = <String>[];

  @override
  Future<ImportedLibraryMedia> importShowByTmdbId(int tmdbId) async {
    importedShowTmdbIds.add(tmdbId);

    return ImportedLibraryMedia(
      id: 'show-uuid',
      tmdbId: tmdbId,
      mediaType: LibraryMediaType.show,
    );
  }

  @override
  Future<ImportedLibraryMedia> importMovieByTmdbId(int tmdbId) async {
    importedMovieTmdbIds.add(tmdbId);

    return ImportedLibraryMedia(
      id: 'movie-uuid',
      tmdbId: tmdbId,
      mediaType: LibraryMediaType.movie,
    );
  }

  @override
  Future<LibraryEntry> addShow(String showId) async {
    addedShowIds.add(showId);

    return _entry(mediaId: showId, mediaType: LibraryMediaType.show);
  }

  @override
  Future<LibraryEntry> addMovie(String movieId) async {
    addedMovieIds.add(movieId);

    return _entry(mediaId: movieId, mediaType: LibraryMediaType.movie);
  }

  LibraryEntry _entry({
    required String mediaId,
    required LibraryMediaType mediaType,
  }) {
    final DateTime now = DateTime.utc(2026, 8, 8);

    return LibraryEntry(
      id: 'entry-uuid',
      mediaId: mediaId,
      mediaType: mediaType,
      status: LibraryStatus.planning,
      createdAt: now,
      updatedAt: now,
    );
  }
}
