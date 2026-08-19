import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/statistics/data/models/statistics_habits_dto.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_habits.dart';

void main() {
  group('StatisticsHabitsDto', () {
    test('maps a valid response to domain', () {
      final StatisticsHabits result =
          StatisticsHabitsDto.fromJson(const <String, dynamic>{
            'current_streak_days': 4,
            'longest_streak_days': 12,
            'biggest_marathon_watch_time_minutes': 270,
            'biggest_marathon_day': '2026-08-12',
            'longest_binge_episode_count': 7,
            'longest_binge_day': '2026-08-15',
            'average_active_day_watch_time_minutes': 103,
            'most_active_weekday': 'Monday',
            'most_active_weekday_watch_count': 8,
          }).toDomain();

      expect(
        result,
        StatisticsHabits(
          currentStreakDays: 4,
          longestStreakDays: 12,
          biggestMarathonWatchTimeMinutes: 270,
          biggestMarathonDay: DateTime(2026, 8, 12),
          longestBingeEpisodeCount: 7,
          longestBingeDay: DateTime(2026, 8, 15),
          averageActiveDayWatchTimeMinutes: 103,
          mostActiveWeekday: 'Monday',
          mostActiveWeekdayWatchCount: 8,
        ),
      );
    });

    test('accepts zero values and null days', () {
      final StatisticsHabits result =
          StatisticsHabitsDto.fromJson(const <String, dynamic>{
            'current_streak_days': 0,
            'longest_streak_days': 0,
            'biggest_marathon_watch_time_minutes': 0,
            'biggest_marathon_day': null,
            'longest_binge_episode_count': 0,
            'longest_binge_day': null,
            'average_active_day_watch_time_minutes': 0,
            'most_active_weekday': null,
            'most_active_weekday_watch_count': 0,
          }).toDomain();

      expect(
        result,
        const StatisticsHabits(
          currentStreakDays: 0,
          longestStreakDays: 0,
          biggestMarathonWatchTimeMinutes: 0,
          biggestMarathonDay: null,
          longestBingeEpisodeCount: 0,
          longestBingeDay: null,
          averageActiveDayWatchTimeMinutes: 0,
          mostActiveWeekday: null,
          mostActiveWeekdayWatchCount: 0,
        ),
      );
    });

    test('rejects a negative marathon watch time', () {
      expect(
        () => StatisticsHabitsDto.fromJson(const <String, dynamic>{
          'current_streak_days': 4,
          'longest_streak_days': 12,
          'biggest_marathon_watch_time_minutes': -1,
          'biggest_marathon_day': '2026-08-12',
          'longest_binge_episode_count': 7,
          'longest_binge_day': '2026-08-15',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects an invalid marathon day', () {
      expect(
        () => StatisticsHabitsDto.fromJson(const <String, dynamic>{
          'current_streak_days': 4,
          'longest_streak_days': 12,
          'biggest_marathon_watch_time_minutes': 270,
          'biggest_marathon_day': 'not-a-date',
          'longest_binge_episode_count': 7,
          'longest_binge_day': '2026-08-15',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a negative binge episode count', () {
      expect(
        () => StatisticsHabitsDto.fromJson(const <String, dynamic>{
          'current_streak_days': 4,
          'longest_streak_days': 12,
          'biggest_marathon_watch_time_minutes': 270,
          'biggest_marathon_day': '2026-08-12',
          'longest_binge_episode_count': -1,
          'longest_binge_day': '2026-08-15',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a non-integer binge episode count', () {
      expect(
        () => StatisticsHabitsDto.fromJson(const <String, dynamic>{
          'current_streak_days': 4,
          'longest_streak_days': 12,
          'biggest_marathon_watch_time_minutes': 270,
          'biggest_marathon_day': '2026-08-12',
          'longest_binge_episode_count': '7',
          'longest_binge_day': '2026-08-15',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects an invalid binge day', () {
      expect(
        () => StatisticsHabitsDto.fromJson(const <String, dynamic>{
          'current_streak_days': 4,
          'longest_streak_days': 12,
          'biggest_marathon_watch_time_minutes': 270,
          'biggest_marathon_day': '2026-08-12',
          'longest_binge_episode_count': 7,
          'longest_binge_day': 'not-a-date',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a non-string binge day', () {
      expect(
        () => StatisticsHabitsDto.fromJson(const <String, dynamic>{
          'current_streak_days': 4,
          'longest_streak_days': 12,
          'biggest_marathon_watch_time_minutes': 270,
          'biggest_marathon_day': '2026-08-12',
          'longest_binge_episode_count': 7,
          'longest_binge_day': 20260815,
        }),
        throwsA(isA<FormatException>()),
      );
    });
    test('rejects a negative average active-day watch time', () {
      expect(
        () => StatisticsHabitsDto.fromJson(const <String, dynamic>{
          'current_streak_days': 4,
          'longest_streak_days': 12,
          'biggest_marathon_watch_time_minutes': 270,
          'biggest_marathon_day': '2026-08-12',
          'longest_binge_episode_count': 7,
          'longest_binge_day': '2026-08-15',
          'average_active_day_watch_time_minutes': -1,
        }),
        throwsA(isA<FormatException>()),
      );
    });
    test('rejects a non-integer average active-day watch time', () {
      expect(
        () => StatisticsHabitsDto.fromJson(const <String, dynamic>{
          'current_streak_days': 4,
          'longest_streak_days': 12,
          'biggest_marathon_watch_time_minutes': 270,
          'biggest_marathon_day': '2026-08-12',
          'longest_binge_episode_count': 7,
          'longest_binge_day': '2026-08-15',
          'average_active_day_watch_time_minutes': '103',
        }),
        throwsA(isA<FormatException>()),
      );
    });
    test('rejects an empty most active weekday', () {
      expect(
        () => StatisticsHabitsDto.fromJson(const <String, dynamic>{
          'current_streak_days': 4,
          'longest_streak_days': 12,
          'biggest_marathon_watch_time_minutes': 270,
          'biggest_marathon_day': '2026-08-12',
          'longest_binge_episode_count': 7,
          'longest_binge_day': '2026-08-15',
          'average_active_day_watch_time_minutes': 103,
          'most_active_weekday': '',
          'most_active_weekday_watch_count': 8,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a negative most active weekday watch count', () {
      expect(
        () => StatisticsHabitsDto.fromJson(const <String, dynamic>{
          'current_streak_days': 4,
          'longest_streak_days': 12,
          'biggest_marathon_watch_time_minutes': 270,
          'biggest_marathon_day': '2026-08-12',
          'longest_binge_episode_count': 7,
          'longest_binge_day': '2026-08-15',
          'average_active_day_watch_time_minutes': 103,
          'most_active_weekday': 'Monday',
          'most_active_weekday_watch_count': -1,
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
