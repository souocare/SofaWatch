import 'package:sofawatch/features/statistics/domain/models/weekly_statistics.dart';

final class WeeklyStatisticsDto {
  const WeeklyStatisticsDto({
    required this.weekStart,
    required this.weekEnd,
    required this.episodesWatched,
    required this.moviesWatched,
    required this.watchTimeMinutes,
  });

  factory WeeklyStatisticsDto.fromJson(Map<String, dynamic> json) {
    return WeeklyStatisticsDto(
      weekStart: _requiredDate(json, 'week_start'),
      weekEnd: _requiredDate(json, 'week_end'),
      episodesWatched: _requiredNonNegativeInt(json, 'episodes_watched'),
      moviesWatched: _requiredNonNegativeInt(json, 'movies_watched'),
      watchTimeMinutes: _requiredNonNegativeInt(json, 'watch_time_minutes'),
    );
  }

  final DateTime weekStart;
  final DateTime weekEnd;

  final int episodesWatched;
  final int moviesWatched;
  final int watchTimeMinutes;

  WeeklyStatistics toDomain() {
    return WeeklyStatistics(
      weekStart: weekStart,
      weekEnd: weekEnd,
      episodesWatched: episodesWatched,
      moviesWatched: moviesWatched,
      watchTimeMinutes: watchTimeMinutes,
    );
  }
}

DateTime _requiredDate(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Invalid $key.');
  }

  final DateTime? parsed = DateTime.tryParse(value);

  if (parsed == null) {
    throw FormatException('Invalid $key.');
  }

  return parsed;
}

int _requiredNonNegativeInt(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! int || value < 0) {
    throw FormatException('Invalid $key.');
  }

  return value;
}
