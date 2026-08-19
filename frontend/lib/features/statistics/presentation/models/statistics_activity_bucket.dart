import 'package:equatable/equatable.dart';

enum StatisticsActivityBucketGranularity { day, week, month, year }

final class StatisticsActivityBucket extends Equatable {
  const StatisticsActivityBucket({
    required this.startDate,
    required this.endDate,
    required this.granularity,
    required this.episodesWatched,
    required this.moviesWatched,
    required this.episodeWatchTimeMinutes,
    required this.movieWatchTimeMinutes,
  });

  final DateTime startDate;
  final DateTime endDate;

  final StatisticsActivityBucketGranularity granularity;

  final int episodesWatched;
  final int moviesWatched;

  final int episodeWatchTimeMinutes;
  final int movieWatchTimeMinutes;

  int get watchTimeMinutes {
    return episodeWatchTimeMinutes + movieWatchTimeMinutes;
  }

  @override
  List<Object?> get props => <Object?>[
    startDate,
    endDate,
    granularity,
    episodesWatched,
    moviesWatched,
    episodeWatchTimeMinutes,
    movieWatchTimeMinutes,
  ];
}
