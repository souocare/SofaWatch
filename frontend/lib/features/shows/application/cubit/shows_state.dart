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

  bool get hasFatalError => error != null;

  bool get isLibraryEmpty => libraryShows.isEmpty;

  bool get isWatchNextEmpty => watchNext.isEmpty;

  bool get isStaleWatchingEmpty => staleWatching.isEmpty;

  bool get isWatchHistoryEmpty => watchHistory.isEmpty;

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
      watchNextError: clearWatchNextError
          ? null
          : watchNextError ?? this.watchNextError,
      staleWatchingError: clearStaleWatchingError
          ? null
          : staleWatchingError ?? this.staleWatchingError,
      watchHistoryError: clearWatchHistoryError
          ? null
          : watchHistoryError ?? this.watchHistoryError,
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
    watchNextError,
    staleWatchingError,
    watchHistoryError,
    error,
  ];
}
