import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
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

    testWidgets('adds a Movie to the Watchlist and keeps the result visible', (
      WidgetTester tester,
    ) async {
      final _FakeLibraryRepository repository = _FakeLibraryRepository();

      await _pumpWidget(
        tester,
        repository: repository,
        results: const <SearchResult>[_movieResult],
      );

      final Finder row = find.byKey(
        const ValueKey<String>('search-result-movie-438631'),
      );

      final Finder action = find.byKey(
        const ValueKey<String>('search-result-action-movie-438631'),
      );

      expect(row, findsOneWidget);
      expect(action, findsOneWidget);

      await tester.tap(action);

      await tester.pump();

      expect(repository.importedMovieTmdbIds, <int>[438631]);

      await tester.pumpAndSettle();

      expect(repository.addedMovieIds, <String>['movie-uuid']);

      expect(
        row,
        findsOneWidget,
        reason: 'Adding a Movie must not remove the Search result.',
      );

      expect(find.text('Added'), findsOneWidget);
    });
  });
  testWidgets(
    'shows an existing Watchlist Movie as Added without making a request',
    (WidgetTester tester) async {
      final _FakeLibraryRepository repository = _FakeLibraryRepository();

      await _pumpWidget(
        tester,
        repository: repository,
        results: const <SearchResult>[_addedMovieResult],
      );

      expect(find.text('Added'), findsOneWidget);

      final Finder action = find.byKey(
        const ValueKey<String>('search-result-action-movie-438631'),
      );

      final TextButton button = tester.widget<TextButton>(action);

      expect(button.onPressed, isNull);

      expect(repository.importedMovieTmdbIds, isEmpty);

      expect(repository.addedMovieIds, isEmpty);
    },
  );

  testWidgets('disables the action and shows a spinner while adding', (
    WidgetTester tester,
  ) async {
    final Completer<ImportedLibraryMedia> completer =
        Completer<ImportedLibraryMedia>();

    final _FakeLibraryRepository repository = _FakeLibraryRepository()
      ..pendingShowImport = completer;

    await _pumpWidget(
      tester,
      repository: repository,
      results: const <SearchResult>[_showResult],
    );

    final Finder action = find.byKey(
      const ValueKey<String>('search-result-action-show-95396'),
    );

    await tester.tap(action);
    await tester.pump();

    expect(
      find.byKey(
        const ValueKey<String>('search-result-action-loading-show-95396'),
      ),
      findsOneWidget,
    );

    final TextButton button = tester.widget<TextButton>(action);

    expect(button.onPressed, isNull);

    completer.complete(
      const ImportedLibraryMedia(
        id: 'show-uuid',
        tmdbId: 95396,
        mediaType: LibraryMediaType.show,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Added'), findsOneWidget);
  });

  testWidgets(
    'keeps other result actions interactive while one item is adding',
    (WidgetTester tester) async {
      final Completer<ImportedLibraryMedia> completer =
          Completer<ImportedLibraryMedia>();

      final _FakeLibraryRepository repository = _FakeLibraryRepository()
        ..pendingShowImport = completer;

      await _pumpWidget(
        tester,
        repository: repository,
        results: const <SearchResult>[_showResult, _movieResult],
      );

      final Finder showAction = find.byKey(
        const ValueKey<String>('search-result-action-show-95396'),
      );

      final Finder movieAction = find.byKey(
        const ValueKey<String>('search-result-action-movie-438631'),
      );

      await tester.tap(showAction);
      await tester.pump();

      final TextButton showButton = tester.widget<TextButton>(showAction);

      final TextButton movieButton = tester.widget<TextButton>(movieAction);

      expect(showButton.onPressed, isNull);

      expect(movieButton.onPressed, isNotNull);

      await tester.tap(movieAction);

      await tester.pump();
      await tester.pump();

      expect(repository.importedMovieTmdbIds, <int>[438631]);

      expect(repository.addedMovieIds, <String>['movie-uuid']);

      completer.complete(
        const ImportedLibraryMedia(
          id: 'show-uuid',
          tmdbId: 95396,
          mediaType: LibraryMediaType.show,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Added'), findsNWidgets(2));
    },
  );

  testWidgets('exposes the correct Added tooltip and semantics for a Show', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semanticsHandle = tester.ensureSemantics();

    final _FakeLibraryRepository repository = _FakeLibraryRepository();

    await _pumpWidget(
      tester,
      repository: repository,
      results: const <SearchResult>[_addedShowResult],
    );

    expect(find.bySemanticsLabel('Severance is in Library'), findsOneWidget);

    expect(find.byTooltip('Added to Library'), findsOneWidget);

    expect(
      find.byKey(
        const ValueKey<String>('search-result-action-added-show-95396'),
      ),
      findsOneWidget,
    );

    final TextButton button = tester.widget<TextButton>(
      find.byKey(const ValueKey<String>('search-result-action-show-95396')),
    );

    expect(button.onPressed, isNull);

    semanticsHandle.dispose();
  });

  testWidgets('exposes the correct Added tooltip and semantics for a Movie', (
    WidgetTester tester,
  ) async {
    final SemanticsHandle semanticsHandle = tester.ensureSemantics();

    final _FakeLibraryRepository repository = _FakeLibraryRepository();

    await _pumpWidget(
      tester,
      repository: repository,
      results: const <SearchResult>[_addedMovieResult],
    );

    expect(find.bySemanticsLabel('Dune is in Watchlist'), findsOneWidget);

    expect(find.byTooltip('Added to Watchlist'), findsOneWidget);

    expect(
      find.byKey(
        const ValueKey<String>('search-result-action-added-movie-438631'),
      ),
      findsOneWidget,
    );

    semanticsHandle.dispose();
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

const SearchResult _addedMovieResult = SearchResult(
  mediaType: SearchMediaType.movie,
  tmdbId: 438631,
  title: 'Dune',
  originalTitle: 'Dune',
  originalLanguage: 'en',
  genreIds: <int>[878],
  popularity: 100,
  voteAverage: 7.8,
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
  Completer<ImportedLibraryMedia>? pendingShowImport;

  int showImportFailuresRemaining = 0;

  final List<int> importedShowTmdbIds = <int>[];
  final List<int> importedMovieTmdbIds = <int>[];

  final List<String> addedShowIds = <String>[];
  final List<String> addedMovieIds = <String>[];

  final List<String> removedShowIds = <String>[];
  final List<String> removedMovieIds = <String>[];

  final List<({String showId, LibraryStatus status})> updatedShowStatuses =
      <({String showId, LibraryStatus status})>[];

  @override
  Future<ImportedLibraryMedia> importShowByTmdbId(int tmdbId) async {
    importedShowTmdbIds.add(tmdbId);

    if (showImportFailuresRemaining > 0) {
      showImportFailuresRemaining--;

      throw const AppException.connection();
    }

    final Completer<ImportedLibraryMedia>? pendingImport = pendingShowImport;

    if (pendingImport != null) {
      return pendingImport.future;
    }

    return ImportedLibraryMedia(
      id: 'show-uuid',
      tmdbId: tmdbId,
      mediaType: LibraryMediaType.show,
    );
  }

  @override
  Future<LibraryEntry?> getMovieEntry(String movieId) async {
    return null;
  }

  @override
  Future<LibraryEntry> updateMovieStatus(
    String movieId,
    LibraryStatus status,
  ) async {
    return LibraryEntry(
      id: 'entry-uuid',
      mediaId: movieId,
      mediaType: LibraryMediaType.movie,
      status: status,
      createdAt: DateTime.utc(2026, 8, 10),
      updatedAt: DateTime.utc(2026, 8, 10),
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

  @override
  Future<void> removeShow(String showId) async {
    removedShowIds.add(showId);
  }

  @override
  Future<void> removeMovie(String movieId) async {
    removedMovieIds.add(movieId);
  }

  @override
  Future<LibraryEntry> updateShowStatus(
    String showId,
    LibraryStatus status,
  ) async {
    updatedShowStatuses.add((showId: showId, status: status));

    return _entry(
      mediaId: showId,
      mediaType: LibraryMediaType.show,
      status: status,
    );
  }

  LibraryEntry _entry({
    required String mediaId,
    required LibraryMediaType mediaType,
    LibraryStatus status = LibraryStatus.planning,
  }) {
    final DateTime now = DateTime.utc(2026, 8, 8);

    return LibraryEntry(
      id: 'entry-uuid',
      mediaId: mediaId,
      mediaType: mediaType,
      status: status,
      createdAt: now,
      updatedAt: now,
    );
  }
}
