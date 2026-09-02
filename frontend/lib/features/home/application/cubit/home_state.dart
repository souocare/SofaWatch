import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/history/domain/models/history_item.dart';
import 'package:sofawatch/features/home/application/models/home_watch_source.dart';
import 'package:sofawatch/features/shows/domain/models/upcoming_item.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_show.dart';

final class HomeState extends Equatable {
  const HomeState({
    this.premieringToday = const <UpcomingItem>[],
    this.isLoadingPremieringToday = false,
    this.premieringTodayError,
    this.upcoming = const <UpcomingItem>[],
    this.isLoadingUpcoming = false,
    this.upcomingError,
    this.missedRecently = const <UpcomingItem>[],
    this.isLoadingMissedRecently = false,
    this.missedRecentlyError,
    this.recentActivity = const <HistoryItem>[],
    this.isLoadingRecentActivity = false,
    this.recentActivityError,
    this.updatingEpisodeId,
    this.updatingEpisodeSource,
    this.watchOperationError,
    this.continueWatching = const <WatchNextShow>[],
    this.isLoadingContinueWatching = false,
    this.continueWatchingError,
  });

  // ---------------------------------------------------------------------------
  // Premiering Today
  // ---------------------------------------------------------------------------

  final List<UpcomingItem> premieringToday;

  final bool isLoadingPremieringToday;

  final AppException? premieringTodayError;

  // ---------------------------------------------------------------------------
  // Upcoming
  // ---------------------------------------------------------------------------

  final List<UpcomingItem> upcoming;

  final bool isLoadingUpcoming;

  final AppException? upcomingError;

  // ---------------------------------------------------------------------------
  // Missed Recently
  // ---------------------------------------------------------------------------

  final List<UpcomingItem> missedRecently;

  final bool isLoadingMissedRecently;

  final AppException? missedRecentlyError;

  // ---------------------------------------------------------------------------
  // Recent Activity
  // ---------------------------------------------------------------------------

  final List<HistoryItem> recentActivity;

  final bool isLoadingRecentActivity;

  final AppException? recentActivityError;

  // ---------------------------------------------------------------------------
  // Shared watched mutation
  // ---------------------------------------------------------------------------

  final String? updatingEpisodeId;

  final HomeWatchSource? updatingEpisodeSource;

  final AppException? watchOperationError;

  // ---------------------------------------------------------------------------
  // Continue Watching
  // ---------------------------------------------------------------------------

  final List<WatchNextShow> continueWatching;

  final bool isLoadingContinueWatching;

  final AppException? continueWatchingError;

  bool get isUpdatingEpisode {
    return updatingEpisodeId != null;
  }

  bool isUpdatingEpisodeFrom({
    required String episodeId,
    required HomeWatchSource source,
  }) {
    return updatingEpisodeId == episodeId && updatingEpisodeSource == source;
  }

  HomeState copyWith({
    List<UpcomingItem>? premieringToday,
    bool? isLoadingPremieringToday,
    AppException? premieringTodayError,
    bool clearPremieringTodayError = false,

    List<UpcomingItem>? upcoming,
    bool? isLoadingUpcoming,
    AppException? upcomingError,
    bool clearUpcomingError = false,

    List<UpcomingItem>? missedRecently,
    bool? isLoadingMissedRecently,
    AppException? missedRecentlyError,
    bool clearMissedRecentlyError = false,

    List<HistoryItem>? recentActivity,
    bool? isLoadingRecentActivity,
    AppException? recentActivityError,
    bool clearRecentActivityError = false,

    String? updatingEpisodeId,
    bool clearUpdatingEpisodeId = false,
    HomeWatchSource? updatingEpisodeSource,
    bool clearUpdatingEpisodeSource = false,
    AppException? watchOperationError,
    bool clearWatchOperationError = false,

    List<WatchNextShow>? continueWatching,
    bool? isLoadingContinueWatching,
    AppException? continueWatchingError,
    bool clearContinueWatchingError = false,
  }) {
    return HomeState(
      // Premiering Today
      premieringToday: premieringToday ?? this.premieringToday,
      isLoadingPremieringToday:
          isLoadingPremieringToday ?? this.isLoadingPremieringToday,
      premieringTodayError: clearPremieringTodayError
          ? null
          : premieringTodayError ?? this.premieringTodayError,

      // Upcoming
      upcoming: upcoming ?? this.upcoming,
      isLoadingUpcoming: isLoadingUpcoming ?? this.isLoadingUpcoming,
      upcomingError: clearUpcomingError
          ? null
          : upcomingError ?? this.upcomingError,

      // Missed Recently
      missedRecently: missedRecently ?? this.missedRecently,
      isLoadingMissedRecently:
          isLoadingMissedRecently ?? this.isLoadingMissedRecently,
      missedRecentlyError: clearMissedRecentlyError
          ? null
          : missedRecentlyError ?? this.missedRecentlyError,

      // Recent Activity
      recentActivity: recentActivity ?? this.recentActivity,
      isLoadingRecentActivity:
          isLoadingRecentActivity ?? this.isLoadingRecentActivity,
      recentActivityError: clearRecentActivityError
          ? null
          : recentActivityError ?? this.recentActivityError,

      // Shared watched mutation
      updatingEpisodeId: clearUpdatingEpisodeId
          ? null
          : updatingEpisodeId ?? this.updatingEpisodeId,
      updatingEpisodeSource: clearUpdatingEpisodeSource
          ? null
          : updatingEpisodeSource ?? this.updatingEpisodeSource,
      watchOperationError: clearWatchOperationError
          ? null
          : watchOperationError ?? this.watchOperationError,

      continueWatching: continueWatching ?? this.continueWatching,
      isLoadingContinueWatching:
          isLoadingContinueWatching ?? this.isLoadingContinueWatching,
      continueWatchingError: clearContinueWatchingError
          ? null
          : continueWatchingError ?? this.continueWatchingError,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    // Premiering Today
    premieringToday,
    isLoadingPremieringToday,
    premieringTodayError,

    // Upcoming
    upcoming,
    isLoadingUpcoming,
    upcomingError,

    // Missed Recently
    missedRecently,
    isLoadingMissedRecently,
    missedRecentlyError,

    // Recent Activity
    recentActivity,
    isLoadingRecentActivity,
    recentActivityError,

    // Shared watched mutation
    updatingEpisodeId,
    updatingEpisodeSource,
    watchOperationError,

    continueWatching,
    isLoadingContinueWatching,
    continueWatchingError,
  ];
}
