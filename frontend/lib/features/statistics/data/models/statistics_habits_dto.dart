import 'package:sofawatch/features/statistics/domain/models/statistics_habits.dart';

final class StatisticsHabitsDto {
  const StatisticsHabitsDto({
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.biggestMarathonWatchTimeMinutes,
    required this.biggestMarathonDay,
    required this.longestBingeEpisodeCount,
    required this.longestBingeDay,
    required this.averageActiveDayWatchTimeMinutes,
    required this.mostActiveWeekday,
    required this.mostActiveWeekdayWatchCount,
  });

  factory StatisticsHabitsDto.fromJson(Map<String, dynamic> json) {
    return StatisticsHabitsDto(
      currentStreakDays: _readNonNegativeInt(json, 'current_streak_days'),
      longestStreakDays: _readNonNegativeInt(json, 'longest_streak_days'),
      biggestMarathonWatchTimeMinutes: _readNonNegativeInt(
        json,
        'biggest_marathon_watch_time_minutes',
      ),
      biggestMarathonDay: _readNullableDate(json, 'biggest_marathon_day'),
      longestBingeEpisodeCount: _readNonNegativeInt(
        json,
        'longest_binge_episode_count',
      ),
      longestBingeDay: _readNullableDate(json, 'longest_binge_day'),
      averageActiveDayWatchTimeMinutes: _readNonNegativeInt(
        json,
        'average_active_day_watch_time_minutes',
      ),
      mostActiveWeekday: _readNullableString(json, 'most_active_weekday'),
      mostActiveWeekdayWatchCount: _readNonNegativeInt(
        json,
        'most_active_weekday_watch_count',
      ),
    );
  }

  final int currentStreakDays;
  final int longestStreakDays;

  final int biggestMarathonWatchTimeMinutes;
  final DateTime? biggestMarathonDay;

  final int longestBingeEpisodeCount;
  final DateTime? longestBingeDay;

  final int averageActiveDayWatchTimeMinutes;
  final String? mostActiveWeekday;
  final int mostActiveWeekdayWatchCount;

  StatisticsHabits toDomain() {
    return StatisticsHabits(
      currentStreakDays: currentStreakDays,
      longestStreakDays: longestStreakDays,
      biggestMarathonWatchTimeMinutes: biggestMarathonWatchTimeMinutes,
      biggestMarathonDay: biggestMarathonDay,
      longestBingeEpisodeCount: longestBingeEpisodeCount,
      longestBingeDay: longestBingeDay,
      averageActiveDayWatchTimeMinutes: averageActiveDayWatchTimeMinutes,
      mostActiveWeekday: mostActiveWeekday,
      mostActiveWeekdayWatchCount: mostActiveWeekdayWatchCount,
    );
  }
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

DateTime? _readNullableDate(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value == null) {
    return null;
  }

  if (value is! String || value.isEmpty) {
    throw FormatException('Expected "$key" to be null or a non-empty string.');
  }

  final DateTime? parsed = DateTime.tryParse(value);

  if (parsed == null) {
    throw FormatException('Expected "$key" to contain a valid date.');
  }

  return parsed;
}

String? _readNullableString(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value == null) {
    return null;
  }

  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Expected "$key" to be null or a non-empty string.');
  }

  return value;
}
