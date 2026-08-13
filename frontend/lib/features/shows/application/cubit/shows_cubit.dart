import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/shows/application/cubit/shows_state.dart';
import 'package:sofawatch/features/shows/domain/models/library_show.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_show.dart';
import 'package:sofawatch/features/shows/domain/repositories/shows_repository.dart';

final class ShowsCubit extends Cubit<ShowsState> {
  ShowsCubit({required ShowsRepository repository})
    : _repository = repository,
      super(const ShowsState());

  final ShowsRepository _repository;

  Future<void> load() async {
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearWatchNextError: true,
      ),
    );

    final List<LibraryShow> libraryShows;

    try {
      libraryShows = await _repository.getLibraryShows();
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(state.copyWith(isLoading: false, error: error));

      return;
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          isLoading: false,
          error: AppException.unknown(originalError: error),
        ),
      );

      return;
    }

    if (isClosed) {
      return;
    }

    /*
     * Library is the core data source for Shows.
     *
     * Publish it immediately so a supplementary Watch Next request
     * cannot prevent the page itself from being usable.
     */
    emit(
      state.copyWith(
        libraryShows: libraryShows,
        isLoading: false,
        clearError: true,
      ),
    );

    await _loadWatchNext();
  }

  Future<void> _loadWatchNext() async {
    try {
      final List<WatchNextShow> watchNext = await _repository.getWatchNext();

      if (isClosed) {
        return;
      }

      emit(state.copyWith(watchNext: watchNext, clearWatchNextError: true));
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(state.copyWith(watchNextError: error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          watchNextError: AppException.unknown(originalError: error),
        ),
      );
    }
  }

  Future<void> retry() {
    return load();
  }

  Future<void> retryWatchNext() async {
    emit(state.copyWith(clearWatchNextError: true));

    await _loadWatchNext();
  }
}
