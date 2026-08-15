import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/shows/domain/models/library_show.dart';
import 'package:sofawatch/features/shows/domain/models/stale_watching_show.dart';
import 'package:sofawatch/features/shows/domain/models/watch_history_item.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_show.dart';
import 'package:sofawatch/features/shows/domain/models/upcoming_item.dart';

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
    this.updatingWatchHistoryEventId,
    this.watchHistoryOperationError,
    this.upcoming = const <UpcomingItem>[],
    this.hasLoadedUpcoming = false,
    this.upcomingFromDate,
    this.upcomingToDate,
    this.isLoadingUpcoming = false,
    this.isLoadingEarlierUpcoming = false,
    this.upcomingError,
    this.earlierUpcomingError,
    this.upcomingReferenceDate,
    this.updatingUpcomingEpisodeId,
    this.upcomingOperationError,
    this.isRefreshing = false,
    this.refreshError,
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
  final DateTime? upcomingReferenceDate;

  final bool isLoading;
  final String? startingShowId;
  final AppException? startShowError;

  /// Episode currently being marked as watched from the Watch Next section.
  final String? updatingWatchNextEpisodeId;
  final AppException? earlierUpcomingError;

  /// Episode currently being marked as watched from Upcoming.
  final String? updatingUpcomingEpisodeId;

  /// Failure while changing Episode progress from Upcoming.
  ///
  /// Existing Upcoming data must remain visible when the operation fails.
  final AppException? upcomingOperationError;

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

  /// Watch History event currently being changed.
  final String? updatingWatchHistoryEventId;

  /// Failure while changing Episode progress from Watch History.
  ///
  /// Existing Watch History must remain available if the operation fails.
  final AppException? watchHistoryOperationError;
  final List<UpcomingItem> upcoming;

  /// Whether the initial Upcoming timeline has been loaded successfully.
  final bool hasLoadedUpcoming;

  /// Inclusive oldest date currently covered by the Upcoming timeline.
  ///
  /// Null before the first ranged load has completed.
  final DateTime? upcomingFromDate;

  /// Inclusive newest date explicitly covered by the timeline.
  ///
  /// Null means that the loaded range has no upper date boundary and therefore
  /// includes every known future Episode returned by the backend.
  final DateTime? upcomingToDate;

  /// Loading the initial or complete Upcoming timeline.
  final bool isLoadingUpcoming;

  /// Loading an additional historical range above the current timeline.
  final bool isLoadingEarlierUpcoming;

  /// Whether the Shows screen is being explicitly refreshed.
  ///
  /// Existing content remains visible while this is true.
  final bool isRefreshing;

  /// Failure while explicitly refreshing the core Shows data.
  ///
  /// A refresh failure must not replace already loaded content.
  final AppException? refreshError;

  /// Failure while loading the Upcoming timeline.
  ///
  /// Upcoming is supplementary data and must not make the Watch List unusable.
  final AppException? upcomingError;
  bool get isUpcomingEmpty => upcoming.isEmpty;

  bool get canLoadEarlierUpcoming {
    return hasLoadedUpcoming &&
        upcomingFromDate != null &&
        !isLoadingUpcoming &&
        !isLoadingEarlierUpcoming;
  }

  bool isUpcomingEpisodeUpdating(String episodeId) {
    return updatingUpcomingEpisodeId == episodeId;
  }

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

  bool isWatchHistoryEventUpdating(String eventId) {
    return updatingWatchHistoryEventId == eventId;
  }

  List<LibraryShow> get haventStarted {
    return libraryShows
        .where((LibraryShow show) => show.status == LibraryStatus.planning)
        .toList(growable: false);
  }

  bool get isHaventStartedEmpty => haventStarted.isEmpty;

  List<LibraryShow> get upToDate {
    return libraryShows
        .where(
          (LibraryShow show) =>
              show.status == LibraryStatus.watching && show.progress.caughtUp,
        )
        .toList(growable: false);
  }

  bool get isUpToDateEmpty => upToDate.isEmpty;

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
    String? updatingWatchHistoryEventId,
    bool clearUpdatingWatchHistoryEventId = false,
    AppException? watchHistoryOperationError,
    bool clearWatchHistoryOperationError = false,
    bool? isRefreshing,
    AppException? refreshError,
    bool clearRefreshError = false,

    // Upcoming
    List<UpcomingItem>? upcoming,
    bool? hasLoadedUpcoming,
    DateTime? upcomingFromDate,
    bool clearUpcomingFromDate = false,
    DateTime? upcomingToDate,
    bool clearUpcomingToDate = false,
    bool? isLoadingUpcoming,
    bool? isLoadingEarlierUpcoming,
    AppException? upcomingError,
    bool clearUpcomingError = false,
    AppException? earlierUpcomingError,
    bool clearEarlierUpcomingError = false,
    String? updatingUpcomingEpisodeId,
    bool clearUpdatingUpcomingEpisodeId = false,
    AppException? upcomingOperationError,
    bool clearUpcomingOperationError = false,

    DateTime? upcomingReferenceDate,
    bool clearUpcomingReferenceDate = false,
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

      // Upcoming
      upcoming: upcoming ?? this.upcoming,

      isRefreshing: isRefreshing ?? this.isRefreshing,

      refreshError: clearRefreshError
          ? null
          : refreshError ?? this.refreshError,

      hasLoadedUpcoming: hasLoadedUpcoming ?? this.hasLoadedUpcoming,

      upcomingFromDate: clearUpcomingFromDate
          ? null
          : upcomingFromDate ?? this.upcomingFromDate,

      upcomingToDate: clearUpcomingToDate
          ? null
          : upcomingToDate ?? this.upcomingToDate,

      updatingUpcomingEpisodeId: clearUpdatingUpcomingEpisodeId
          ? null
          : updatingUpcomingEpisodeId ?? this.updatingUpcomingEpisodeId,

      upcomingOperationError: clearUpcomingOperationError
          ? null
          : upcomingOperationError ?? this.upcomingOperationError,

      isLoadingUpcoming: isLoadingUpcoming ?? this.isLoadingUpcoming,

      isLoadingEarlierUpcoming:
          isLoadingEarlierUpcoming ?? this.isLoadingEarlierUpcoming,

      upcomingError: clearUpcomingError
          ? null
          : upcomingError ?? this.upcomingError,

      earlierUpcomingError: clearEarlierUpcomingError
          ? null
          : earlierUpcomingError ?? this.earlierUpcomingError,

      updatingWatchNextEpisodeId: clearUpdatingWatchNextEpisodeId
          ? null
          : updatingWatchNextEpisodeId ?? this.updatingWatchNextEpisodeId,

      updatingWatchHistoryEventId: clearUpdatingWatchHistoryEventId
          ? null
          : updatingWatchHistoryEventId ?? this.updatingWatchHistoryEventId,

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

      upcomingReferenceDate: clearUpcomingReferenceDate
          ? null
          : upcomingReferenceDate ?? this.upcomingReferenceDate,

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
    updatingWatchHistoryEventId,
    watchHistoryOperationError,
    startShowError,
    error,

    // Upcoming
    upcoming,
    hasLoadedUpcoming,
    upcomingFromDate,
    upcomingToDate,
    isLoadingUpcoming,
    isLoadingEarlierUpcoming,
    upcomingError,
    earlierUpcomingError,
    upcomingReferenceDate,
    updatingUpcomingEpisodeId,
    upcomingOperationError,

    isRefreshing,
    refreshError,
  ];
}
