import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/statistics/data/models/weekly_statistics_dto.dart';
import 'package:sofawatch/features/statistics/domain/models/weekly_statistics.dart';

void main() {
  group('WeeklyStatisticsDto', () {
    test('maps weekly Statistics response to domain', () {
      final WeeklyStatistics result =
          WeeklyStatisticsDto.fromJson(<String, dynamic>{
            'week_start': '2026-08-17',
            'week_end': '2026-08-23',
            'episodes_watched': 8,
            'movies_watched': 2,
            'watch_time_minutes': 642,
          }).toDomain();

      expect(result.weekStart, DateTime(2026, 8, 17));

      expect(result.weekEnd, DateTime(2026, 8, 23));

      expect(result.episodesWatched, 8);
      expect(result.moviesWatched, 2);
      expect(result.watchTimeMinutes, 642);
    });

    test('supports an empty viewing week', () {
      final WeeklyStatistics result =
          WeeklyStatisticsDto.fromJson(<String, dynamic>{
            'week_start': '2026-08-17',
            'week_end': '2026-08-23',
            'episodes_watched': 0,
            'movies_watched': 0,
            'watch_time_minutes': 0,
          }).toDomain();

      expect(result.episodesWatched, 0);
      expect(result.moviesWatched, 0);
      expect(result.watchTimeMinutes, 0);
    });

    test('rejects negative statistics', () {
      expect(() {
        WeeklyStatisticsDto.fromJson(<String, dynamic>{
          'week_start': '2026-08-17',
          'week_end': '2026-08-23',
          'episodes_watched': -1,
          'movies_watched': 0,
          'watch_time_minutes': 0,
        });
      }, throwsFormatException);
    });

    test('rejects an invalid week date', () {
      expect(() {
        WeeklyStatisticsDto.fromJson(<String, dynamic>{
          'week_start': 'not-a-date',
          'week_end': '2026-08-23',
          'episodes_watched': 0,
          'movies_watched': 0,
          'watch_time_minutes': 0,
        });
      }, throwsFormatException);
    });
  });
}
