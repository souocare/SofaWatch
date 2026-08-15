import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/shows/application/cubit/shows_state.dart';
import 'package:sofawatch/features/shows/domain/models/library_show.dart';
import 'package:sofawatch/features/shows/domain/models/stale_watching_show.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_show.dart';
import 'package:sofawatch/features/shows/domain/repositories/shows_repository.dart';
import 'package:sofawatch/features/shows/domain/models/watch_history_page.dart';
import 'package:sofawatch/features/shows/domain/models/watch_history_item.dart';
import 'package:sofawatch/features/shows/domain/models/upcoming_item.dart';

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
        clearUpcomingError: true,
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
    if (isClosed) {
      return;
    }

    await _loadUpcoming();
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

  Future<void> _loadUpcoming() async {
    if (state.isLoadingUpcoming) {
      return;
    }

    emit(state.copyWith(isLoadingUpcoming: true, clearUpcomingError: true));

    try {
      final List<UpcomingItem> upcoming = await repository.getUpcoming();

      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          upcoming: upcoming,
          isLoadingUpcoming: false,
          clearUpcomingError: true,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(state.copyWith(isLoadingUpcoming: false, upcomingError: error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          isLoadingUpcoming: false,
          upcomingError: AppException.unknown(originalError: error),
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

  Future<void> retryUpcoming() {
    return _loadUpcoming();
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

  Future<void> markWatchNextEpisodeWatched({required String episodeId}) async {
    if (state.updatingWatchNextEpisodeId != null) {
      return;
    }

    emit(
      state.copyWith(
        updatingWatchNextEpisodeId: episodeId,
        clearWatchNextOperationError: true,
      ),
    );

    try {
      await repository.markEpisodeWatched(episodeId: episodeId);

      if (isClosed) {
        return;
      }

      /*
     * The backend remains the source of truth for Watch Next.
     *
     * Marking an Episode as watched may change the next Episode,
     * progress counters, or remove the Show from Watch Next entirely.
     * Therefore these values must not be calculated optimistically here.
     */
      await _loadWatchNext();

      if (isClosed) {
        return;
      }

      await _loadStaleWatching();

      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          clearUpdatingWatchNextEpisodeId: true,
          clearWatchNextOperationError: true,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          clearUpdatingWatchNextEpisodeId: true,
          watchNextOperationError: error,
        ),
      );
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          clearUpdatingWatchNextEpisodeId: true,
          watchNextOperationError: AppException.unknown(originalError: error),
        ),
      );
    }
  }

  Future<void> markWatchHistoryEpisodeUnwatched({
    required String eventId,
    required String episodeId,
  }) async {
    if (state.updatingWatchHistoryEventId != null) {
      return;
    }

    emit(
      state.copyWith(
        updatingWatchHistoryEventId: eventId,
        clearWatchHistoryOperationError: true,
      ),
    );

    try {
      await repository.markEpisodeUnwatched(episodeId: episodeId);

      if (isClosed) {
        return;
      }

      /*
     * Episode progress affects several server-owned collections.
     *
     * Marking an Episode as unwatched may:
     *
     * - remove it from Watch History;
     * - make it the next Episode in Watch Next;
     * - change whether a Show belongs in stale Watching.
     *
     * Reload those collections from the backend instead of deriving
     * them optimistically in the client.
     */

      await loadWatchHistory();

      if (isClosed) {
        return;
      }

      await _loadWatchNext();

      if (isClosed) {
        return;
      }

      await _loadStaleWatching();

      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          clearUpdatingWatchHistoryEventId: true,
          clearWatchHistoryOperationError: true,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          clearUpdatingWatchHistoryEventId: true,
          watchHistoryOperationError: error,
        ),
      );
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          clearUpdatingWatchHistoryEventId: true,
          watchHistoryOperationError: AppException.unknown(
            originalError: error,
          ),
        ),
      );
    }
  }

  Future<void> rewatchWatchHistoryEpisode({
    required String eventId,
    required String episodeId,
  }) async {
    if (state.updatingWatchHistoryEventId != null) {
      return;
    }

    emit(
      state.copyWith(
        updatingWatchHistoryEventId: eventId,
        clearWatchHistoryOperationError: true,
      ),
    );

    try {
      await repository.markEpisodeWatched(episodeId: episodeId);

      if (isClosed) {
        return;
      }

      /*
     * Rewatch creates a new server-owned viewing event.
     *
     * The backend remains the source of truth for:
     *
     * - Watch History;
     * - Episode progress;
     * - Watch Next;
     * - stale Watching.
     *
     * Reload the affected collections instead of creating or updating
     * viewing events optimistically in the client.
     */

      await loadWatchHistory();

      if (isClosed) {
        return;
      }

      await _loadWatchNext();

      if (isClosed) {
        return;
      }

      await _loadStaleWatching();

      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          clearUpdatingWatchHistoryEventId: true,
          clearWatchHistoryOperationError: true,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          clearUpdatingWatchHistoryEventId: true,
          watchHistoryOperationError: error,
        ),
      );
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          clearUpdatingWatchHistoryEventId: true,
          watchHistoryOperationError: AppException.unknown(
            originalError: error,
          ),
        ),
      );
    }
  }

  Future<void> startShow({required String showId}) async {
    if (state.startingShowId != null) {
      return;
    }

    emit(state.copyWith(startingShowId: showId, clearStartShowError: true));

    try {
      await repository.startShow(showId: showId);

      if (isClosed) {
        return;
      }

      /*
     * Starting a Show changes multiple server-owned collections:
     *
     * - Library status changes from Planning to Watching.
     * - The first aired Episode becomes watched.
     * - Watch Next may now contain the following Episode.
     *
     * Reload the backend state instead of reproducing these rules locally.
     */
      final List<LibraryShow> libraryShows = await repository.getLibraryShows();

      if (isClosed) {
        return;
      }

      emit(state.copyWith(libraryShows: libraryShows));

      await _loadWatchNext();

      if (isClosed) {
        return;
      }

      await _loadStaleWatching();

      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(clearStartingShowId: true, clearStartShowError: true),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(state.copyWith(clearStartingShowId: true, startShowError: error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          clearStartingShowId: true,
          startShowError: AppException.unknown(originalError: error),
        ),
      );
    }
    await _loadUpcoming();

    if (isClosed) {
      return;
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
