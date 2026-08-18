import 'package:sofawatch/features/statistics/domain/models/statistics_activity.dart';

final class StatisticsActivityDto {
  const StatisticsActivityDto({
    required this.startDate,
    required this.endDate,
    required this.days,
  });

  factory StatisticsActivityDto.fromJson(Map<String, dynamic> json) {
    final String startDate = _readString(json, 'start_date');

    final String endDate = _readString(json, 'end_date');

    final Object? rawDays = json['days'];

    if (rawDays is! List<dynamic>) {
      throw const FormatException('Expected "days" to be a list.');
    }

    return StatisticsActivityDto(
      startDate: _parseDate(startDate, key: 'start_date'),
      endDate: _parseDate(endDate, key: 'end_date'),
      days: rawDays
          .map((Object? value) {
            if (value is! Map<String, dynamic>) {
              throw const FormatException(
                'Expected every activity day to be an object.',
              );
            }

            return DailyStatisticsActivityDto.fromJson(value);
          })
          .toList(growable: false),
    );
  }

  final DateTime startDate;
  final DateTime endDate;

  final List<DailyStatisticsActivityDto> days;

  StatisticsActivity toDomain() {
    return StatisticsActivity(
      startDate: startDate,
      endDate: endDate,
      days: days
          .map((DailyStatisticsActivityDto item) => item.toDomain())
          .toList(growable: false),
    );
  }
}

final class DailyStatisticsActivityDto {
  const DailyStatisticsActivityDto({
    required this.day,
    required this.episodesWatched,
    required this.moviesWatched,
    required this.episodeWatchTimeMinutes,
    required this.movieWatchTimeMinutes,
    required this.watchTimeMinutes,
  });

  factory DailyStatisticsActivityDto.fromJson(Map<String, dynamic> json) {
    return DailyStatisticsActivityDto(
      day: _parseDate(_readString(json, 'day'), key: 'day'),
      episodesWatched: _readNonNegativeInt(json, 'episodes_watched'),
      moviesWatched: _readNonNegativeInt(json, 'movies_watched'),
      episodeWatchTimeMinutes: _readNonNegativeInt(
        json,
        'episode_watch_time_minutes',
      ),
      movieWatchTimeMinutes: _readNonNegativeInt(
        json,
        'movie_watch_time_minutes',
      ),
      watchTimeMinutes: _readNonNegativeInt(json, 'watch_time_minutes'),
    );
  }

  final DateTime day;

  final int episodesWatched;
  final int moviesWatched;

  final int episodeWatchTimeMinutes;
  final int movieWatchTimeMinutes;
  final int watchTimeMinutes;

  DailyStatisticsActivity toDomain() {
    return DailyStatisticsActivity(
      day: day,
      episodesWatched: episodesWatched,
      moviesWatched: moviesWatched,
      episodeWatchTimeMinutes: episodeWatchTimeMinutes,
      movieWatchTimeMinutes: movieWatchTimeMinutes,
      watchTimeMinutes: watchTimeMinutes,
    );
  }
}

String _readString(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! String || value.isEmpty) {
    throw FormatException('Expected "$key" to be a non-empty string.');
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

DateTime _parseDate(String value, {required String key}) {
  final DateTime? parsed = DateTime.tryParse(value);

  if (parsed == null) {
    throw FormatException('Expected "$key" to contain a valid date.');
  }

  return parsed;
}
