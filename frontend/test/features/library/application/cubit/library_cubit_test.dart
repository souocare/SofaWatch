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

      expect(cubit.state.operationFor(key).isAdded, isTrue);

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
}

final class _FakeLibraryRepository implements LibraryRepository {
  _FakeLibraryRepository({this.error});

  final AppException? error;

  final List<int> importedShowTmdbIds = <int>[];
  final List<int> importedMovieTmdbIds = <int>[];

  final List<String> addedShowIds = <String>[];
  final List<String> addedMovieIds = <String>[];

  @override
  Future<ImportedLibraryMedia> importShowByTmdbId(int tmdbId) async {
    importedShowTmdbIds.add(tmdbId);

    _throwIfNeeded();

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

  void _throwIfNeeded() {
    final AppException? currentError = error;

    if (currentError != null) {
      throw currentError;
    }
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
