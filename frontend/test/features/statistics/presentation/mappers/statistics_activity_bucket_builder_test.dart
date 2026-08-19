import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity_period.dart';
import 'package:sofawatch/features/statistics/presentation/mappers/statistics_activity_bucket_builder.dart';
import 'package:sofawatch/features/statistics/presentation/models/statistics_activity_bucket.dart';

void main() {
  group('StatisticsActivityBucketBuilder', () {
    test('keeps 30D Activity in daily buckets', () {
      final StatisticsActivity activity = StatisticsActivity(
        startDate: DateTime(2026, 8, 17),
        endDate: DateTime(2026, 8, 18),
        days: <DailyStatisticsActivity>[
          _day(2026, 8, 17, episodes: 2, episodeMinutes: 100),
          _day(2026, 8, 18, movies: 1, movieMinutes: 120),
        ],
      );

      final List<StatisticsActivityBucket> result =
          StatisticsActivityBucketBuilder.build(
            activity: activity,
            period: StatisticsActivityPeriod.days30,
          );

      expect(result, hasLength(2));

      expect(result[0].episodesWatched, 2);
      expect(result[0].watchTimeMinutes, 100);

      expect(result[1].moviesWatched, 1);
      expect(result[1].watchTimeMinutes, 120);
    });

    test('groups 90D Activity into calendar weeks', () {
      final StatisticsActivity activity = StatisticsActivity(
        startDate: DateTime(2026, 8, 17),
        endDate: DateTime(2026, 8, 24),
        days: <DailyStatisticsActivity>[
          _day(2026, 8, 17, episodes: 1, episodeMinutes: 50),
          _day(2026, 8, 18, movies: 1, movieMinutes: 120),
          _day(2026, 8, 24, episodes: 2, episodeMinutes: 100),
        ],
      );

      final List<StatisticsActivityBucket> result =
          StatisticsActivityBucketBuilder.build(
            activity: activity,
            period: StatisticsActivityPeriod.days90,
          );

      expect(result, hasLength(2));

      expect(result[0].startDate, DateTime(2026, 8, 17));

      expect(result[0].endDate, DateTime(2026, 8, 18));

      expect(result[0].watchTimeMinutes, 170);

      expect(result[1].startDate, DateTime(2026, 8, 24));

      expect(result[1].watchTimeMinutes, 100);
    });

    test('groups 1Y Activity into calendar months', () {
      final StatisticsActivity activity = StatisticsActivity(
        startDate: DateTime(2026, 7, 31),
        endDate: DateTime(2026, 8, 1),
        days: <DailyStatisticsActivity>[
          _day(2026, 7, 31, episodeMinutes: 50),
          _day(2026, 8, 1, movieMinutes: 120),
        ],
      );

      final List<StatisticsActivityBucket> result =
          StatisticsActivityBucketBuilder.build(
            activity: activity,
            period: StatisticsActivityPeriod.year1,
          );

      expect(result, hasLength(2));

      expect(result[0].startDate.month, 7);
      expect(result[0].watchTimeMinutes, 50);

      expect(result[1].startDate.month, 8);
      expect(result[1].watchTimeMinutes, 120);
    });

    test('uses monthly buckets for All when history fits within 24 months', () {
      final StatisticsActivity activity = StatisticsActivity(
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2026, 8, 18),
        days: <DailyStatisticsActivity>[
          _day(2025, 1, 1, episodeMinutes: 50),
          _day(2026, 8, 18, movieMinutes: 120),
        ],
      );

      final List<StatisticsActivityBucket> result =
          StatisticsActivityBucketBuilder.build(
            activity: activity,
            period: StatisticsActivityPeriod.all,
          );

      expect(result, hasLength(2));

      expect(
        result.every(
          (StatisticsActivityBucket bucket) =>
              bucket.granularity == StatisticsActivityBucketGranularity.month,
        ),
        isTrue,
      );
    });

    test('uses yearly older buckets and monthly recent buckets for All', () {
      final StatisticsActivity activity = StatisticsActivity(
        startDate: DateTime(2022, 2, 10),
        endDate: DateTime(2026, 8, 18),
        days: <DailyStatisticsActivity>[
          _day(2022, 2, 10, episodeMinutes: 40),
          _day(2023, 6, 5, movieMinutes: 100),
          _day(2024, 8, 20, episodeMinutes: 50),
          _day(2024, 9, 1, episodeMinutes: 60),
          _day(2025, 1, 15, movieMinutes: 120),
          _day(2026, 8, 18, episodeMinutes: 45),
        ],
      );

      final List<StatisticsActivityBucket> result =
          StatisticsActivityBucketBuilder.build(
            activity: activity,
            period: StatisticsActivityPeriod.all,
          );

      expect(
        result.map((StatisticsActivityBucket bucket) => bucket.granularity),
        <StatisticsActivityBucketGranularity>[
          StatisticsActivityBucketGranularity.year,
          StatisticsActivityBucketGranularity.year,
          StatisticsActivityBucketGranularity.year,
          StatisticsActivityBucketGranularity.month,
          StatisticsActivityBucketGranularity.month,
          StatisticsActivityBucketGranularity.month,
        ],
      );

      expect(result[0].startDate, DateTime(2022, 2, 10));

      expect(result[0].endDate, DateTime(2022, 2, 10));

      expect(result[0].watchTimeMinutes, 40);

      expect(result[2].startDate, DateTime(2024, 8, 20));

      expect(result[2].granularity, StatisticsActivityBucketGranularity.year);

      expect(result[3].startDate, DateTime(2024, 9, 1));

      expect(result[3].granularity, StatisticsActivityBucketGranularity.month);
    });

    test('returns no buckets for empty Activity', () {
      final StatisticsActivity activity = StatisticsActivity(
        startDate: DateTime(2026, 8, 18),
        endDate: DateTime(2026, 8, 18),
        days: const <DailyStatisticsActivity>[],
      );

      expect(
        StatisticsActivityBucketBuilder.build(
          activity: activity,
          period: StatisticsActivityPeriod.days7,
        ),
        isEmpty,
      );
    });
    test('All hybrid buckets never overlap at monthly cutoff', () {
      final StatisticsActivity activity = StatisticsActivity(
        startDate: DateTime(2024, 8, 31),
        endDate: DateTime(2026, 8, 18),
        days: <DailyStatisticsActivity>[
          _day(2024, 8, 31, episodeMinutes: 50),
          _day(2024, 9, 1, episodeMinutes: 60),
        ],
      );

      final List<StatisticsActivityBucket> result =
          StatisticsActivityBucketBuilder.build(
            activity: activity,
            period: StatisticsActivityPeriod.all,
          );

      expect(result, hasLength(2));

      expect(result[0].granularity, StatisticsActivityBucketGranularity.year);

      expect(result[0].endDate, DateTime(2024, 8, 31));

      expect(result[1].granularity, StatisticsActivityBucketGranularity.month);

      expect(result[1].startDate, DateTime(2024, 9, 1));
    });
  });
}

DailyStatisticsActivity _day(
  int year,
  int month,
  int day, {
  int episodes = 0,
  int movies = 0,
  int episodeMinutes = 0,
  int movieMinutes = 0,
}) {
  return DailyStatisticsActivity(
    day: DateTime(year, month, day),
    episodesWatched: episodes,
    moviesWatched: movies,
    episodeWatchTimeMinutes: episodeMinutes,
    movieWatchTimeMinutes: movieMinutes,
    watchTimeMinutes: episodeMinutes + movieMinutes,
  );
}
