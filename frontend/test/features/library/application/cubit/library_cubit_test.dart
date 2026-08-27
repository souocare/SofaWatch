import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/application/cubit/library_cubit.dart';
import 'package:sofawatch/features/library/application/cubit/library_item_operation.dart';
import 'package:sofawatch/features/library/domain/models/imported_library_media.dart';
import 'package:sofawatch/features/library/domain/models/library_entry.dart';
import 'package:sofawatch/features/library/domain/models/library_media_key.dart';
import 'package:sofawatch/features/library/domain/models/library_media_type.dart';
import 'package:sofawatch/features/library/domain/models/library_preview.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/library/domain/repositories/library_repository.dart';

void main() {
  group('LibraryCubit', () {
    test('imports and adds a Show', () async {
      final _FakeLibraryRepository repository = _FakeLibraryRepository();

      final LibraryCubit cubit = LibraryCubit(repository);

      const LibraryMediaKey key = LibraryMediaKey(
        mediaType: LibraryMediaType.show,
        tmdbId: 95396,
      );

      final Future<List<LibraryItemOperationStatus>> statusesFuture = cubit
          .stream
          .map((state) => state.operationFor(key).status)
          .take(2)
          .toList();

      await cubit.addToLibrary(key);

      final List<LibraryItemOperationStatus> statuses = await statusesFuture;

      expect(statuses, <LibraryItemOperationStatus>[
        LibraryItemOperationStatus.adding,
        LibraryItemOperationStatus.added,
      ]);

      expect(repository.importedShowTmdbIds, <int>[95396]);

      expect(repository.addedShowIds, <String>['show-uuid']);

      await cubit.close();
    });

    test('imports and adds a Movie', () async {
      final _FakeLibraryRepository repository = _FakeLibraryRepository();

      final LibraryCubit cubit = LibraryCubit(repository);

      const LibraryMediaKey key = LibraryMediaKey(
        mediaType: LibraryMediaType.movie,
        tmdbId: 438631,
      );

      await cubit.addToLibrary(key);

      final operation = cubit.state.operationFor(key);

      expect(operation.isAdded, isTrue);

      expect(operation.entry, isNotNull);

      expect(operation.entry!.status, LibraryStatus.planning);

      expect(repository.importedMovieTmdbIds, <int>[438631]);

      expect(repository.addedMovieIds, <String>['movie-uuid']);

      await cubit.close();
    });

    test('stores a failure for only the affected media', () async {
      final _FakeLibraryRepository repository = _FakeLibraryRepository(
        error: const AppException.connection(),
      );

      final LibraryCubit cubit = LibraryCubit(repository);

      const LibraryMediaKey failedKey = LibraryMediaKey(
        mediaType: LibraryMediaType.show,
        tmdbId: 95396,
      );

      const LibraryMediaKey untouchedKey = LibraryMediaKey(
        mediaType: LibraryMediaType.movie,
        tmdbId: 438631,
      );

      await cubit.addToLibrary(failedKey);

      expect(cubit.state.operationFor(failedKey).hasFailed, isTrue);

      expect(
        cubit.state.operationFor(untouchedKey).status,
        LibraryItemOperationStatus.idle,
      );

      await cubit.close();
    });

    test('does not repeat an already added operation', () async {
      final _FakeLibraryRepository repository = _FakeLibraryRepository();

      final LibraryCubit cubit = LibraryCubit(repository);

      const LibraryMediaKey key = LibraryMediaKey(
        mediaType: LibraryMediaType.show,
        tmdbId: 95396,
      );

      await cubit.addToLibrary(key);
      await cubit.addToLibrary(key);

      expect(repository.importedShowTmdbIds, <int>[95396]);

      await cubit.close();
    });

    test('markAdded initializes known library state', () async {
      final _FakeLibraryRepository repository = _FakeLibraryRepository();

      final LibraryCubit cubit = LibraryCubit(repository);

      const LibraryMediaKey key = LibraryMediaKey(
        mediaType: LibraryMediaType.movie,
        tmdbId: 438631,
      );

      cubit.markAdded(key);

      expect(cubit.state.operationFor(key).isAdded, isTrue);

      expect(repository.importedMovieTmdbIds, isEmpty);

      await cubit.close();
    });
  });

  test(
    'does not start a duplicate operation while the item is adding',
    () async {
      final Completer<ImportedLibraryMedia> completer =
          Completer<ImportedLibraryMedia>();

      final _FakeLibraryRepository repository = _FakeLibraryRepository()
        ..pendingShowImport = completer;

      final LibraryCubit cubit = LibraryCubit(repository);

      const LibraryMediaKey key = LibraryMediaKey(
        mediaType: LibraryMediaType.show,
        tmdbId: 95396,
      );

      final Future<void> firstRequest = cubit.addToLibrary(key);

      await Future<void>.delayed(Duration.zero);

      await cubit.addToLibrary(key);

      expect(repository.importedShowTmdbIds, <int>[95396]);

      completer.complete(
        const ImportedLibraryMedia(
          id: 'show-uuid',
          tmdbId: 95396,
          mediaType: LibraryMediaType.show,
        ),
      );

      await firstRequest;

      await cubit.close();
    },
  );
  test('removes an added Movie', () async {
    final _FakeLibraryRepository repository = _FakeLibraryRepository();
    final LibraryCubit cubit = LibraryCubit(repository);

    const LibraryMediaKey key = LibraryMediaKey(
      mediaType: LibraryMediaType.movie,
      tmdbId: 438631,
    );

    await cubit.addToLibrary(key);

    expect(cubit.state.operationFor(key).isAdded, isTrue);

    await cubit.removeFromLibrary(key);

    expect(repository.removedMovieIds, <String>['movie-uuid']);

    expect(
      cubit.state.operationFor(key).status,
      LibraryItemOperationStatus.idle,
    );

    await cubit.close();
  });

  test('keeps the Movie entry while removal is in progress', () async {
    final Completer<void> completer = Completer<void>();

    final _FakeLibraryRepository repository = _FakeLibraryRepository()
      ..pendingMovieRemoval = completer;

    final LibraryCubit cubit = LibraryCubit(repository);

    const LibraryMediaKey key = LibraryMediaKey(
      mediaType: LibraryMediaType.movie,
      tmdbId: 438631,
    );

    await cubit.addToLibrary(key);

    final LibraryEntry? addedEntry = cubit.state.operationFor(key).entry;

    final Future<void> removal = cubit.removeFromLibrary(key);

    await Future<void>.delayed(Duration.zero);

    final LibraryItemOperation operation = cubit.state.operationFor(key);

    expect(operation.isRemoving, isTrue);
    expect(operation.entry, addedEntry);
    expect(operation.entry?.mediaId, 'movie-uuid');

    completer.complete();

    await removal;

    expect(
      cubit.state.operationFor(key).status,
      LibraryItemOperationStatus.idle,
    );

    await cubit.close();
  });

  test('preserves the Movie entry when removal fails', () async {
    final _FakeLibraryRepository repository = _FakeLibraryRepository();
    final LibraryCubit cubit = LibraryCubit(repository);

    const LibraryMediaKey key = LibraryMediaKey(
      mediaType: LibraryMediaType.movie,
      tmdbId: 438631,
    );

    await cubit.addToLibrary(key);

    final LibraryEntry? addedEntry = cubit.state.operationFor(key).entry;

    repository.removeError = const AppException.connection();

    await cubit.removeFromLibrary(key);

    final LibraryItemOperation operation = cubit.state.operationFor(key);

    expect(operation.hasFailed, isTrue);
    expect(operation.error, const AppException.connection());

    expect(operation.entry, addedEntry);
    expect(operation.entry?.mediaId, 'movie-uuid');

    await cubit.close();
  });

  test('retryRemove retries a failed Movie removal', () async {
    final _FakeLibraryRepository repository = _FakeLibraryRepository();
    final LibraryCubit cubit = LibraryCubit(repository);

    const LibraryMediaKey key = LibraryMediaKey(
      mediaType: LibraryMediaType.movie,
      tmdbId: 438631,
    );

    await cubit.addToLibrary(key);

    repository.removeError = const AppException.connection();

    await cubit.removeFromLibrary(key);

    expect(cubit.state.operationFor(key).hasFailed, isTrue);
    expect(repository.removedMovieIds, <String>['movie-uuid']);

    repository.removeError = null;

    await cubit.retryRemove(key);

    expect(repository.removedMovieIds, <String>['movie-uuid', 'movie-uuid']);

    expect(
      cubit.state.operationFor(key).status,
      LibraryItemOperationStatus.idle,
    );

    await cubit.close();
  });

  test('loads existing Movie library state', () async {
    final DateTime now = DateTime.utc(2026, 8, 10);

    final LibraryEntry existingEntry = LibraryEntry(
      id: 'entry-uuid',
      mediaId: 'movie-uuid',
      mediaType: LibraryMediaType.movie,
      status: LibraryStatus.planning,
      createdAt: now,
      updatedAt: now,
    );

    final _FakeLibraryRepository repository = _FakeLibraryRepository(
      movieEntry: existingEntry,
    );

    final LibraryCubit cubit = LibraryCubit(repository);

    const LibraryMediaKey key = LibraryMediaKey(
      mediaType: LibraryMediaType.movie,
      tmdbId: 438631,
    );

    await cubit.loadMovieState(key);

    final LibraryItemOperation operation = cubit.state.operationFor(key);

    expect(operation.isAdded, isTrue);
    expect(operation.entry, existingEntry);

    expect(repository.importedMovieTmdbIds, <int>[438631]);
    expect(repository.requestedMovieEntryIds, <String>['movie-uuid']);

    await cubit.close();
  });

  test('keeps Movie idle when it is not in the library', () async {
    final _FakeLibraryRepository repository = _FakeLibraryRepository();

    final LibraryCubit cubit = LibraryCubit(repository);

    const LibraryMediaKey key = LibraryMediaKey(
      mediaType: LibraryMediaType.movie,
      tmdbId: 438631,
    );

    await cubit.loadMovieState(key);

    final LibraryItemOperation operation = cubit.state.operationFor(key);

    expect(operation.status, LibraryItemOperationStatus.idle);

    expect(repository.importedMovieTmdbIds, <int>[438631]);
    expect(repository.requestedMovieEntryIds, <String>['movie-uuid']);

    await cubit.close();
  });

  test('does not overwrite an already added Movie state', () async {
    final _FakeLibraryRepository repository = _FakeLibraryRepository();

    final LibraryCubit cubit = LibraryCubit(repository);

    const LibraryMediaKey key = LibraryMediaKey(
      mediaType: LibraryMediaType.movie,
      tmdbId: 438631,
    );

    cubit.markAdded(key);

    await cubit.loadMovieState(key);

    expect(cubit.state.operationFor(key).isAdded, isTrue);

    expect(repository.importedMovieTmdbIds, isEmpty);
    expect(repository.requestedMovieEntryIds, isEmpty);

    await cubit.close();
  });

  test('marks an added Movie as watched', () async {
    final _FakeLibraryRepository repository = _FakeLibraryRepository();

    final LibraryCubit cubit = LibraryCubit(repository);

    const LibraryMediaKey key = LibraryMediaKey(
      mediaType: LibraryMediaType.movie,
      tmdbId: 438631,
    );

    await cubit.addToLibrary(key);

    expect(cubit.state.operationFor(key).entry?.status, LibraryStatus.planning);

    await cubit.markMovieWatched(key);

    final LibraryItemOperation operation = cubit.state.operationFor(key);

    expect(operation.isAdded, isTrue);
    expect(operation.entry?.status, LibraryStatus.completed);
    expect(operation.entry?.completedAt, isNotNull);

    expect(
      repository.updatedMovieStatuses,
      <({String movieId, LibraryStatus status})>[
        (movieId: 'movie-uuid', status: LibraryStatus.completed),
      ],
    );

    await cubit.close();
  });

  test('marks a completed Movie as unwatched', () async {
    final DateTime now = DateTime.utc(2026, 8, 10);

    final LibraryEntry completedEntry = LibraryEntry(
      id: 'entry-uuid',
      mediaId: 'movie-uuid',
      mediaType: LibraryMediaType.movie,
      status: LibraryStatus.completed,
      completedAt: now,
      createdAt: DateTime.utc(2026, 8, 8),
      updatedAt: now,
    );

    final _FakeLibraryRepository repository = _FakeLibraryRepository(
      movieEntry: completedEntry,
    );

    final LibraryCubit cubit = LibraryCubit(repository);

    const LibraryMediaKey key = LibraryMediaKey(
      mediaType: LibraryMediaType.movie,
      tmdbId: 438631,
    );

    await cubit.loadMovieState(key);

    expect(
      cubit.state.operationFor(key).entry?.status,
      LibraryStatus.completed,
    );

    await cubit.markMovieUnwatched(key);

    final LibraryItemOperation operation = cubit.state.operationFor(key);

    expect(operation.isAdded, isTrue);
    expect(operation.entry?.status, LibraryStatus.planning);
    expect(operation.entry?.completedAt, isNull);

    expect(
      repository.updatedMovieStatuses,
      <({String movieId, LibraryStatus status})>[
        (movieId: 'movie-uuid', status: LibraryStatus.planning),
      ],
    );

    await cubit.close();
  });

  test(
    'does not update Movie when watched state is already completed',
    () async {
      final DateTime now = DateTime.utc(2026, 8, 10);

      final LibraryEntry completedEntry = LibraryEntry(
        id: 'entry-uuid',
        mediaId: 'movie-uuid',
        mediaType: LibraryMediaType.movie,
        status: LibraryStatus.completed,
        completedAt: now,
        createdAt: DateTime.utc(2026, 8, 8),
        updatedAt: now,
      );

      final _FakeLibraryRepository repository = _FakeLibraryRepository(
        movieEntry: completedEntry,
      );

      final LibraryCubit cubit = LibraryCubit(repository);

      const LibraryMediaKey key = LibraryMediaKey(
        mediaType: LibraryMediaType.movie,
        tmdbId: 438631,
      );

      await cubit.loadMovieState(key);

      await cubit.markMovieWatched(key);

      expect(repository.updatedMovieStatuses, isEmpty);

      await cubit.close();
    },
  );

  test('preserves Movie entry when watched update fails', () async {
    final _FakeLibraryRepository repository = _FakeLibraryRepository();

    final LibraryCubit cubit = LibraryCubit(repository);

    const LibraryMediaKey key = LibraryMediaKey(
      mediaType: LibraryMediaType.movie,
      tmdbId: 438631,
    );

    await cubit.addToLibrary(key);

    final LibraryEntry? originalEntry = cubit.state.operationFor(key).entry;

    repository.updateMovieStatusError = const AppException.connection();

    await cubit.markMovieWatched(key);

    final LibraryItemOperation operation = cubit.state.operationFor(key);

    expect(operation.hasFailed, isTrue);
    expect(operation.error, const AppException.connection());

    expect(operation.entry, originalEntry);
    expect(operation.entry?.status, LibraryStatus.planning);

    await cubit.close();
  });
  test('loads existing Show library state', () async {
    final DateTime now = DateTime.utc(2026, 8, 11);

    final LibraryEntry existingEntry = LibraryEntry(
      id: 'show-entry-uuid',
      mediaId: 'show-uuid',
      mediaType: LibraryMediaType.show,
      status: LibraryStatus.watching,
      createdAt: now,
      updatedAt: now,
    );

    final _FakeLibraryRepository repository = _FakeLibraryRepository(
      showEntry: existingEntry,
    );

    final LibraryCubit cubit = LibraryCubit(repository);

    const LibraryMediaKey key = LibraryMediaKey(
      mediaType: LibraryMediaType.show,
      tmdbId: 95396,
    );

    await cubit.loadShowState(key);

    final LibraryItemOperation operation = cubit.state.operationFor(key);

    expect(operation.isAdded, isTrue);
    expect(operation.entry, existingEntry);

    expect(repository.importedShowTmdbIds, <int>[95396]);
    expect(repository.requestedShowEntryIds, <String>['show-uuid']);

    await cubit.close();
  });
  test('keeps Show idle when it is not in the library', () async {
    final _FakeLibraryRepository repository = _FakeLibraryRepository();

    final LibraryCubit cubit = LibraryCubit(repository);

    const LibraryMediaKey key = LibraryMediaKey(
      mediaType: LibraryMediaType.show,
      tmdbId: 95396,
    );

    await cubit.loadShowState(key);

    expect(
      cubit.state.operationFor(key).status,
      LibraryItemOperationStatus.idle,
    );

    expect(repository.importedShowTmdbIds, <int>[95396]);
    expect(repository.requestedShowEntryIds, <String>['show-uuid']);

    await cubit.close();
  });
  test('does not overwrite an already added Show state', () async {
    final _FakeLibraryRepository repository = _FakeLibraryRepository();

    final LibraryCubit cubit = LibraryCubit(repository);

    const LibraryMediaKey key = LibraryMediaKey(
      mediaType: LibraryMediaType.show,
      tmdbId: 95396,
    );

    cubit.markAdded(key);

    await cubit.loadShowState(key);

    expect(cubit.state.operationFor(key).isAdded, isTrue);

    expect(repository.importedShowTmdbIds, isEmpty);
    expect(repository.requestedShowEntryIds, isEmpty);

    await cubit.close();
  });
}

final class _FakeLibraryRepository implements LibraryRepository {
  _FakeLibraryRepository({this.error, this.showEntry, this.movieEntry});

  final AppException? error;
  AppException? removeError;
  final LibraryEntry? movieEntry;
  final LibraryEntry? showEntry;
  AppException? updateMovieStatusError;
  Completer<void>? pendingMovieRemoval;

  final List<int> importedShowTmdbIds = <int>[];
  final List<int> importedMovieTmdbIds = <int>[];

  final List<String> addedShowIds = <String>[];
  final List<String> addedMovieIds = <String>[];

  final List<String> removedShowIds = <String>[];
  final List<String> removedMovieIds = <String>[];
  final List<String> requestedMovieEntryIds = <String>[];
  final List<String> requestedShowEntryIds = <String>[];

  final List<({String showId, LibraryStatus status})> updatedShowStatuses =
      <({String showId, LibraryStatus status})>[];

  final List<({String movieId, LibraryStatus status})> updatedMovieStatuses =
      <({String movieId, LibraryStatus status})>[];

  Completer<ImportedLibraryMedia>? pendingShowImport;

  @override
  Future<ImportedLibraryMedia> importShowByTmdbId(int tmdbId) async {
    importedShowTmdbIds.add(tmdbId);

    _throwIfNeeded();

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

    _throwIfNeeded();

    return ImportedLibraryMedia(
      id: 'movie-uuid',
      tmdbId: tmdbId,
      mediaType: LibraryMediaType.movie,
    );
  }

  @override
  Future<LibraryEntry?> getShowEntry(String showId) async {
    requestedShowEntryIds.add(showId);

    return showEntry;
  }

  @override
  Future<LibraryEntry?> getMovieEntry(String movieId) async {
    requestedMovieEntryIds.add(movieId);

    return movieEntry;
  }

  @override
  Future<LibraryEntry> addShow(String showId) async {
    addedShowIds.add(showId);

    _throwIfNeeded();

    return _entry(mediaId: showId, mediaType: LibraryMediaType.show);
  }

  @override
  Future<LibraryEntry> addMovie(String movieId) async {
    addedMovieIds.add(movieId);

    _throwIfNeeded();

    return _entry(mediaId: movieId, mediaType: LibraryMediaType.movie);
  }

  @override
  Future<void> removeShow(String showId) async {
    removedShowIds.add(showId);

    _throwIfNeeded();
  }

  @override
  Future<void> removeMovie(String movieId) async {
    removedMovieIds.add(movieId);

    final AppException? currentRemoveError = removeError;

    if (currentRemoveError != null) {
      throw currentRemoveError;
    }

    final Completer<void>? pendingRemoval = pendingMovieRemoval;

    if (pendingRemoval != null) {
      await pendingRemoval.future;
    }
  }

  @override
  Future<LibraryEntry> updateShowStatus(
    String showId,
    LibraryStatus status,
  ) async {
    updatedShowStatuses.add((showId: showId, status: status));

    _throwIfNeeded();

    return _entry(
      mediaId: showId,
      mediaType: LibraryMediaType.show,
      status: status,
    );
  }

  @override
  Future<LibraryEntry> updateMovieStatus(
    String movieId,
    LibraryStatus status,
  ) async {
    updatedMovieStatuses.add((movieId: movieId, status: status));

    final AppException? currentError = updateMovieStatusError;

    if (currentError != null) {
      throw currentError;
    }

    final DateTime now = DateTime.utc(2026, 8, 10);

    return LibraryEntry(
      id: 'entry-uuid',
      mediaId: movieId,
      mediaType: LibraryMediaType.movie,
      status: status,
      completedAt: status == LibraryStatus.completed ? now : null,
      createdAt: DateTime.utc(2026, 8, 8),
      updatedAt: now,
    );
  }

  void _throwIfNeeded() {
    final AppException? currentError = error;

    if (currentError != null) {
      throw currentError;
    }
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

  @override
  Future<LibraryPreview> getPreview() {
    throw UnimplementedError();
  }
}
