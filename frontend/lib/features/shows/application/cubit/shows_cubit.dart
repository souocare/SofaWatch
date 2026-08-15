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
  ShowsCubit({required this.repository, DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(const ShowsState());

  final ShowsRepository repository;
  final DateTime Function() _now;

  static const int _initialUpcomingPastDays = 7;
  static const int _earlierUpcomingChunkDays = 14;

  DateTime _today() {
    final DateTime now = _now();

    return DateTime(now.year, now.month, now.day);
  }

  DateTime _initialUpcomingFromDate() {
    return _today().subtract(const Duration(days: _initialUpcomingPastDays));
  }

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

    await _loadUpcoming(
      fromDate: state.upcomingFromDate ?? _initialUpcomingFromDate(),
      toDate: state.upcomingToDate,
      referenceDate: state.upcomingReferenceDate ?? _today(),
    );
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

  Future<void> _loadUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
    DateTime? referenceDate,
  }) async {
    if (state.isLoadingUpcoming) {
      return;
    }

    emit(state.copyWith(isLoadingUpcoming: true, clearUpcomingError: true));

    try {
      final List<UpcomingItem> upcoming = await repository.getUpcoming(
        fromDate: fromDate,
        toDate: toDate,
      );

      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          upcoming: upcoming,
          hasLoadedUpcoming: true,
          upcomingReferenceDate:
              referenceDate ?? state.upcomingReferenceDate ?? _today(),
          upcomingFromDate: fromDate,
          clearUpcomingFromDate: fromDate == null,
          upcomingToDate: toDate,
          clearUpcomingToDate: toDate == null,
          isLoadingUpcoming: false,
          clearUpcomingError: true,
          clearEarlierUpcomingError: true,
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

  Future<void> _refreshLoadedUpcomingRange() {
    return _loadUpcoming(
      fromDate: state.upcomingFromDate ?? _initialUpcomingFromDate(),
      toDate: state.upcomingToDate,
    );
  }

  Future<void> loadEarlierUpcoming() async {
    if (!state.canLoadEarlierUpcoming) {
      return;
    }

    final DateTime? currentFromDate = state.upcomingFromDate;

    if (currentFromDate == null) {
      return;
    }

    /*
   * The current range already includes currentFromDate.
   *
   * Therefore the next historical range must end on the previous day
   * to avoid requesting the same boundary twice.
   */
    final DateTime toDate = currentFromDate.subtract(const Duration(days: 1));

    final DateTime fromDate = toDate.subtract(
      const Duration(days: _earlierUpcomingChunkDays - 1),
    );

    emit(
      state.copyWith(
        isLoadingEarlierUpcoming: true,
        clearEarlierUpcomingError: true,
      ),
    );

    try {
      final List<UpcomingItem> earlierItems = await repository.getUpcoming(
        fromDate: fromDate,
        toDate: toDate,
      );

      if (isClosed) {
        return;
      }

      /*
     * The backend orders each requested range chronologically.
     *
     * Still deduplicate by Episode ID because Upcoming can later evolve
     * independently and overlapping ranges must never create duplicate rows.
     */
      final Set<String> existingEpisodeIds = state.upcoming
          .map((UpcomingItem item) => item.episode.id)
          .toSet();

      final List<UpcomingItem> newItems = earlierItems
          .where(
            (UpcomingItem item) =>
                !existingEpisodeIds.contains(item.episode.id),
          )
          .toList(growable: false);

      final List<UpcomingItem> mergedItems =
          <UpcomingItem>[...newItems, ...state.upcoming]
            ..sort((UpcomingItem left, UpcomingItem right) {
              final int dateComparison = left.episode.airDate.compareTo(
                right.episode.airDate,
              );

              if (dateComparison != 0) {
                return dateComparison;
              }

              final int showComparison = left.showTitle.toLowerCase().compareTo(
                right.showTitle.toLowerCase(),
              );

              if (showComparison != 0) {
                return showComparison;
              }

              final int seasonComparison = left.episode.seasonNumber.compareTo(
                right.episode.seasonNumber,
              );

              if (seasonComparison != 0) {
                return seasonComparison;
              }

              return left.episode.episodeNumber.compareTo(
                right.episode.episodeNumber,
              );
            });

      emit(
        state.copyWith(
          upcoming: mergedItems,
          upcomingFromDate: fromDate,
          isLoadingEarlierUpcoming: false,
          clearEarlierUpcomingError: true,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          isLoadingEarlierUpcoming: false,
          earlierUpcomingError: error,
        ),
      );
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          isLoadingEarlierUpcoming: false,
          earlierUpcomingError: AppException.unknown(originalError: error),
        ),
      );
    }
  }

  Future<void> retryEarlierUpcoming() {
    return loadEarlierUpcoming();
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
    if (!state.hasLoadedUpcoming) {
      final DateTime today = _today();

      return _loadUpcoming(
        fromDate: today.subtract(
          const Duration(days: _initialUpcomingPastDays),
        ),
        referenceDate: today,
      );
    }

    return _loadUpcoming(
      fromDate: state.upcomingFromDate,
      toDate: state.upcomingToDate,
      referenceDate: state.upcomingReferenceDate,
    );
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
     * - Upcoming may change because the Show is now eligible as Watching.
     *
     * Reload backend-owned collections instead of reproducing
     * those rules locally.
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

      await _refreshLoadedUpcomingRange();

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
