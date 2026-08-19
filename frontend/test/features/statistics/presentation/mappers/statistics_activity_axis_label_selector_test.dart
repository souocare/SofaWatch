import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity_period.dart';
import 'package:sofawatch/features/statistics/presentation/mappers/statistics_activity_axis_label_selector.dart';
import 'package:sofawatch/features/statistics/presentation/models/statistics_activity_bucket.dart';

void main() {
  group('StatisticsActivityAxisLabelSelector', () {
    test('shows every label for seven daily buckets', () {
      final List<StatisticsActivityBucket> buckets = _buckets(7);

      expect(
        StatisticsActivityAxisLabelSelector.select(
          buckets: buckets,
          period: StatisticsActivityPeriod.days7,
        ),
        <int>{0, 1, 2, 3, 4, 5, 6},
      );
    });

    test('limits fourteen-day labels while preserving edges', () {
      final Set<int> result = StatisticsActivityAxisLabelSelector.select(
        buckets: _buckets(14),
        period: StatisticsActivityPeriod.days14,
      );

      expect(result, hasLength(7));

      expect(result, contains(0));

      expect(result, contains(13));
    });

    test('limits All labels while preserving first and last', () {
      final Set<int> result = StatisticsActivityAxisLabelSelector.select(
        buckets: _buckets(40),
        period: StatisticsActivityPeriod.all,
      );

      expect(result.length, lessThanOrEqualTo(8));

      expect(result, contains(0));

      expect(result, contains(39));
    });

    test('returns the only index for one bucket', () {
      expect(
        StatisticsActivityAxisLabelSelector.select(
          buckets: _buckets(1),
          period: StatisticsActivityPeriod.all,
        ),
        <int>{0},
      );
    });

    test('returns no indexes without buckets', () {
      expect(
        StatisticsActivityAxisLabelSelector.select(
          buckets: const <StatisticsActivityBucket>[],
          period: StatisticsActivityPeriod.days7,
        ),
        isEmpty,
      );
    });
  });
}

List<StatisticsActivityBucket> _buckets(int count) {
  return List<StatisticsActivityBucket>.generate(count, (int index) {
    final DateTime day = DateTime(2026, 1, 1 + index);

    return StatisticsActivityBucket(
      startDate: day,
      endDate: day,
      granularity: StatisticsActivityBucketGranularity.day,
      episodesWatched: 0,
      moviesWatched: 0,
      episodeWatchTimeMinutes: 0,
      movieWatchTimeMinutes: 0,
    );
  }, growable: false);
}
