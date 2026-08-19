import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/statistics/presentation/formatters/statistics_activity_bucket_label_formatter.dart';
import 'package:sofawatch/features/statistics/presentation/models/statistics_activity_bucket.dart';

void main() {
  group('StatisticsActivityBucketLabelFormatter', () {
    test('formats daily axis labels', () {
      expect(
        StatisticsActivityBucketLabelFormatter.formatAxisLabel(
          _bucket(
            startDate: DateTime(2026, 8, 18),
            endDate: DateTime(2026, 8, 18),
            granularity: StatisticsActivityBucketGranularity.day,
          ),
        ),
        '18',
      );
    });

    test('formats weekly axis labels', () {
      expect(
        StatisticsActivityBucketLabelFormatter.formatAxisLabel(
          _bucket(
            startDate: DateTime(2026, 8, 17),
            endDate: DateTime(2026, 8, 23),
            granularity: StatisticsActivityBucketGranularity.week,
          ),
        ),
        '17 Aug',
      );
    });

    test('formats monthly axis labels', () {
      expect(
        StatisticsActivityBucketLabelFormatter.formatAxisLabel(
          _bucket(
            startDate: DateTime(2026, 8, 1),
            endDate: DateTime(2026, 8, 18),
            granularity: StatisticsActivityBucketGranularity.month,
          ),
        ),
        'Aug',
      );
    });

    test('formats yearly axis labels', () {
      expect(
        StatisticsActivityBucketLabelFormatter.formatAxisLabel(
          _bucket(
            startDate: DateTime(2024, 1, 1),
            endDate: DateTime(2024, 8, 31),
            granularity: StatisticsActivityBucketGranularity.year,
          ),
        ),
        '2024',
      );
    });

    test('shows the real range for a partial yearly bucket tooltip', () {
      expect(
        StatisticsActivityBucketLabelFormatter.formatTooltipDate(
          _bucket(
            startDate: DateTime(2024, 1, 10),
            endDate: DateTime(2024, 8, 31),
            granularity: StatisticsActivityBucketGranularity.year,
          ),
        ),
        '10 Jan – 31 Aug 2024',
      );
    });
  });
}

StatisticsActivityBucket _bucket({
  required DateTime startDate,
  required DateTime endDate,
  required StatisticsActivityBucketGranularity granularity,
}) {
  return StatisticsActivityBucket(
    startDate: startDate,
    endDate: endDate,
    granularity: granularity,
    episodesWatched: 0,
    moviesWatched: 0,
    episodeWatchTimeMinutes: 0,
    movieWatchTimeMinutes: 0,
  );
}
