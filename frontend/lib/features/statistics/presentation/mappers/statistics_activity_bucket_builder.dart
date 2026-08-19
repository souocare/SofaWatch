import 'package:sofawatch/features/statistics/domain/models/statistics_activity.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity_period.dart';
import 'package:sofawatch/features/statistics/presentation/models/statistics_activity_bucket.dart';

abstract final class StatisticsActivityBucketBuilder {
  static const int _allRecentMonths = 24;

  static StatisticsActivityBucketGranularity granularityFor({
    required StatisticsActivity activity,
    required StatisticsActivityPeriod period,
  }) {
    return switch (period) {
      StatisticsActivityPeriod.days7 ||
      StatisticsActivityPeriod.days14 ||
      StatisticsActivityPeriod.days30 =>
        StatisticsActivityBucketGranularity.day,

      StatisticsActivityPeriod.days90 =>
        StatisticsActivityBucketGranularity.week,

      StatisticsActivityPeriod.year1 =>
        StatisticsActivityBucketGranularity.month,

      /*
       * All can contain mixed granularity.
       *
       * This value represents the granularity used for the recent portion
       * of the range. Older data is compressed into yearly buckets.
       */
      StatisticsActivityPeriod.all => StatisticsActivityBucketGranularity.month,
    };
  }

  static List<StatisticsActivityBucket> build({
    required StatisticsActivity activity,
    required StatisticsActivityPeriod period,
  }) {
    if (activity.days.isEmpty) {
      return const <StatisticsActivityBucket>[];
    }

    return switch (period) {
      StatisticsActivityPeriod.days7 ||
      StatisticsActivityPeriod.days14 ||
      StatisticsActivityPeriod.days30 => _buildDaily(activity.days),

      StatisticsActivityPeriod.days90 => _buildWeekly(activity.days),

      StatisticsActivityPeriod.year1 => _buildMonthly(activity.days),

      StatisticsActivityPeriod.all => _buildAll(activity),
    };
  }

  static List<StatisticsActivityBucket> _buildAll(StatisticsActivity activity) {
    final DateTime recentCutoff = _subtractMonths(
      _dateOnly(activity.endDate),
      _allRecentMonths - 1,
    );

    final List<DailyStatisticsActivity> olderDays = <DailyStatisticsActivity>[];

    final List<DailyStatisticsActivity> recentDays =
        <DailyStatisticsActivity>[];

    for (final DailyStatisticsActivity activityDay in activity.days) {
      final DateTime day = _dateOnly(activityDay.day);

      if (day.isBefore(recentCutoff)) {
        olderDays.add(activityDay);
      } else {
        recentDays.add(activityDay);
      }
    }

    return <StatisticsActivityBucket>[
      ..._buildYearly(olderDays),
      ..._buildMonthly(recentDays),
    ];
  }

  static List<StatisticsActivityBucket> _buildDaily(
    List<DailyStatisticsActivity> days,
  ) {
    return days
        .map(
          (DailyStatisticsActivity day) => StatisticsActivityBucket(
            startDate: _dateOnly(day.day),
            endDate: _dateOnly(day.day),
            granularity: StatisticsActivityBucketGranularity.day,
            episodesWatched: day.episodesWatched,
            moviesWatched: day.moviesWatched,
            episodeWatchTimeMinutes: day.episodeWatchTimeMinutes,
            movieWatchTimeMinutes: day.movieWatchTimeMinutes,
          ),
        )
        .toList(growable: false);
  }

  static List<StatisticsActivityBucket> _buildWeekly(
    List<DailyStatisticsActivity> days,
  ) {
    return _group(
      days: days,
      granularity: StatisticsActivityBucketGranularity.week,
      keyFor: _weekStart,
    );
  }

  static List<StatisticsActivityBucket> _buildMonthly(
    List<DailyStatisticsActivity> days,
  ) {
    return _group(
      days: days,
      granularity: StatisticsActivityBucketGranularity.month,
      keyFor: (DateTime day) {
        return DateTime(day.year, day.month);
      },
    );
  }

  static List<StatisticsActivityBucket> _buildYearly(
    List<DailyStatisticsActivity> days,
  ) {
    return _group(
      days: days,
      granularity: StatisticsActivityBucketGranularity.year,
      keyFor: (DateTime day) {
        return DateTime(day.year);
      },
    );
  }

  static List<StatisticsActivityBucket> _group({
    required List<DailyStatisticsActivity> days,
    required StatisticsActivityBucketGranularity granularity,
    required DateTime Function(DateTime day) keyFor,
  }) {
    final Map<DateTime, _MutableBucket> buckets = <DateTime, _MutableBucket>{};

    for (final DailyStatisticsActivity activityDay in days) {
      final DateTime day = _dateOnly(activityDay.day);

      final DateTime key = keyFor(day);

      final _MutableBucket bucket = buckets.putIfAbsent(
        key,
        () => _MutableBucket(
          startDate: day,
          endDate: day,
          granularity: granularity,
        ),
      );

      bucket.add(day: day, activity: activityDay);
    }

    final List<DateTime> keys = buckets.keys.toList()..sort();

    return keys
        .map((DateTime key) => buckets[key]!.toImmutable())
        .toList(growable: false);
  }

  static DateTime _weekStart(DateTime value) {
    final DateTime day = _dateOnly(value);

    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  static DateTime _subtractMonths(DateTime value, int months) {
    final int totalMonths = (value.year * 12) + (value.month - 1) - months;

    return DateTime(totalMonths ~/ 12, (totalMonths % 12) + 1, 1);
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}

final class _MutableBucket {
  _MutableBucket({
    required this.startDate,
    required this.endDate,
    required this.granularity,
  });

  DateTime startDate;
  DateTime endDate;

  final StatisticsActivityBucketGranularity granularity;

  int episodesWatched = 0;
  int moviesWatched = 0;

  int episodeWatchTimeMinutes = 0;
  int movieWatchTimeMinutes = 0;

  void add({required DateTime day, required DailyStatisticsActivity activity}) {
    if (day.isBefore(startDate)) {
      startDate = day;
    }

    if (day.isAfter(endDate)) {
      endDate = day;
    }

    episodesWatched += activity.episodesWatched;
    moviesWatched += activity.moviesWatched;

    episodeWatchTimeMinutes += activity.episodeWatchTimeMinutes;

    movieWatchTimeMinutes += activity.movieWatchTimeMinutes;
  }

  StatisticsActivityBucket toImmutable() {
    return StatisticsActivityBucket(
      startDate: startDate,
      endDate: endDate,
      granularity: granularity,
      episodesWatched: episodesWatched,
      moviesWatched: moviesWatched,
      episodeWatchTimeMinutes: episodeWatchTimeMinutes,
      movieWatchTimeMinutes: movieWatchTimeMinutes,
    );
  }
}
