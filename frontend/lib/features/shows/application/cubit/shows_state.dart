import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/shows/domain/models/library_show.dart';
import 'package:sofawatch/features/shows/domain/models/stale_watching_show.dart';
import 'package:sofawatch/features/shows/domain/models/watch_history_item.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_show.dart';

final class ShowsState extends Equatable {
  const ShowsState({
    this.libraryShows = const <LibraryShow>[],
    this.watchNext = const <WatchNextShow>[],
    this.staleWatching = const <StaleWatchingShow>[],
    this.watchHistory = const <WatchHistoryItem>[],
    this.hasLoadedWatchHistory = false,
    this.watchHistoryNextCursor,
    this.hasMoreWatchHistory = false,
    this.isLoadingWatchHistory = false,
    this.isLoadingMoreWatchHistory = false,
    this.isLoading = false,
    this.watchNextError,
    this.staleWatchingError,
    this.watchHistoryError,
    this.error,
    this.updatingWatchNextEpisodeId,
    this.watchNextOperationError,
    this.startingShowId,
    this.startShowError,
    this.updatingWatchHistoryEpisodeId,
    this.watchHistoryOperationError,
  });

  final List<LibraryShow> libraryShows;

  final List<WatchNextShow> watchNext;

  final List<StaleWatchingShow> staleWatching;

  final List<WatchHistoryItem> watchHistory;

  final bool hasLoadedWatchHistory;

  final String? watchHistoryNextCursor;

  final bool hasMoreWatchHistory;

  final bool isLoadingWatchHistory;

  final bool isLoadingMoreWatchHistory;

  final bool isLoading;
  final String? startingShowId;
  final AppException? startShowError;

  /// Episode currently being marked as watched from the Watch Next section.
  final String? updatingWatchNextEpisodeId;

  /// Failure while changing Episode progress from Watch Next.
  ///
  /// Existing Watch Next data must remain available when the operation fails.
  final AppException? watchNextOperationError;

  /// Failure of the supplementary Watch Next block.
  ///
  /// This must not make the entire Shows screen unusable.
  final AppException? watchNextError;

  /// Failure of the supplementary Haven't Watched in a While block.
  ///
  /// This must not make the entire Shows screen unusable.
  final AppException? staleWatchingError;

  /// Failure while loading Watch History.
  ///
  /// Existing History items must remain available when pagination fails.
  final AppException? watchHistoryError;

  /// Fatal failure while loading the core Shows/Library data.
  final AppException? error;

  /// Episode currently being changed from Watch History.
  final String? updatingWatchHistoryEpisodeId;

  /// Failure while changing Episode progress from Watch History.
  ///
  /// Existing Watch History must remain available if the operation fails.
  final AppException? watchHistoryOperationError;

  bool get hasFatalError => error != null;

  bool get isLibraryEmpty => libraryShows.isEmpty;

  bool get isWatchNextEmpty => watchNext.isEmpty;

  bool get isStaleWatchingEmpty => staleWatching.isEmpty;

  bool isShowStarting(String showId) {
    return startingShowId == showId;
  }

  bool get isWatchHistoryEmpty => watchHistory.isEmpty;
  bool isWatchNextEpisodeUpdating(String episodeId) {
    return updatingWatchNextEpisodeId == episodeId;
  }

  bool isWatchHistoryEpisodeUpdating(String episodeId) {
    return updatingWatchHistoryEpisodeId == episodeId;
  }

  List<LibraryShow> get haventStarted {
    return libraryShows
        .where((LibraryShow show) => show.status == LibraryStatus.planning)
        .toList(growable: false);
  }

  bool get isHaventStartedEmpty => haventStarted.isEmpty;

  ShowsState copyWith({
    List<LibraryShow>? libraryShows,
    List<WatchNextShow>? watchNext,
    List<StaleWatchingShow>? staleWatching,
    List<WatchHistoryItem>? watchHistory,
    String? watchHistoryNextCursor,
    bool clearWatchHistoryNextCursor = false,
    bool? hasMoreWatchHistory,
    bool? isLoadingWatchHistory,
    bool? isLoadingMoreWatchHistory,
    bool? isLoading,
    AppException? watchNextError,
    bool clearWatchNextError = false,
    AppException? staleWatchingError,
    bool clearStaleWatchingError = false,
    AppException? watchHistoryError,
    bool clearWatchHistoryError = false,
    AppException? error,
    bool clearError = false,
    bool? hasLoadedWatchHistory,
    String? updatingWatchNextEpisodeId,
    bool clearUpdatingWatchNextEpisodeId = false,
    AppException? watchNextOperationError,
    bool clearWatchNextOperationError = false,
    String? startingShowId,
    bool clearStartingShowId = false,
    AppException? startShowError,
    bool clearStartShowError = false,
    String? updatingWatchHistoryEpisodeId,
    bool clearUpdatingWatchHistoryEpisodeId = false,
    AppException? watchHistoryOperationError,
    bool clearWatchHistoryOperationError = false,
  }) {
    return ShowsState(
      libraryShows: libraryShows ?? this.libraryShows,
      watchNext: watchNext ?? this.watchNext,
      staleWatching: staleWatching ?? this.staleWatching,
      watchHistory: watchHistory ?? this.watchHistory,
      watchHistoryNextCursor: clearWatchHistoryNextCursor
          ? null
          : watchHistoryNextCursor ?? this.watchHistoryNextCursor,
      hasMoreWatchHistory: hasMoreWatchHistory ?? this.hasMoreWatchHistory,
      isLoadingWatchHistory:
          isLoadingWatchHistory ?? this.isLoadingWatchHistory,
      isLoadingMoreWatchHistory:
          isLoadingMoreWatchHistory ?? this.isLoadingMoreWatchHistory,
      isLoading: isLoading ?? this.isLoading,
      hasLoadedWatchHistory:
          hasLoadedWatchHistory ?? this.hasLoadedWatchHistory,
      updatingWatchNextEpisodeId: clearUpdatingWatchNextEpisodeId
          ? null
          : updatingWatchNextEpisodeId ?? this.updatingWatchNextEpisodeId,
      updatingWatchHistoryEpisodeId: clearUpdatingWatchHistoryEpisodeId
          ? null
          : updatingWatchHistoryEpisodeId ?? this.updatingWatchHistoryEpisodeId,

      watchHistoryOperationError: clearWatchHistoryOperationError
          ? null
          : watchHistoryOperationError ?? this.watchHistoryOperationError,
      watchNextOperationError: clearWatchNextOperationError
          ? null
          : watchNextOperationError ?? this.watchNextOperationError,
      watchNextError: clearWatchNextError
          ? null
          : watchNextError ?? this.watchNextError,
      staleWatchingError: clearStaleWatchingError
          ? null
          : staleWatchingError ?? this.staleWatchingError,
      watchHistoryError: clearWatchHistoryError
          ? null
          : watchHistoryError ?? this.watchHistoryError,
      startingShowId: clearStartingShowId
          ? null
          : startingShowId ?? this.startingShowId,

      startShowError: clearStartShowError
          ? null
          : startShowError ?? this.startShowError,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    libraryShows,
    watchNext,
    staleWatching,
    watchHistory,
    hasLoadedWatchHistory,
    watchHistoryNextCursor,
    hasMoreWatchHistory,
    isLoadingWatchHistory,
    isLoadingMoreWatchHistory,
    isLoading,
    updatingWatchNextEpisodeId,
    watchNextOperationError,
    watchNextError,
    staleWatchingError,
    watchHistoryError,
    startingShowId,
    updatingWatchHistoryEpisodeId,
    watchHistoryOperationError,
    startShowError,
    error,
  ];
}
