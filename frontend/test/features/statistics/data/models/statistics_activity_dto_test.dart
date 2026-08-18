import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/statistics/data/models/statistics_activity_dto.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity.dart';

void main() {
  group('StatisticsActivityDto', () {
    test('maps a valid activity response to domain', () {
      final StatisticsActivity result = StatisticsActivityDto.fromJson(
        <String, dynamic>{
          'start_date': '2026-08-12',
          'end_date': '2026-08-18',
          'days': <Map<String, dynamic>>[
            <String, dynamic>{
              'day': '2026-08-12',
              'episodes_watched': 3,
              'movies_watched': 1,
              'episode_watch_time_minutes': 150,
              'movie_watch_time_minutes': 120,
              'watch_time_minutes': 270,
            },
            <String, dynamic>{
              'day': '2026-08-13',
              'episodes_watched': 0,
              'movies_watched': 0,
              'episode_watch_time_minutes': 0,
              'movie_watch_time_minutes': 0,
              'watch_time_minutes': 0,
            },
          ],
        },
      ).toDomain();

      expect(result.startDate, DateTime(2026, 8, 12));

      expect(result.endDate, DateTime(2026, 8, 18));

      expect(result.days, hasLength(2));

      final DailyStatisticsActivity firstDay = result.days.first;

      expect(firstDay.day, DateTime(2026, 8, 12));

      expect(firstDay.episodesWatched, 3);

      expect(firstDay.moviesWatched, 1);

      expect(firstDay.episodeWatchTimeMinutes, 150);

      expect(firstDay.movieWatchTimeMinutes, 120);

      expect(firstDay.watchTimeMinutes, 270);
    });

    test('rejects a negative activity value', () {
      expect(
        () => StatisticsActivityDto.fromJson(<String, dynamic>{
          'start_date': '2026-08-12',
          'end_date': '2026-08-18',
          'days': <Map<String, dynamic>>[
            <String, dynamic>{
              'day': '2026-08-12',
              'episodes_watched': -1,
              'movies_watched': 0,
              'episode_watch_time_minutes': 0,
              'movie_watch_time_minutes': 0,
              'watch_time_minutes': 0,
            },
          ],
        }),
        throwsFormatException,
      );
    });

    test('rejects an invalid activity date', () {
      expect(
        () => StatisticsActivityDto.fromJson(<String, dynamic>{
          'start_date': 'not-a-date',
          'end_date': '2026-08-18',
          'days': <Map<String, dynamic>>[],
        }),
        throwsFormatException,
      );
    });

    test('rejects a non-list days value', () {
      expect(
        () => StatisticsActivityDto.fromJson(<String, dynamic>{
          'start_date': '2026-08-12',
          'end_date': '2026-08-18',
          'days': 'invalid',
        }),
        throwsFormatException,
      );
    });
  });
}
