import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/home/application/cubit/home_state.dart';
import 'package:sofawatch/features/home/application/models/home_watch_source.dart';
import 'package:sofawatch/features/shows/domain/models/upcoming_item.dart';
import 'package:sofawatch/features/shows/domain/models/watch_history_page.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_show.dart';
import 'package:sofawatch/features/shows/domain/repositories/shows_repository.dart';

final class HomeCubit extends Cubit<HomeState> {
  HomeCubit({required this.repository, DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(const HomeState());

  static const int premieringTodayLimit = 5;
  static const int upcomingLimit = 6;
  static const int upcomingDays = 7;
  static const int recentActivityLimit = 5;
  static const int continueWatchingLimit = 6;

  final ShowsRepository repository;
  final DateTime Function() _now;

  DateTime _today() {
    final DateTime now = _now();

    return DateTime(now.year, now.month, now.day);
  }

  // ---------------------------------------------------------------------------
  // Initial load
  // ---------------------------------------------------------------------------

  Future<void> load() async {
    /*
     * Home sections deliberately load independently.
     *
     * A failure in one section must not prevent the remaining Home sections
     * from being loaded.
     */
    await Future.wait(<Future<void>>[
      loadContinueWatching(),
      loadPremieringToday(),
      loadUpcoming(),
      loadMissedRecently(),
      loadRecentActivity(),
    ]);
  }

  Future<bool> refresh() async {
    /*
   * Refresh every server-owned Home collection independently.
   *
   * Each section already preserves its existing content while loading and
   * when a request fails, so refresh must reuse those loaders instead of
   * implementing a second data-loading path.
   */
    await Future.wait(<Future<void>>[
      loadContinueWatching(),
      loadPremieringToday(),
      loadUpcoming(),
      loadMissedRecently(),
      loadRecentActivity(),
    ]);

    if (isClosed) {
      return false;
    }

    /*
   * A partial failure still leaves the remaining Home sections usable.
   *
   * Returning a boolean lets the presentation layer show one unobtrusive
   * refresh warning without replacing valid section content.
   */
    return state.continueWatchingError == null &&
        state.premieringTodayError == null &&
        state.upcomingError == null &&
        state.missedRecentlyError == null &&
        state.recentActivityError == null;
  }

  // ---------------------------------------------------------------------------
  // Continue Watching
  // ---------------------------------------------------------------------------

  Future<void> loadContinueWatching() async {
    if (state.isLoadingContinueWatching) {
      return;
    }

    emit(
      state.copyWith(
        isLoadingContinueWatching: true,
        clearContinueWatchingError: true,
      ),
    );

    try {
      final List<WatchNextShow> result = await repository.getWatchNext(
        limit: continueWatchingLimit,
      );

      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          continueWatching: result,
          isLoadingContinueWatching: false,
          clearContinueWatchingError: true,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          isLoadingContinueWatching: false,
          continueWatchingError: error,
        ),
      );
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          isLoadingContinueWatching: false,
          continueWatchingError: AppException.unknown(originalError: error),
        ),
      );
    }
  }

  Future<void> retryContinueWatching() {
    return loadContinueWatching();
  }

  Future<void> markContinueWatchingEpisodeWatched({required String episodeId}) {
    return _markEpisodeWatched(
      episodeId: episodeId,
      source: HomeWatchSource.continueWatching,
    );
  }

  // ---------------------------------------------------------------------------
  // Missed Recently
  // ---------------------------------------------------------------------------

  Future<void> loadMissedRecently() async {
    if (state.isLoadingMissedRecently) {
      return;
    }

    emit(
      state.copyWith(
        isLoadingMissedRecently: true,
        clearMissedRecentlyError: true,
      ),
    );

    try {
      /*
       * Missed Recently is a backend-owned Home collection.
       *
       * The server is responsible for:
       *
       * - the fourteen-day window;
       * - excluding today;
       * - regular Episodes only;
       * - Watching Shows only;
       * - excluding watched Episodes;
       * - newest-first ordering;
       * - the explicit Home limit.
       *
       * Keeping these rules server-side avoids duplicating domain logic
       * in Flutter and allows the database query to perform the filtering
       * efficiently.
       */
      final List<UpcomingItem> result = await repository.getMissedRecently();

      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          missedRecently: result,
          isLoadingMissedRecently: false,
          clearMissedRecentlyError: true,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          isLoadingMissedRecently: false,
          missedRecentlyError: error,
        ),
      );
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          isLoadingMissedRecently: false,
          missedRecentlyError: AppException.unknown(originalError: error),
        ),
      );
    }
  }

  Future<void> retryMissedRecently() {
    return loadMissedRecently();
  }

  Future<void> markMissedRecentlyEpisodeWatched({required String episodeId}) {
    return _markEpisodeWatched(
      episodeId: episodeId,
      source: HomeWatchSource.missedRecently,
    );
  }

  // ---------------------------------------------------------------------------
  // Recent Activity
  // ---------------------------------------------------------------------------

  Future<void> loadRecentActivity() async {
    if (state.isLoadingRecentActivity) {
      return;
    }

    emit(
      state.copyWith(
        isLoadingRecentActivity: true,
        clearRecentActivityError: true,
      ),
    );

    try {
      /*
       * Watch History is already ordered newest first by the backend.
       *
       * Home deliberately requests only a small fixed amount. Cursor
       * pagination remains owned by the full Watch History experience.
       */
      final WatchHistoryPage page = await repository.getWatchHistory(
        limit: recentActivityLimit,
      );

      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          recentActivity: page.items
              .take(recentActivityLimit)
              .toList(growable: false),
          isLoadingRecentActivity: false,
          clearRecentActivityError: true,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          isLoadingRecentActivity: false,
          recentActivityError: error,
        ),
      );
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          isLoadingRecentActivity: false,
          recentActivityError: AppException.unknown(originalError: error),
        ),
      );
    }
  }

  Future<void> retryRecentActivity() {
    return loadRecentActivity();
  }

  // ---------------------------------------------------------------------------
  // Premiering Today
  // ---------------------------------------------------------------------------

  Future<void> loadPremieringToday() async {
    if (state.isLoadingPremieringToday) {
      return;
    }

    emit(
      state.copyWith(
        isLoadingPremieringToday: true,
        clearPremieringTodayError: true,
      ),
    );

    final DateTime today = _today();

    try {
      final List<UpcomingItem> result = await repository.getUpcoming(
        fromDate: today,
        toDate: today,
        limit: premieringTodayLimit,
      );

      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          premieringToday: result,
          isLoadingPremieringToday: false,
          clearPremieringTodayError: true,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          isLoadingPremieringToday: false,
          premieringTodayError: error,
        ),
      );
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          isLoadingPremieringToday: false,
          premieringTodayError: AppException.unknown(originalError: error),
        ),
      );
    }
  }

  Future<void> retryPremieringToday() {
    return loadPremieringToday();
  }

  Future<void> markPremieringTodayEpisodeWatched({required String episodeId}) {
    return _markEpisodeWatched(
      episodeId: episodeId,
      source: HomeWatchSource.premieringToday,
    );
  }

  // ---------------------------------------------------------------------------
  // Unified watch action
  // ---------------------------------------------------------------------------

  Future<void> markEpisodeWatched({
    required String episodeId,
    required HomeWatchSource source,
  }) {
    return _markEpisodeWatched(episodeId: episodeId, source: source);
  }

  // ---------------------------------------------------------------------------
  // Upcoming
  // ---------------------------------------------------------------------------

  Future<void> loadUpcoming() async {
    if (state.isLoadingUpcoming) {
      return;
    }

    emit(state.copyWith(isLoadingUpcoming: true, clearUpcomingError: true));

    final DateTime today = _today();

    /*
     * Premiering Today owns today's Episodes.
     *
     * Upcoming therefore starts tomorrow.
     *
     * Example:
     *
     * today    = 17 Aug
     * fromDate = 18 Aug
     * toDate   = 24 Aug
     *
     * Exactly seven future calendar days.
     */
    final DateTime fromDate = today.add(const Duration(days: 1));

    final DateTime toDate = today.add(const Duration(days: upcomingDays));

    try {
      final List<UpcomingItem> result = await repository.getUpcoming(
        fromDate: fromDate,
        toDate: toDate,
        limit: upcomingLimit,
      );

      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          upcoming: result,
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

  Future<void> retryUpcoming() {
    return loadUpcoming();
  }

  // ---------------------------------------------------------------------------
  // Cross-section watch synchronization
  // ---------------------------------------------------------------------------

  Future<void> _markEpisodeWatched({
    required String episodeId,
    required HomeWatchSource source,
  }) async {
    if (state.isUpdatingEpisode) {
      return;
    }

    final bool sourceContainsEpisode = switch (source) {
      HomeWatchSource.premieringToday => _containsUpcomingEpisode(
        state.premieringToday,
        episodeId,
        requireUnwatched: true,
      ),
      HomeWatchSource.missedRecently => _containsUpcomingEpisode(
        state.missedRecently,
        episodeId,
        requireUnwatched: true,
      ),
      HomeWatchSource.continueWatching => _containsWatchNextEpisode(
        state.continueWatching,
        episodeId,
      ),
    };

    if (!sourceContainsEpisode) {
      return;
    }

    /*
     * Keep every locally affected collection so the optimistic state can be
     * restored as one consistent unit if the server mutation fails.
     */
    final List<WatchNextShow> previousContinueWatching = state.continueWatching;

    final List<UpcomingItem> previousPremieringToday = state.premieringToday;

    final List<UpcomingItem> previousMissedRecently = state.missedRecently;

    /*
     * Apply only deterministic local consequences.
     *
     * Continue Watching:
     * when the action originated here, remove the current Watch Next card
     * immediately. The replacement Episode, if any, belongs to the backend.
     *
     * Premiering Today:
     * if the same Episode is visible there, reflect the watched state
     * immediately.
     *
     * Missed Recently:
     * a watched Episode no longer qualifies, so remove it immediately.
     */
    emit(
      state.copyWith(
        continueWatching: source == HomeWatchSource.continueWatching
            ? _removeWatchNextEpisode(state.continueWatching, episodeId)
            : state.continueWatching,
        premieringToday: _markEpisodeWatchedInItems(
          state.premieringToday,
          episodeId,
        ),
        missedRecently: _removeEpisode(state.missedRecently, episodeId),
        updatingEpisodeId: episodeId,
        updatingEpisodeSource: source,
        clearWatchOperationError: true,
      ),
    );

    try {
      await repository.markEpisodeWatched(episodeId: episodeId);

      if (isClosed) {
        return;
      }

      /*
       * Watch Next is server-owned.
       *
       * Watching an Episode can:
       *
       * - advance the Show to the next Episode;
       * - remove it when the user becomes caught up;
       * - update progress counters.
       *
       * Fetch only this affected section instead of reloading the whole Home.
       */
      await loadContinueWatching();

      if (isClosed) {
        return;
      }

      /*
       * Recent Activity contains server-owned viewing-event data:
       *
       * - event_id;
       * - watched_at;
       * - watch_count;
       * - final ordering.
       *
       * Refresh this small section after a successful mutation.
       */
      await loadRecentActivity();

      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          clearUpdatingEpisodeId: true,
          clearUpdatingEpisodeSource: true,
          clearWatchOperationError: true,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      /*
       * Restore every collection changed optimistically.
       */
      emit(
        state.copyWith(
          continueWatching: previousContinueWatching,
          premieringToday: previousPremieringToday,
          missedRecently: previousMissedRecently,
          clearUpdatingEpisodeId: true,
          clearUpdatingEpisodeSource: true,
          watchOperationError: error,
        ),
      );
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        state.copyWith(
          continueWatching: previousContinueWatching,
          premieringToday: previousPremieringToday,
          missedRecently: previousMissedRecently,
          clearUpdatingEpisodeId: true,
          clearUpdatingEpisodeSource: true,
          watchOperationError: AppException.unknown(originalError: error),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  List<UpcomingItem> _markEpisodeWatchedInItems(
    List<UpcomingItem> items,
    String episodeId,
  ) {
    return items
        .map((UpcomingItem item) {
          if (item.episode.id != episodeId) {
            return item;
          }

          return item.copyWith(episode: item.episode.copyWith(isWatched: true));
        })
        .toList(growable: false);
  }

  List<UpcomingItem> _removeEpisode(
    List<UpcomingItem> items,
    String episodeId,
  ) {
    return items
        .where((UpcomingItem item) => item.episode.id != episodeId)
        .toList(growable: false);
  }

  List<WatchNextShow> _removeWatchNextEpisode(
    List<WatchNextShow> items,
    String episodeId,
  ) {
    return items
        .where((WatchNextShow item) => item.nextEpisode.id != episodeId)
        .toList(growable: false);
  }

  bool _containsUpcomingEpisode(
    List<UpcomingItem> items,
    String episodeId, {
    required bool requireUnwatched,
  }) {
    for (final UpcomingItem item in items) {
      if (item.episode.id != episodeId) {
        continue;
      }

      if (requireUnwatched && item.episode.isWatched) {
        return false;
      }

      return true;
    }

    return false;
  }

  bool _containsWatchNextEpisode(List<WatchNextShow> items, String episodeId) {
    return items.any((WatchNextShow item) => item.nextEpisode.id == episodeId);
  }
}
