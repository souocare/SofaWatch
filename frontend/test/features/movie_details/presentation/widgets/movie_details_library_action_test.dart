import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/application/cubit/library_cubit.dart';
import 'package:sofawatch/features/library/application/cubit/library_item_operation.dart';
import 'package:sofawatch/features/library/domain/models/imported_library_media.dart';
import 'package:sofawatch/features/library/domain/models/library_entry.dart';
import 'package:sofawatch/features/library/domain/models/library_media_key.dart';
import 'package:sofawatch/features/library/domain/models/library_media_type.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/library/domain/repositories/library_repository.dart';
import 'package:sofawatch/features/movie_details/presentation/widgets/movie_details_library_action.dart';
import 'package:sofawatch/features/library/domain/models/library_preview.dart';

void main() {
  group('MovieDetailsLibraryAction', () {
    testWidgets('shows Add to Watchlist initially', (
      WidgetTester tester,
    ) async {
      final _FakeLibraryRepository repository = _FakeLibraryRepository();

      final LibraryCubit cubit = LibraryCubit(repository);

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      expect(
        find.byKey(const ValueKey<String>('movie-details-library-add')),
        findsOneWidget,
      );

      expect(find.text('Add to Watchlist'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('movie-details-library-adding')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('movie-details-library-added')),
        findsNothing,
      );

      await cubit.close();
    });

    testWidgets('imports and adds Movie to Library', (
      WidgetTester tester,
    ) async {
      final _FakeLibraryRepository repository = _FakeLibraryRepository();

      final LibraryCubit cubit = LibraryCubit(repository);

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.tap(
        find.byKey(const ValueKey<String>('movie-details-library-add')),
      );

      await tester.pumpAndSettle();

      expect(repository.importMovieCalls, 1);

      expect(repository.requestedTmdbIds, <int>[438631]);

      expect(repository.addMovieCalls, 1);

      expect(repository.requestedMovieIds, <String>['movie-local-uuid']);

      expect(
        find.byKey(const ValueKey<String>('movie-details-library-added')),
        findsOneWidget,
      );

      expect(find.text('In Watchlist'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('shows loading state while Movie is being added', (
      WidgetTester tester,
    ) async {
      final _ControlledLibraryRepository repository =
          _ControlledLibraryRepository();

      final LibraryCubit cubit = LibraryCubit(repository);

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.tap(
        find.byKey(const ValueKey<String>('movie-details-library-add')),
      );

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('movie-details-library-adding')),
        findsOneWidget,
      );

      expect(find.text('Adding…'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('movie-details-library-add')),
        findsNothing,
      );

      repository.completeImport();

      await tester.pump();

      repository.completeAdd();

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('movie-details-library-added')),
        findsOneWidget,
      );

      await cubit.close();
    });

    testWidgets('does not repeat add after Movie was added', (
      WidgetTester tester,
    ) async {
      final _FakeLibraryRepository repository = _FakeLibraryRepository();

      final LibraryCubit cubit = LibraryCubit(repository);

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.tap(
        find.byKey(const ValueKey<String>('movie-details-library-add')),
      );

      await tester.pumpAndSettle();

      expect(repository.importMovieCalls, 1);

      expect(repository.addMovieCalls, 1);

      expect(
        find.byKey(const ValueKey<String>('movie-details-library-added')),
        findsOneWidget,
      );

      await cubit.addToLibrary(
        const LibraryMediaKey(
          mediaType: LibraryMediaType.movie,
          tmdbId: 438631,
        ),
      );

      expect(repository.importMovieCalls, 1);

      expect(repository.addMovieCalls, 1);

      await cubit.close();
    });

    testWidgets('shows failure message when adding Movie fails', (
      WidgetTester tester,
    ) async {
      final _FakeLibraryRepository repository = _FakeLibraryRepository(
        importError: const AppException.connection(),
      );

      final LibraryCubit cubit = LibraryCubit(repository);

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.tap(
        find.byKey(const ValueKey<String>('movie-details-library-add')),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('movie-details-library-failure')),
        findsOneWidget,
      );

      expect(find.text('Retry'), findsOneWidget);

      expect(repository.importMovieCalls, 1);

      expect(repository.addMovieCalls, 0);

      await cubit.close();
    });

    testWidgets('Retry repeats the failed Movie add operation', (
      WidgetTester tester,
    ) async {
      final _RetryLibraryRepository repository = _RetryLibraryRepository();

      final LibraryCubit cubit = LibraryCubit(repository);

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.tap(
        find.byKey(const ValueKey<String>('movie-details-library-add')),
      );

      await tester.pumpAndSettle();

      expect(repository.importMovieCalls, 1);

      expect(
        find.byKey(const ValueKey<String>('movie-details-library-failure')),
        findsOneWidget,
      );

      await tester.tap(find.text('Retry'));

      await tester.pumpAndSettle();

      expect(repository.importMovieCalls, 2);

      expect(repository.addMovieCalls, 1);

      expect(
        find.byKey(const ValueKey<String>('movie-details-library-added')),
        findsOneWidget,
      );

      await cubit.close();
    });

    testWidgets('removes Movie from Watchlist', (WidgetTester tester) async {
      final _FakeLibraryRepository repository = _FakeLibraryRepository();

      final LibraryCubit cubit = LibraryCubit(repository);

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.tap(
        find.byKey(const ValueKey<String>('movie-details-library-add')),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('movie-details-library-added')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('movie-details-library-added')),
      );

      await tester.pumpAndSettle();

      expect(repository.removeMovieCalls, 1);

      expect(repository.requestedRemovedMovieIds, <String>['movie-local-uuid']);

      expect(
        find.byKey(const ValueKey<String>('movie-details-library-add')),
        findsOneWidget,
      );

      expect(find.text('Add to Watchlist'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('shows removing state while Movie is being removed', (
      WidgetTester tester,
    ) async {
      final _ControlledRemoveLibraryRepository repository =
          _ControlledRemoveLibraryRepository();

      final LibraryCubit cubit = LibraryCubit(repository);

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      // Add Movie first.
      await tester.tap(
        find.byKey(const ValueKey<String>('movie-details-library-add')),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('movie-details-library-added')),
        findsOneWidget,
      );

      // Remove through the actual UI.
      await tester.tap(
        find.byKey(const ValueKey<String>('movie-details-library-added')),
      );

      // Do NOT use pumpAndSettle here because the remove request
      // is intentionally pending.
      await tester.pump();

      const LibraryMediaKey key = LibraryMediaKey(
        mediaType: LibraryMediaType.movie,
        tmdbId: 438631,
      );

      expect(cubit.state.operationFor(key).isRemoving, isTrue);

      expect(
        find.byKey(const ValueKey<String>('movie-details-library-removing')),
        findsOneWidget,
      );

      expect(find.text('Removing…'), findsOneWidget);

      repository.completeRemove();

      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        cubit.state.operationFor(key).status,
        LibraryItemOperationStatus.idle,
      );

      expect(
        find.byKey(const ValueKey<String>('movie-details-library-add')),
        findsOneWidget,
      );

      await cubit.close();
    });

    testWidgets('shows failure when removing Movie fails', (
      WidgetTester tester,
    ) async {
      final _FakeLibraryRepository repository = _FakeLibraryRepository(
        removeError: const AppException.connection(),
      );

      final LibraryCubit cubit = LibraryCubit(repository);

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.tap(
        find.byKey(const ValueKey<String>('movie-details-library-add')),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('movie-details-library-added')),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('movie-details-library-failure')),
        findsOneWidget,
      );

      expect(find.text('Retry'), findsOneWidget);

      expect(repository.removeMovieCalls, 1);

      await cubit.close();
    });

    testWidgets('Retry repeats failed Movie removal', (
      WidgetTester tester,
    ) async {
      final _RetryRemoveLibraryRepository repository =
          _RetryRemoveLibraryRepository();

      final LibraryCubit cubit = LibraryCubit(repository);

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.tap(
        find.byKey(const ValueKey<String>('movie-details-library-add')),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('movie-details-library-added')),
      );

      await tester.pumpAndSettle();

      expect(repository.removeMovieCalls, 1);

      expect(
        find.byKey(const ValueKey<String>('movie-details-library-failure')),
        findsOneWidget,
      );

      await tester.tap(find.text('Retry'));

      await tester.pumpAndSettle();

      expect(repository.removeMovieCalls, 2);

      expect(
        find.byKey(const ValueKey<String>('movie-details-library-add')),
        findsOneWidget,
      );

      await cubit.close();
    });

    testWidgets('shows current Watchlist state when Movie is already added', (
      WidgetTester tester,
    ) async {
      final _FakeLibraryRepository repository = _FakeLibraryRepository(
        movieEntry: _libraryEntry,
      );

      final LibraryCubit cubit = LibraryCubit(repository);

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await cubit.loadMovieState(
        const LibraryMediaKey(
          mediaType: LibraryMediaType.movie,
          tmdbId: 438631,
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('movie-details-library-added')),
        findsOneWidget,
      );

      expect(find.text('In Watchlist'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('movie-details-library-add')),
        findsNothing,
      );

      await cubit.close();
    });

    testWidgets('shows Add to Watchlist when Movie is not in the library', (
      WidgetTester tester,
    ) async {
      final _FakeLibraryRepository repository = _FakeLibraryRepository();

      final LibraryCubit cubit = LibraryCubit(repository);

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await cubit.loadMovieState(
        const LibraryMediaKey(
          mediaType: LibraryMediaType.movie,
          tmdbId: 438631,
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('movie-details-library-add')),
        findsOneWidget,
      );

      expect(find.text('Add to Watchlist'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('movie-details-library-added')),
        findsNothing,
      );

      await cubit.close();
    });

    testWidgets('shows Mark as watched for an unwatched Movie', (
      WidgetTester tester,
    ) async {
      final _FakeLibraryRepository repository = _FakeLibraryRepository(
        movieEntry: _libraryEntry,
      );

      final LibraryCubit cubit = LibraryCubit(repository);

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await cubit.loadMovieState(
        const LibraryMediaKey(
          mediaType: LibraryMediaType.movie,
          tmdbId: 438631,
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('movie-details-mark-watched')),
        findsOneWidget,
      );

      expect(find.text('Mark as watched'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('movie-details-mark-unwatched')),
        findsNothing,
      );

      await cubit.close();
    });

    testWidgets('marks Movie as watched', (WidgetTester tester) async {
      final _FakeLibraryRepository repository = _FakeLibraryRepository(
        movieEntry: _libraryEntry,
      );

      final LibraryCubit cubit = LibraryCubit(repository);

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await cubit.loadMovieState(
        const LibraryMediaKey(
          mediaType: LibraryMediaType.movie,
          tmdbId: 438631,
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('movie-details-mark-watched')),
      );

      await tester.pumpAndSettle();

      expect(repository.updateMovieStatusCalls, 1);

      expect(
        repository.updatedMovieStatuses,
        <({String movieId, LibraryStatus status})>[
          (movieId: 'movie-local-uuid', status: LibraryStatus.completed),
        ],
      );

      expect(
        find.byKey(const ValueKey<String>('movie-details-mark-unwatched')),
        findsOneWidget,
      );

      expect(find.text('Mark as unwatched'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('marks Movie as unwatched', (WidgetTester tester) async {
      final _FakeLibraryRepository repository = _FakeLibraryRepository(
        movieEntry: _completedLibraryEntry,
      );

      final LibraryCubit cubit = LibraryCubit(repository);

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await cubit.loadMovieState(
        const LibraryMediaKey(
          mediaType: LibraryMediaType.movie,
          tmdbId: 438631,
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('movie-details-mark-unwatched')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('movie-details-mark-unwatched')),
      );

      await tester.pumpAndSettle();

      expect(repository.updateMovieStatusCalls, 1);

      expect(
        repository.updatedMovieStatuses,
        <({String movieId, LibraryStatus status})>[
          (movieId: 'movie-local-uuid', status: LibraryStatus.planning),
        ],
      );

      expect(
        find.byKey(const ValueKey<String>('movie-details-mark-watched')),
        findsOneWidget,
      );

      await cubit.close();
    });

    testWidgets('shows updating state while Movie is being marked as watched', (
      WidgetTester tester,
    ) async {
      final _ControlledUpdateLibraryRepository repository =
          _ControlledUpdateLibraryRepository(movieEntry: _libraryEntry);

      final LibraryCubit cubit = LibraryCubit(repository);

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await cubit.loadMovieState(
        const LibraryMediaKey(
          mediaType: LibraryMediaType.movie,
          tmdbId: 438631,
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('movie-details-mark-watched')),
      );

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('movie-details-library-updating')),
        findsOneWidget,
      );

      expect(find.text('Marking as watched…'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('movie-details-library-added')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('movie-details-mark-watched')),
        findsNothing,
      );

      repository.completeUpdate(status: LibraryStatus.completed);

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('movie-details-mark-unwatched')),
        findsOneWidget,
      );

      await cubit.close();
    });

    testWidgets('keeps Movie in Watchlist when watched update fails', (
      WidgetTester tester,
    ) async {
      final _FakeLibraryRepository repository = _FakeLibraryRepository(
        movieEntry: _libraryEntry,
        updateStatusError: const AppException.connection(),
      );

      final LibraryCubit cubit = LibraryCubit(repository);

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await cubit.loadMovieState(
        const LibraryMediaKey(
          mediaType: LibraryMediaType.movie,
          tmdbId: 438631,
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('movie-details-mark-watched')),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('movie-details-library-failure')),
        findsOneWidget,
      );

      expect(find.text('Retry'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('movie-details-library-added')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('movie-details-library-add')),
        findsNothing,
      );

      await cubit.close();
    });

    testWidgets('Retry repeats failed Movie watched update', (
      WidgetTester tester,
    ) async {
      final _RetryUpdateLibraryRepository repository =
          _RetryUpdateLibraryRepository(movieEntry: _libraryEntry);

      final LibraryCubit cubit = LibraryCubit(repository);

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await cubit.loadMovieState(
        const LibraryMediaKey(
          mediaType: LibraryMediaType.movie,
          tmdbId: 438631,
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('movie-details-mark-watched')),
      );

      await tester.pumpAndSettle();

      expect(repository.updateMovieStatusCalls, 1);

      expect(
        find.byKey(const ValueKey<String>('movie-details-library-failure')),
        findsOneWidget,
      );

      await tester.tap(find.text('Retry'));

      await tester.pumpAndSettle();

      expect(repository.updateMovieStatusCalls, 2);

      expect(
        find.byKey(const ValueKey<String>('movie-details-mark-unwatched')),
        findsOneWidget,
      );

      expect(find.text('Mark as unwatched'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('shows watched date for a completed Movie', (
      WidgetTester tester,
    ) async {
      final _FakeLibraryRepository repository = _FakeLibraryRepository(
        movieEntry: _completedLibraryEntry,
      );

      final LibraryCubit cubit = LibraryCubit(repository);

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await cubit.loadMovieState(
        const LibraryMediaKey(
          mediaType: LibraryMediaType.movie,
          tmdbId: 438631,
        ),
      );

      await tester.pumpAndSettle();

      final Finder watchedDate = find.byKey(
        const ValueKey<String>('movie-details-watched-date'),
      );

      expect(watchedDate, findsOneWidget);

      final BuildContext context = tester.element(watchedDate);

      final String expectedDate = MaterialLocalizations.of(
        context,
      ).formatMediumDate(_completedLibraryEntry.completedAt!.toLocal());

      expect(
        find.descendant(
          of: watchedDate,
          matching: find.text('Watched $expectedDate'),
        ),
        findsOneWidget,
      );

      await cubit.close();
    });

    testWidgets('hides watched date for an unwatched Movie', (
      WidgetTester tester,
    ) async {
      final _FakeLibraryRepository repository = _FakeLibraryRepository(
        movieEntry: _libraryEntry,
      );

      final LibraryCubit cubit = LibraryCubit(repository);

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await cubit.loadMovieState(
        const LibraryMediaKey(
          mediaType: LibraryMediaType.movie,
          tmdbId: 438631,
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('movie-details-watched-date')),
        findsNothing,
      );

      await cubit.close();
    });

    testWidgets('does not allow marking an upcoming Movie as watched', (
      WidgetTester tester,
    ) async {
      final _FakeLibraryRepository repository = _FakeLibraryRepository(
        movieEntry: _libraryEntry,
      );

      final LibraryCubit cubit = LibraryCubit(repository);

      await tester.pumpWidget(_buildTestApp(cubit: cubit, isUpcoming: true));

      await cubit.loadMovieState(
        const LibraryMediaKey(
          mediaType: LibraryMediaType.movie,
          tmdbId: 438631,
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('movie-details-library-added')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('movie-details-mark-watched')),
        findsNothing,
      );

      await cubit.close();
    });
  });
}

Widget _buildTestApp({required LibraryCubit cubit, bool isUpcoming = false}) {
  return MaterialApp(
    home: Scaffold(
      body: BlocProvider<LibraryCubit>.value(
        value: cubit,
        child: MovieDetailsLibraryAction(
          tmdbId: 438631,
          isUpcoming: isUpcoming,
        ),
      ),
    ),
  );
}

const ImportedLibraryMedia _importedMovie = ImportedLibraryMedia(
  id: 'movie-local-uuid',
  tmdbId: 438631,
  mediaType: LibraryMediaType.movie,
);

final LibraryEntry _libraryEntry = LibraryEntry(
  id: 'library-entry-uuid',
  mediaId: 'movie-local-uuid',
  mediaType: LibraryMediaType.movie,
  status: LibraryStatus.planning,
  createdAt: DateTime(2026, 8, 10),
  updatedAt: DateTime(2026, 8, 10),
);

final LibraryEntry _completedLibraryEntry = LibraryEntry(
  id: 'library-entry-uuid',
  mediaId: 'movie-local-uuid',
  mediaType: LibraryMediaType.movie,
  status: LibraryStatus.completed,
  completedAt: DateTime.utc(2026, 8, 10, 20),
  createdAt: DateTime.utc(2026, 8, 8),
  updatedAt: DateTime.utc(2026, 8, 10, 20),
);

class _FakeLibraryRepository implements LibraryRepository {
  _FakeLibraryRepository({
    this.importError,
    this.removeError,
    this.updateStatusError,
    this.movieEntry,
  }) : addError = null;

  final AppException? removeError;

  int removeMovieCalls = 0;
  final LibraryEntry? movieEntry;

  final List<String> requestedRemovedMovieIds = <String>[];

  final AppException? importError;
  final AppException? addError;

  int importMovieCalls = 0;
  int addMovieCalls = 0;

  final List<int> requestedTmdbIds = <int>[];
  final List<String> requestedMovieIds = <String>[];
  final AppException? updateStatusError;

  int updateMovieStatusCalls = 0;

  final List<({String movieId, LibraryStatus status})> updatedMovieStatuses =
      <({String movieId, LibraryStatus status})>[];

  @override
  Future<ImportedLibraryMedia> importMovieByTmdbId(int tmdbId) async {
    importMovieCalls++;

    requestedTmdbIds.add(tmdbId);

    final AppException? error = importError;

    if (error != null) {
      throw error;
    }

    return _importedMovie;
  }

  @override
  Future<LibraryEntry?> getMovieEntry(String movieId) async {
    return movieEntry;
  }

  @override
  Future<LibraryEntry?> getShowEntry(String showId) async {
    return null;
  }

  @override
  Future<LibraryEntry> updateMovieStatus(
    String movieId,
    LibraryStatus status,
  ) async {
    updateMovieStatusCalls++;

    updatedMovieStatuses.add((movieId: movieId, status: status));

    final AppException? error = updateStatusError;

    if (error != null) {
      throw error;
    }

    final DateTime now = DateTime.utc(2026, 8, 11);

    return LibraryEntry(
      id: 'library-entry-uuid',
      mediaId: movieId,
      mediaType: LibraryMediaType.movie,
      status: status,
      completedAt: status == LibraryStatus.completed ? now : null,
      createdAt: DateTime.utc(2026, 8, 10),
      updatedAt: now,
    );
  }

  @override
  Future<LibraryEntry> addMovie(String movieId) async {
    addMovieCalls++;

    requestedMovieIds.add(movieId);

    final AppException? error = addError;

    if (error != null) {
      throw error;
    }

    return _libraryEntry;
  }

  @override
  Future<ImportedLibraryMedia> importShowByTmdbId(int tmdbId) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryEntry> addShow(String showId) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeShow(String showId) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeMovie(String movieId) async {
    removeMovieCalls++;

    requestedRemovedMovieIds.add(movieId);

    final AppException? error = removeError;

    if (error != null) {
      throw error;
    }
  }

  @override
  Future<LibraryEntry> updateShowStatus(String showId, LibraryStatus status) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryPreview> getPreview() {
    throw UnimplementedError();
  }
}

final class _RetryLibraryRepository extends _FakeLibraryRepository {
  @override
  Future<ImportedLibraryMedia> importMovieByTmdbId(int tmdbId) async {
    importMovieCalls++;

    requestedTmdbIds.add(tmdbId);

    if (importMovieCalls == 1) {
      throw const AppException.connection();
    }

    return _importedMovie;
  }
}

final class _ControlledLibraryRepository implements LibraryRepository {
  final Completer<ImportedLibraryMedia> _importCompleter =
      Completer<ImportedLibraryMedia>();

  final Completer<LibraryEntry> _addCompleter = Completer<LibraryEntry>();

  void completeImport() {
    _importCompleter.complete(_importedMovie);
  }

  void completeAdd() {
    _addCompleter.complete(_libraryEntry);
  }

  @override
  Future<LibraryEntry?> getMovieEntry(String movieId) async {
    return null;
  }

  @override
  Future<LibraryEntry?> getShowEntry(String showId) async {
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
  Future<ImportedLibraryMedia> importMovieByTmdbId(int tmdbId) {
    return _importCompleter.future;
  }

  @override
  Future<LibraryEntry> addMovie(String movieId) {
    return _addCompleter.future;
  }

  @override
  Future<ImportedLibraryMedia> importShowByTmdbId(int tmdbId) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryEntry> addShow(String showId) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeShow(String showId) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeMovie(String movieId) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryEntry> updateShowStatus(String showId, LibraryStatus status) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryPreview> getPreview() {
    throw UnimplementedError();
  }
}

final class _ControlledRemoveLibraryRepository extends _FakeLibraryRepository {
  final Completer<void> _removeCompleter = Completer<void>();

  void completeRemove() {
    _removeCompleter.complete();
  }

  @override
  Future<void> removeMovie(String movieId) {
    removeMovieCalls++;

    requestedRemovedMovieIds.add(movieId);

    return _removeCompleter.future;
  }
}

final class _RetryUpdateLibraryRepository extends _FakeLibraryRepository {
  _RetryUpdateLibraryRepository({super.movieEntry});

  @override
  Future<LibraryEntry> updateMovieStatus(
    String movieId,
    LibraryStatus status,
  ) async {
    updateMovieStatusCalls++;

    updatedMovieStatuses.add((movieId: movieId, status: status));

    if (updateMovieStatusCalls == 1) {
      throw const AppException.connection();
    }

    final DateTime now = DateTime.utc(2026, 8, 11);

    return LibraryEntry(
      id: 'library-entry-uuid',
      mediaId: movieId,
      mediaType: LibraryMediaType.movie,
      status: status,
      completedAt: status == LibraryStatus.completed ? now : null,
      createdAt: DateTime.utc(2026, 8, 10),
      updatedAt: now,
    );
  }
}

final class _ControlledUpdateLibraryRepository extends _FakeLibraryRepository {
  _ControlledUpdateLibraryRepository({super.movieEntry});

  final Completer<LibraryEntry> _updateCompleter = Completer<LibraryEntry>();

  void completeUpdate({required LibraryStatus status}) {
    final DateTime now = DateTime.utc(2026, 8, 11);

    _updateCompleter.complete(
      LibraryEntry(
        id: 'library-entry-uuid',
        mediaId: 'movie-local-uuid',
        mediaType: LibraryMediaType.movie,
        status: status,
        completedAt: status == LibraryStatus.completed ? now : null,
        createdAt: DateTime.utc(2026, 8, 10),
        updatedAt: now,
      ),
    );
  }

  @override
  Future<LibraryEntry> updateMovieStatus(String movieId, LibraryStatus status) {
    updateMovieStatusCalls++;

    updatedMovieStatuses.add((movieId: movieId, status: status));

    return _updateCompleter.future;
  }
}

final class _RetryRemoveLibraryRepository extends _FakeLibraryRepository {
  @override
  Future<void> removeMovie(String movieId) async {
    removeMovieCalls++;

    requestedRemovedMovieIds.add(movieId);

    if (removeMovieCalls == 1) {
      throw const AppException.connection();
    }
  }
}
