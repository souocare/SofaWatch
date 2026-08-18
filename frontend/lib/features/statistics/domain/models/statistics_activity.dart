import 'package:equatable/equatable.dart';

final class StatisticsActivity extends Equatable {
  const StatisticsActivity({
    required this.startDate,
    required this.endDate,
    required this.days,
  });

  final DateTime startDate;
  final DateTime endDate;
  final List<DailyStatisticsActivity> days;

  @override
  List<Object?> get props => <Object?>[startDate, endDate, days];
}

final class DailyStatisticsActivity extends Equatable {
  const DailyStatisticsActivity({
    required this.day,
    required this.episodesWatched,
    required this.moviesWatched,
    required this.episodeWatchTimeMinutes,
    required this.movieWatchTimeMinutes,
    required this.watchTimeMinutes,
  });

  final DateTime day;

  final int episodesWatched;
  final int moviesWatched;

  final int episodeWatchTimeMinutes;
  final int movieWatchTimeMinutes;
  final int watchTimeMinutes;

  @override
  List<Object?> get props => <Object?>[
    day,
    episodesWatched,
    moviesWatched,
    episodeWatchTimeMinutes,
    movieWatchTimeMinutes,
    watchTimeMinutes,
  ];
}
