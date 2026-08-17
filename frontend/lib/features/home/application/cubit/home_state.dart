import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/shows/domain/models/upcoming_item.dart';

final class HomeState extends Equatable {
  const HomeState({
    this.premieringToday = const <UpcomingItem>[],
    this.isLoadingPremieringToday = false,
    this.premieringTodayError,
    this.updatingPremieringTodayEpisodeId,
    this.premieringTodayOperationError,
    this.upcoming = const <UpcomingItem>[],
    this.isLoadingUpcoming = false,
    this.upcomingError,
  });

  // ---------------------------------------------------------------------------
  // Premiering Today
  // ---------------------------------------------------------------------------

  final List<UpcomingItem> premieringToday;

  final bool isLoadingPremieringToday;

  final AppException? premieringTodayError;

  final String? updatingPremieringTodayEpisodeId;

  final AppException? premieringTodayOperationError;

  bool get isUpdatingPremieringTodayEpisode {
    return updatingPremieringTodayEpisodeId != null;
  }

  // ---------------------------------------------------------------------------
  // Upcoming
  // ---------------------------------------------------------------------------

  final List<UpcomingItem> upcoming;

  final bool isLoadingUpcoming;

  final AppException? upcomingError;

  HomeState copyWith({
    List<UpcomingItem>? premieringToday,
    bool? isLoadingPremieringToday,
    AppException? premieringTodayError,
    bool clearPremieringTodayError = false,
    String? updatingPremieringTodayEpisodeId,
    bool clearUpdatingPremieringTodayEpisodeId = false,
    AppException? premieringTodayOperationError,
    bool clearPremieringTodayOperationError = false,
    List<UpcomingItem>? upcoming,
    bool? isLoadingUpcoming,
    AppException? upcomingError,
    bool clearUpcomingError = false,
  }) {
    return HomeState(
      premieringToday: premieringToday ?? this.premieringToday,
      isLoadingPremieringToday:
          isLoadingPremieringToday ?? this.isLoadingPremieringToday,
      premieringTodayError: clearPremieringTodayError
          ? null
          : premieringTodayError ?? this.premieringTodayError,
      updatingPremieringTodayEpisodeId: clearUpdatingPremieringTodayEpisodeId
          ? null
          : updatingPremieringTodayEpisodeId ??
                this.updatingPremieringTodayEpisodeId,
      premieringTodayOperationError: clearPremieringTodayOperationError
          ? null
          : premieringTodayOperationError ?? this.premieringTodayOperationError,
      upcoming: upcoming ?? this.upcoming,
      isLoadingUpcoming: isLoadingUpcoming ?? this.isLoadingUpcoming,
      upcomingError: clearUpcomingError
          ? null
          : upcomingError ?? this.upcomingError,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    premieringToday,
    isLoadingPremieringToday,
    premieringTodayError,
    updatingPremieringTodayEpisodeId,
    premieringTodayOperationError,
    upcoming,
    isLoadingUpcoming,
    upcomingError,
  ];
}
