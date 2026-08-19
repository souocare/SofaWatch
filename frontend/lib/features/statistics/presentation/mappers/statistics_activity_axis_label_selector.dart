import 'package:sofawatch/features/statistics/domain/models/statistics_activity_period.dart';
import 'package:sofawatch/features/statistics/presentation/models/statistics_activity_bucket.dart';

abstract final class StatisticsActivityAxisLabelSelector {
  static Set<int> select({
    required List<StatisticsActivityBucket> buckets,
    required StatisticsActivityPeriod period,
  }) {
    if (buckets.isEmpty) {
      return const <int>{};
    }

    if (buckets.length == 1) {
      return const <int>{0};
    }

    final int targetLabels = switch (period) {
      StatisticsActivityPeriod.days7 => 7,
      StatisticsActivityPeriod.days14 => 7,
      StatisticsActivityPeriod.days30 => 6,
      StatisticsActivityPeriod.days90 => 6,
      StatisticsActivityPeriod.year1 => 6,
      StatisticsActivityPeriod.all => 8,
    };

    if (buckets.length <= targetLabels) {
      return Set<int>.from(
        List<int>.generate(buckets.length, (int index) => index),
      );
    }

    final Set<int> selected = <int>{0, buckets.length - 1};

    final double interval = (buckets.length - 1) / (targetLabels - 1);

    for (int index = 1; index < targetLabels - 1; index++) {
      selected.add((interval * index).round());
    }

    return selected;
  }
}
