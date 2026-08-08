import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/application/cubit/library_item_operation.dart';
import 'package:sofawatch/features/library/application/cubit/library_state.dart';
import 'package:sofawatch/features/library/domain/models/imported_library_media.dart';
import 'package:sofawatch/features/library/domain/models/library_entry.dart';
import 'package:sofawatch/features/library/domain/models/library_media_key.dart';
import 'package:sofawatch/features/library/domain/models/library_media_type.dart';
import 'package:sofawatch/features/library/domain/repositories/library_repository.dart';

final class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit(this._repository) : super(const LibraryState());

  final LibraryRepository _repository;

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
}
