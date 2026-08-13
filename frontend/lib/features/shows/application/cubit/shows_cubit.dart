import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/shows/application/cubit/shows_state.dart';
import 'package:sofawatch/features/shows/domain/models/library_show.dart';
import 'package:sofawatch/features/shows/domain/models/stale_watching_show.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_show.dart';
import 'package:sofawatch/features/shows/domain/repositories/shows_repository.dart';
import 'package:sofawatch/features/shows/domain/models/watch_history_page.dart';
import 'package:sofawatch/features/shows/domain/models/watch_history_item.dart';

final class ShowsCubit extends Cubit<ShowsState> {
  ShowsCubit({required this.repository}) : super(const ShowsState());

  final ShowsRepository repository;

  Future<void> load() async {
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearWatchNextError: true,
        clearStaleWatchingError: true,
      ),
    );

    final List<LibraryShow> libraryShows;

    try {
      libraryShows = await repository.getLibraryShows();
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
     * Publish it immediately so supplementary sections cannot prevent
     * the main Shows screen from being usable.
     */
    emit(
      state.copyWith(
        libraryShows: libraryShows,
        isLoading: false,
        clearError: true,
      ),
    );

    await _loadWatchNext();

    if (isClosed) {
      return;
    }

    await _loadStaleWatching();
  }

  Future<void> _loadWatchNext() async {
    try {
      final List<WatchNextShow> watchNext = await repository.getWatchNext();

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

  Future<void> _loadStaleWatching() async {
    try {
      final List<StaleWatchingShow> staleWatching = await repository
          .getStaleWatching();

      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          staleWatching: staleWatching,
          clearStaleWatchingError: true,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(state.copyWith(staleWatchingError: error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          staleWatchingError: AppException.unknown(originalError: error),
        ),
      );
    }
  }

  Future<void> loadWatchHistory() async {
    if (state.isLoadingWatchHistory) {
      return;
    }

    emit(
      state.copyWith(isLoadingWatchHistory: true, clearWatchHistoryError: true),
    );

    try {
      final WatchHistoryPage page = await repository.getWatchHistory();

      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          watchHistory: page.items,
          watchHistoryNextCursor: page.nextCursor,
          clearWatchHistoryNextCursor: page.nextCursor == null,
          hasMoreWatchHistory: page.hasMore,
          isLoadingWatchHistory: false,
          clearWatchHistoryError: true,
          hasLoadedWatchHistory: true,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(isLoadingWatchHistory: false, watchHistoryError: error),
      );
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          isLoadingWatchHistory: false,
          watchHistoryError: AppException.unknown(originalError: error),
        ),
      );
    }
  }

  Future<void> loadMoreWatchHistory() async {
    if (state.isLoadingWatchHistory ||
        state.isLoadingMoreWatchHistory ||
        !state.hasMoreWatchHistory ||
        state.watchHistoryNextCursor == null) {
      return;
    }

    emit(
      state.copyWith(
        isLoadingMoreWatchHistory: true,
        clearWatchHistoryError: true,
      ),
    );

    try {
      final WatchHistoryPage page = await repository.getWatchHistory(
        cursor: state.watchHistoryNextCursor,
      );

      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          watchHistory: <WatchHistoryItem>[
            ...state.watchHistory,
            ...page.items,
          ],
          watchHistoryNextCursor: page.nextCursor,
          clearWatchHistoryNextCursor: page.nextCursor == null,
          hasMoreWatchHistory: page.hasMore,
          isLoadingMoreWatchHistory: false,
          clearWatchHistoryError: true,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          isLoadingMoreWatchHistory: false,
          watchHistoryError: error,
        ),
      );
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          isLoadingMoreWatchHistory: false,
          watchHistoryError: AppException.unknown(originalError: error),
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

  Future<void> retryStaleWatching() async {
    emit(state.copyWith(clearStaleWatchingError: true));

    await _loadStaleWatching();
  }

  Future<void> retryWatchHistory() async {
    await loadWatchHistory();
  }
}
