import 'package:sofawatch/features/statistics/presentation/models/statistics_activity_bucket.dart';

abstract final class StatisticsActivityBucketLabelFormatter {
  static const List<String> _shortMonths = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String formatAxisLabel(StatisticsActivityBucket bucket) {
    return switch (bucket.granularity) {
      StatisticsActivityBucketGranularity.day => '${bucket.startDate.day}',

      StatisticsActivityBucketGranularity.week =>
        '${bucket.startDate.day} ${_month(bucket.startDate)}',

      StatisticsActivityBucketGranularity.month => _month(bucket.startDate),

      StatisticsActivityBucketGranularity.year => '${bucket.startDate.year}',
    };
  }

  static String formatTooltipDate(StatisticsActivityBucket bucket) {
    return switch (bucket.granularity) {
      StatisticsActivityBucketGranularity.day =>
        '${bucket.startDate.day} '
            '${_month(bucket.startDate)} '
            '${bucket.startDate.year}',

      StatisticsActivityBucketGranularity.week =>
        '${bucket.startDate.day} ${_month(bucket.startDate)}'
            ' – '
            '${bucket.endDate.day} ${_month(bucket.endDate)}',

      StatisticsActivityBucketGranularity.month =>
        '${_month(bucket.startDate)} ${bucket.startDate.year}',

      StatisticsActivityBucketGranularity.year =>
        bucket.startDate.year == bucket.endDate.year &&
                bucket.startDate.month == 1 &&
                bucket.startDate.day == 1 &&
                bucket.endDate.month == 12 &&
                bucket.endDate.day == 31
            ? '${bucket.startDate.year}'
            : '${bucket.startDate.day} ${_month(bucket.startDate)}'
                  ' – '
                  '${bucket.endDate.day} ${_month(bucket.endDate)} '
                  '${bucket.endDate.year}',
    };
  }

  static String _month(DateTime value) {
    return _shortMonths[value.month - 1];
  }
}
