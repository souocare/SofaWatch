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
  });

  final List<UpcomingItem> premieringToday;

  final bool isLoadingPremieringToday;

  final AppException? premieringTodayError;

  final String? updatingPremieringTodayEpisodeId;

  final AppException? premieringTodayOperationError;

  bool get isUpdatingPremieringTodayEpisode {
    return updatingPremieringTodayEpisodeId != null;
  }

  HomeState copyWith({
    List<UpcomingItem>? premieringToday,
    bool? isLoadingPremieringToday,
    AppException? premieringTodayError,
    bool clearPremieringTodayError = false,
    String? updatingPremieringTodayEpisodeId,
    bool clearUpdatingPremieringTodayEpisodeId = false,
    AppException? premieringTodayOperationError,
    bool clearPremieringTodayOperationError = false,
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
    );
  }

  @override
  List<Object?> get props => <Object?>[
    premieringToday,
    isLoadingPremieringToday,
    premieringTodayError,
    updatingPremieringTodayEpisodeId,
    premieringTodayOperationError,
  ];
}
