import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/application/cubit/library_item_operation.dart';
import 'package:sofawatch/features/library/application/cubit/library_state.dart';
import 'package:sofawatch/features/library/domain/models/imported_library_media.dart';
import 'package:sofawatch/features/library/domain/models/library_entry.dart';
import 'package:sofawatch/features/library/domain/models/library_media_key.dart';
import 'package:sofawatch/features/library/domain/models/library_media_type.dart';
import 'package:sofawatch/features/library/domain/repositories/library_repository.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';

final class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit(this._repository) : super(const LibraryState());

  final LibraryRepository _repository;

  Future<void> loadMovieState(LibraryMediaKey key) async {
    if (key.mediaType != LibraryMediaType.movie) {
      return;
    }

    final LibraryItemOperation currentOperation = state.operationFor(key);

    /*
   * Do not overwrite an operation that may already have been performed
   * while the initial state was being resolved.
   */
    if (currentOperation.isAdding ||
        currentOperation.isAdded ||
        currentOperation.isRemoving ||
        currentOperation.isUpdating) {
      return;
    }

    try {
      final ImportedLibraryMedia movie = await _repository.importMovieByTmdbId(
        key.tmdbId,
      );

      final LibraryEntry? entry = await _repository.getMovieEntry(movie.id);

      if (isClosed) {
        return;
      }

      /*
     * Check the state again because another operation may have completed
     * while the initial request was running.
     */
      final LibraryItemOperation latestOperation = state.operationFor(key);

      if (latestOperation.isAdding ||
          latestOperation.isAdded ||
          latestOperation.isRemoving ||
          latestOperation.isUpdating) {
        return;
      }

      if (entry == null) {
        /*
       * Idle is already the correct state for a Movie that is not
       * currently in the Watchlist.
       */
        return;
      }

      emit(state.withOperation(key, LibraryItemOperation.added(entry: entry)));
    } on AppException {
      /*
     * Loading the existing Watchlist state is supplementary.
     *
     * A failure here must not prevent Movie Details from opening.
     * Add/remove operations still expose their own failures.
     */
    } on Object {
      /*
     * Same reasoning as above: Movie Details should remain usable even
     * when its initial Watchlist state cannot be resolved.
     */
    }
  }

  Future<void> addToLibrary(LibraryMediaKey key) async {
    final LibraryItemOperation currentOperation = state.operationFor(key);

    if (currentOperation.isAdding || currentOperation.isAdded) {
      return;
    }

    emit(state.withOperation(key, const LibraryItemOperation.adding()));

    try {
      final ImportedLibraryMedia importedMedia = await _importMedia(key);

      final LibraryEntry entry = await _addImportedMedia(importedMedia);

      if (isClosed) {
        return;
      }

      emit(state.withOperation(key, LibraryItemOperation.added(entry: entry)));
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(state.withOperation(key, LibraryItemOperation.failure(error)));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.withOperation(
          key,
          LibraryItemOperation.failure(
            AppException.unknown(originalError: error),
          ),
        ),
      );
    }
  }

  Future<void> retry(LibraryMediaKey key) {
    return addToLibrary(key);
  }

  void markAdded(LibraryMediaKey key) {
    final LibraryItemOperation currentOperation = state.operationFor(key);

    if (currentOperation.isAdding || currentOperation.isAdded) {
      return;
    }

    emit(state.withOperation(key, const LibraryItemOperation.added()));
  }

  Future<ImportedLibraryMedia> _importMedia(LibraryMediaKey key) {
    return switch (key.mediaType) {
      LibraryMediaType.show => _repository.importShowByTmdbId(key.tmdbId),
      LibraryMediaType.movie => _repository.importMovieByTmdbId(key.tmdbId),
    };
  }

  Future<LibraryEntry> _addImportedMedia(ImportedLibraryMedia media) {
    return switch (media.mediaType) {
      LibraryMediaType.show => _repository.addShow(media.id),
      LibraryMediaType.movie => _repository.addMovie(media.id),
    };
  }

  Future<void> markMovieWatched(LibraryMediaKey key) {
    return _updateMovieStatus(key: key, status: LibraryStatus.completed);
  }

  Future<void> markMovieUnwatched(LibraryMediaKey key) {
    return _updateMovieStatus(key: key, status: LibraryStatus.planning);
  }

  Future<void> retryMovieStatus(LibraryMediaKey key) async {
    final LibraryItemOperation operation = state.operationFor(key);

    final LibraryStatus? targetStatus = operation.targetStatus;
    final LibraryEntry? entry = operation.entry;

    if (!operation.isStatusUpdateFailure ||
        targetStatus == null ||
        entry == null) {
      return;
    }

    await _updateMovieStatus(key: key, status: targetStatus);
  }

  Future<void> _updateMovieStatus({
    required LibraryMediaKey key,
    required LibraryStatus status,
  }) async {
    if (key.mediaType != LibraryMediaType.movie) {
      return;
    }

    final LibraryItemOperation currentOperation = state.operationFor(key);
    final LibraryEntry? entry = currentOperation.entry;

    if (entry == null ||
        currentOperation.isAdding ||
        currentOperation.isRemoving ||
        currentOperation.isUpdating) {
      return;
    }

    /*
   * Avoid sending a request when the Movie is already in the requested state.
   */
    if (entry.status == status) {
      return;
    }

    emit(
      state.withOperation(
        key,
        LibraryItemOperation.updating(entry: entry, targetStatus: status),
      ),
    );

    try {
      final LibraryEntry updatedEntry = await _repository.updateMovieStatus(
        entry.mediaId,
        status,
      );

      if (isClosed) {
        return;
      }

      emit(
        state.withOperation(
          key,
          LibraryItemOperation.added(entry: updatedEntry),
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.withOperation(
          key,
          LibraryItemOperation.failure(
            error,
            entry: entry,
            targetStatus: status,
          ),
        ),
      );
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.withOperation(
          key,
          LibraryItemOperation.failure(
            AppException.unknown(originalError: error),
            entry: entry,
            targetStatus: status,
          ),
        ),
      );
    }
  }

  Future<void> removeFromLibrary(LibraryMediaKey key) async {
    final LibraryItemOperation currentOperation = state.operationFor(key);

    if (currentOperation.isAdding || currentOperation.isRemoving) {
      return;
    }

    final LibraryEntry? entry = currentOperation.entry;

    if (!currentOperation.isAdded || entry == null) {
      return;
    }

    await _removeEntry(key: key, entry: entry);
  }

  Future<void> retryRemove(LibraryMediaKey key) async {
    final LibraryItemOperation currentOperation = state.operationFor(key);

    if (!currentOperation.hasFailed || currentOperation.entry == null) {
      return;
    }

    await _removeEntry(key: key, entry: currentOperation.entry!);
  }

  Future<void> _removeEntry({
    required LibraryMediaKey key,
    required LibraryEntry entry,
  }) async {
    final LibraryItemOperation currentOperation = state.operationFor(key);

    if (currentOperation.isRemoving) {
      return;
    }
    emit(state.withOperation(key, LibraryItemOperation.removing(entry: entry)));

    try {
      await _removeImportedMedia(entry);

      if (isClosed) {
        return;
      }

      emit(state.withOperation(key, const LibraryItemOperation.idle()));
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.withOperation(
          key,
          LibraryItemOperation.failure(error, entry: entry),
        ),
      );
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.withOperation(
          key,
          LibraryItemOperation.failure(
            AppException.unknown(originalError: error),
            entry: entry,
          ),
        ),
      );
    }
  }

  Future<void> _removeImportedMedia(LibraryEntry entry) {
    return switch (entry.mediaType) {
      LibraryMediaType.show => _repository.removeShow(entry.mediaId),
      LibraryMediaType.movie => _repository.removeMovie(entry.mediaId),
    };
  }
}
