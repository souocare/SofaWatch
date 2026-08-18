import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/statistics/data/models/statistics_summary_dto.dart';

void main() {
  group('StatisticsSummaryDto', () {
    test('maps a statistics summary response', () {
      final StatisticsSummaryDto dto = StatisticsSummaryDto.fromJson(
        const <String, dynamic>{
          'shows_watched': 12,
          'episodes': <String, dynamic>{
            'watch_count': 125,
            'unique_count': 100,
            'rewatch_count': 25,
            'watch_time_minutes': 6250,
            'rewatch_time_minutes': 1250,
          },
          'movies': <String, dynamic>{
            'watch_count': 34,
            'unique_count': 30,
            'rewatch_count': 4,
            'watch_time_minutes': 4200,
            'rewatch_time_minutes': 500,
          },
          'watch_time_minutes': 10450,
          'rewatch_time_minutes': 1750,
        },
      );

      final summary = dto.toDomain();

      expect(summary.showsWatched, 12);

      expect(summary.episodes.watchCount, 125);
      expect(summary.episodes.uniqueCount, 100);
      expect(summary.episodes.rewatchCount, 25);
      expect(summary.episodes.watchTimeMinutes, 6250);
      expect(summary.episodes.rewatchTimeMinutes, 1250);

      expect(summary.movies.watchCount, 34);
      expect(summary.movies.uniqueCount, 30);
      expect(summary.movies.rewatchCount, 4);
      expect(summary.movies.watchTimeMinutes, 4200);
      expect(summary.movies.rewatchTimeMinutes, 500);

      expect(summary.watchTimeMinutes, 10450);
      expect(summary.rewatchTimeMinutes, 1750);

      expect(summary.episodesWatched, 125);

      expect(summary.moviesWatched, 34);
    });

    test('rejects a missing Episodes object', () {
      expect(
        () => StatisticsSummaryDto.fromJson(const <String, dynamic>{
          'shows_watched': 12,
          'movies': <String, dynamic>{
            'watch_count': 34,
            'unique_count': 30,
            'rewatch_count': 4,
            'watch_time_minutes': 4200,
            'rewatch_time_minutes': 500,
          },
          'watch_time_minutes': 10450,
          'rewatch_time_minutes': 1750,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects negative nested values', () {
      expect(
        () => StatisticsSummaryDto.fromJson(const <String, dynamic>{
          'shows_watched': 12,
          'episodes': <String, dynamic>{
            'watch_count': 125,
            'unique_count': 100,
            'rewatch_count': -1,
            'watch_time_minutes': 6250,
            'rewatch_time_minutes': 1250,
          },
          'movies': <String, dynamic>{
            'watch_count': 34,
            'unique_count': 30,
            'rewatch_count': 4,
            'watch_time_minutes': 4200,
            'rewatch_time_minutes': 500,
          },
          'watch_time_minutes': 10450,
          'rewatch_time_minutes': 1750,
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
