import 'package:sofawatch/features/statistics/domain/models/statistics_summary.dart';

final class MediaViewingStatisticsDto {
  const MediaViewingStatisticsDto({
    required this.watchCount,
    required this.uniqueCount,
    required this.rewatchCount,
    required this.watchTimeMinutes,
    required this.rewatchTimeMinutes,
  });

  factory MediaViewingStatisticsDto.fromJson(Map<String, dynamic> json) {
    return MediaViewingStatisticsDto(
      watchCount: _readNonNegativeInt(json, 'watch_count'),
      uniqueCount: _readNonNegativeInt(json, 'unique_count'),
      rewatchCount: _readNonNegativeInt(json, 'rewatch_count'),
      watchTimeMinutes: _readNonNegativeInt(json, 'watch_time_minutes'),
      rewatchTimeMinutes: _readNonNegativeInt(json, 'rewatch_time_minutes'),
    );
  }

  final int watchCount;
  final int uniqueCount;
  final int rewatchCount;
  final int watchTimeMinutes;
  final int rewatchTimeMinutes;

  MediaViewingStatistics toDomain() {
    return MediaViewingStatistics(
      watchCount: watchCount,
      uniqueCount: uniqueCount,
      rewatchCount: rewatchCount,
      watchTimeMinutes: watchTimeMinutes,
      rewatchTimeMinutes: rewatchTimeMinutes,
    );
  }
}

final class StatisticsSummaryDto {
  const StatisticsSummaryDto({
    required this.showsWatched,
    required this.episodes,
    required this.movies,
    required this.watchTimeMinutes,
    required this.rewatchTimeMinutes,
  });

  factory StatisticsSummaryDto.fromJson(Map<String, dynamic> json) {
    return StatisticsSummaryDto(
      showsWatched: _readNonNegativeInt(json, 'shows_watched'),
      episodes: MediaViewingStatisticsDto.fromJson(
        _readObject(json, 'episodes'),
      ),
      movies: MediaViewingStatisticsDto.fromJson(_readObject(json, 'movies')),
      watchTimeMinutes: _readNonNegativeInt(json, 'watch_time_minutes'),
      rewatchTimeMinutes: _readNonNegativeInt(json, 'rewatch_time_minutes'),
    );
  }

  final int showsWatched;

  final MediaViewingStatisticsDto episodes;
  final MediaViewingStatisticsDto movies;

  final int watchTimeMinutes;
  final int rewatchTimeMinutes;

  StatisticsSummary toDomain() {
    return StatisticsSummary(
      showsWatched: showsWatched,
      episodes: episodes.toDomain(),
      movies: movies.toDomain(),
      watchTimeMinutes: watchTimeMinutes,
      rewatchTimeMinutes: rewatchTimeMinutes,
    );
  }
}

Map<String, dynamic> _readObject(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! Map<String, dynamic>) {
    throw FormatException('Expected "$key" to be an object.');
  }

  return value;
}

int _readNonNegativeInt(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! int) {
    throw FormatException('Expected "$key" to be an integer.');
  }

  if (value < 0) {
    throw FormatException('Expected "$key" to be non-negative.');
  }

  return value;
}
