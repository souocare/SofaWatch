import 'package:equatable/equatable.dart';

final class MediaViewingStatistics extends Equatable {
  const MediaViewingStatistics({
    required this.watchCount,
    required this.uniqueCount,
    required this.rewatchCount,
    required this.watchTimeMinutes,
    required this.rewatchTimeMinutes,
  });

  final int watchCount;
  final int uniqueCount;
  final int rewatchCount;
  final int watchTimeMinutes;
  final int rewatchTimeMinutes;

  @override
  List<Object?> get props => <Object?>[
    watchCount,
    uniqueCount,
    rewatchCount,
    watchTimeMinutes,
    rewatchTimeMinutes,
  ];
}

final class StatisticsSummary extends Equatable {
  const StatisticsSummary({
    required this.showsWatched,
    required this.episodes,
    required this.movies,
    required this.watchTimeMinutes,
    required this.rewatchTimeMinutes,
  });

  final int showsWatched;

  final MediaViewingStatistics episodes;
  final MediaViewingStatistics movies;

  final int watchTimeMinutes;
  final int rewatchTimeMinutes;

  /*
   * Convenience values used by compact summary surfaces such as Profile.
   *
   * These deliberately represent watch events, so Rewatches are included.
   */
  int get episodesWatched => episodes.watchCount;

  int get moviesWatched => movies.watchCount;

  @override
  List<Object?> get props => <Object?>[
    showsWatched,
    episodes,
    movies,
    watchTimeMinutes,
    rewatchTimeMinutes,
  ];
}
