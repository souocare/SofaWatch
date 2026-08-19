import 'package:equatable/equatable.dart';

final class StatisticsBacklog extends Equatable {
  const StatisticsBacklog({
    required this.unwatchedAiredEpisodes,
    required this.plannedMovies,
    required this.futureWatchTimeMinutes,
    required this.catchUpSpeedEpisodesPerWeek,
    required this.backlogTrend,
    required this.backlogTrendEpisodeDelta,
  });

  final int unwatchedAiredEpisodes;
  final int plannedMovies;

  final int futureWatchTimeMinutes;

  final double catchUpSpeedEpisodesPerWeek;

  /// Backend-defined backlog direction.
  ///
  /// Expected values:
  /// - growing
  /// - shrinking
  /// - stable
  final String backlogTrend;

  /// Change in backlog Episodes over the backend comparison window.
  ///
  /// Positive means the backlog grew.
  /// Negative means it shrank.
  /// Zero means it remained stable.
  final int backlogTrendEpisodeDelta;

  @override
  List<Object?> get props => <Object?>[
    unwatchedAiredEpisodes,
    plannedMovies,
    futureWatchTimeMinutes,
    catchUpSpeedEpisodesPerWeek,
    backlogTrend,
    backlogTrendEpisodeDelta,
  ];
}
