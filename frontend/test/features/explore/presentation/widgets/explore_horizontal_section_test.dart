import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_item.dart';
import 'package:sofawatch/features/explore/presentation/widgets/explore_horizontal_section.dart';
import 'package:sofawatch/features/library/application/cubit/library_cubit.dart';
import 'package:sofawatch/features/library/domain/models/imported_library_media.dart';
import 'package:sofawatch/features/library/domain/models/library_entry.dart';
import 'package:sofawatch/features/library/domain/models/library_media_type.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/library/domain/repositories/library_repository.dart';

void main() {
  testWidgets('adds a Movie to Watchlist through LibraryCubit', (
    WidgetTester tester,
  ) async {
    final _FakeLibraryRepository repository = _FakeLibraryRepository();

    final LibraryCubit cubit = LibraryCubit(repository);

    await tester.pumpWidget(
      _buildTestApp(cubit: cubit, items: <ExploreMediaItem>[_movie]),
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('explore-media-library-action-movie-438631'),
      ),
    );

    await tester.pumpAndSettle();

    expect(repository.importedMovieTmdbIds, <int>[438631]);

    expect(repository.addedMovieIds, <String>['movie-uuid']);

    await cubit.close();
  });

  testWidgets('adds a Show to Library through LibraryCubit', (
    WidgetTester tester,
  ) async {
    final _FakeLibraryRepository repository = _FakeLibraryRepository();

    final LibraryCubit cubit = LibraryCubit(repository);

    await tester.pumpWidget(
      _buildTestApp(cubit: cubit, items: <ExploreMediaItem>[_show]),
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('explore-media-library-action-show-95396'),
      ),
    );

    await tester.pumpAndSettle();

    expect(repository.importedShowTmdbIds, <int>[95396]);

    expect(repository.addedShowIds, <String>['show-uuid']);

    await cubit.close();
  });

  testWidgets('shows spinner only for the item currently being added', (
    WidgetTester tester,
  ) async {
    final _FakeLibraryRepository repository = _FakeLibraryRepository();

    repository.pendingMovieImport = Completer<ImportedLibraryMedia>();

    final LibraryCubit cubit = LibraryCubit(repository);

    await tester.pumpWidget(
      _buildTestApp(cubit: cubit, items: <ExploreMediaItem>[_movie, _show]),
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('explore-media-library-action-movie-438631'),
      ),
    );

    await tester.pump();

    expect(
      find.byKey(
        const ValueKey<String>('explore-media-library-loading-movie-438631'),
      ),
      findsOneWidget,
    );

    expect(
      find.byKey(
        const ValueKey<String>('explore-media-library-add-show-95396'),
      ),
      findsOneWidget,
    );

    repository.pendingMovieImport!.complete(
      const ImportedLibraryMedia(
        id: 'movie-uuid',
        tmdbId: 438631,
        mediaType: LibraryMediaType.movie,
      ),
    );

    await tester.pumpAndSettle();

    await cubit.close();
  });

  testWidgets('keeps another card interactive while one item is adding', (
    WidgetTester tester,
  ) async {
    final _FakeLibraryRepository repository = _FakeLibraryRepository();

    repository.pendingMovieImport = Completer<ImportedLibraryMedia>();

    final LibraryCubit cubit = LibraryCubit(repository);

    await tester.pumpWidget(
      _buildTestApp(cubit: cubit, items: <ExploreMediaItem>[_movie, _show]),
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('explore-media-library-action-movie-438631'),
      ),
    );

    await tester.pump();

    await tester.tap(
      find.byKey(
        const ValueKey<String>('explore-media-library-action-show-95396'),
      ),
    );

    await tester.pump();

    expect(repository.importedMovieTmdbIds, <int>[438631]);

    expect(repository.importedShowTmdbIds, <int>[95396]);

    repository.pendingMovieImport!.complete(
      const ImportedLibraryMedia(
        id: 'movie-uuid',
        tmdbId: 438631,
        mediaType: LibraryMediaType.movie,
      ),
    );

    await tester.pumpAndSettle();

    await cubit.close();
  });

  testWidgets('does not start an operation for an item already in Library', (
    WidgetTester tester,
  ) async {
    final _FakeLibraryRepository repository = _FakeLibraryRepository();

    final LibraryCubit cubit = LibraryCubit(repository);

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

    await tester.pumpWidget(
      _buildTestApp(cubit: cubit, items: <ExploreMediaItem>[addedMovie]),
    );

    await tester.tap(
      find.byKey(
        const ValueKey<String>('explore-media-library-action-movie-438631'),
      ),
    );

    await tester.pump();

    expect(repository.importedMovieTmdbIds, isEmpty);

    expect(repository.addedMovieIds, isEmpty);

    await cubit.close();
  });

  testWidgets('does not start duplicate requests for the same item', (
    WidgetTester tester,
  ) async {
    final _FakeLibraryRepository repository = _FakeLibraryRepository();

    repository.pendingMovieImport = Completer<ImportedLibraryMedia>();

    final LibraryCubit cubit = LibraryCubit(repository);

    await tester.pumpWidget(
      _buildTestApp(cubit: cubit, items: <ExploreMediaItem>[_movie]),
    );

    final Finder action = find.byKey(
      const ValueKey<String>('explore-media-library-action-movie-438631'),
    );

    await tester.tap(action);
    await tester.pump();

    await tester.tap(action);
    await tester.pump();

    expect(repository.importedMovieTmdbIds, <int>[438631]);

    repository.pendingMovieImport!.complete(
      const ImportedLibraryMedia(
        id: 'movie-uuid',
        tmdbId: 438631,
        mediaType: LibraryMediaType.movie,
      ),
    );

    await tester.pumpAndSettle();

    await cubit.close();
  });
}

Widget _buildTestApp({
  required LibraryCubit cubit,
  required List<ExploreMediaItem> items,
}) {
  return MaterialApp(
    home: Scaffold(
      body: BlocProvider<LibraryCubit>.value(
        value: cubit,
        child: ExploreHorizontalSection(title: 'Test', items: items),
      ),
    ),
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

final class _FakeLibraryRepository implements LibraryRepository {
  final List<int> importedShowTmdbIds = <int>[];

  final List<int> importedMovieTmdbIds = <int>[];

  final List<String> addedShowIds = <String>[];

  final List<String> addedMovieIds = <String>[];

  Completer<ImportedLibraryMedia>? pendingShowImport;

  Completer<ImportedLibraryMedia>? pendingMovieImport;

  @override
  Future<ImportedLibraryMedia> importShowByTmdbId(int tmdbId) async {
    importedShowTmdbIds.add(tmdbId);

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
  Future<ImportedLibraryMedia> importMovieByTmdbId(int tmdbId) async {
    importedMovieTmdbIds.add(tmdbId);

    final Completer<ImportedLibraryMedia>? pendingImport = pendingMovieImport;

    if (pendingImport != null) {
      return pendingImport.future;
    }

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
  Future<void> removeShow(String showId) async {}

  @override
  Future<void> removeMovie(String movieId) async {}

  @override
  Future<LibraryEntry> updateShowStatus(
    String showId,
    LibraryStatus status,
  ) async {
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
    final DateTime now = DateTime.utc(2026, 8, 9);

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
