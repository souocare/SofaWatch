import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity_period.dart';
import 'package:sofawatch/features/statistics/presentation/formatters/statistics_activity_bucket_label_formatter.dart';
import 'package:sofawatch/features/statistics/presentation/formatters/statistics_watch_time_formatter.dart';
import 'package:sofawatch/features/statistics/presentation/mappers/statistics_activity_axis_label_selector.dart';
import 'package:sofawatch/features/statistics/presentation/mappers/statistics_activity_bucket_builder.dart';
import 'package:sofawatch/features/statistics/presentation/models/statistics_activity_bucket.dart';

final class ActivityWatchTimeChart extends StatelessWidget {
  const ActivityWatchTimeChart({
    required this.activity,
    required this.period,
    super.key,
  });

  static const double _chartHeight = 180;
  static const double _axisLabelHeight = 32;

  static const double _minimumBarWidth = 8;
  static const double _maximumBarWidth = 28;
  static const double _barSpacing = 6;

  final StatisticsActivity activity;
  final StatisticsActivityPeriod period;

  @override
  Widget build(BuildContext context) {
    final List<StatisticsActivityBucket> buckets =
        StatisticsActivityBucketBuilder.build(
          activity: activity,
          period: period,
        );

    final int totalWatchTimeMinutes = buckets.fold<int>(0, (
      int total,
      StatisticsActivityBucket bucket,
    ) {
      return total + bucket.watchTimeMinutes;
    });

    return Container(
      key: const ValueKey<String>('detailed-statistics-watch-time-chart'),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Watch time',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: AppSpacing.xs),

          Text(
            formatStatisticsWatchTime(totalWatchTimeMinutes),
            key: const ValueKey<String>(
              'detailed-statistics-watch-time-chart-total',
            ),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: AppSpacing.lg),

          if (buckets.isEmpty || totalWatchTimeMinutes == 0)
            const _EmptyWatchTimeChart()
          else
            _WatchTimeBars(buckets: buckets, period: period),

          const SizedBox(height: AppSpacing.lg),

          const _WatchTimeLegend(),
        ],
      ),
    );
  }
}

final class _WatchTimeBars extends StatelessWidget {
  const _WatchTimeBars({required this.buckets, required this.period});

  final List<StatisticsActivityBucket> buckets;
  final StatisticsActivityPeriod period;

  @override
  Widget build(BuildContext context) {
    final int maximumMinutes = buckets.fold<int>(0, (
      int maximum,
      StatisticsActivityBucket bucket,
    ) {
      return math.max(maximum, bucket.watchTimeMinutes);
    });

    final Set<int> labelIndexes = StatisticsActivityAxisLabelSelector.select(
      buckets: buckets,
      period: period,
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double availableWidth = constraints.maxWidth;

        final double calculatedBarWidth =
            (availableWidth -
                ((buckets.length - 1) * ActivityWatchTimeChart._barSpacing)) /
            buckets.length;

        final double barWidth = calculatedBarWidth.clamp(
          ActivityWatchTimeChart._minimumBarWidth,
          ActivityWatchTimeChart._maximumBarWidth,
        );

        final double requiredWidth =
            (barWidth * buckets.length) +
            (ActivityWatchTimeChart._barSpacing *
                math.max(0, buckets.length - 1));

        final Widget chart = SizedBox(
          width: math.max(availableWidth, requiredWidth),
          height:
              ActivityWatchTimeChart._chartHeight +
              ActivityWatchTimeChart._axisLabelHeight,
          child: Row(
            key: const ValueKey<String>('detailed-statistics-watch-time-bars'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int index = 0; index < buckets.length; index++) ...<Widget>[
                SizedBox(
                  width: barWidth,
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        height: ActivityWatchTimeChart._chartHeight,
                        child: _WatchTimeBar(
                          bucket: buckets[index],
                          maximumMinutes: maximumMinutes,
                        ),
                      ),

                      SizedBox(
                        height: ActivityWatchTimeChart._axisLabelHeight,
                        child: labelIndexes.contains(index)
                            ? _ActivityAxisLabel(bucket: buckets[index])
                            : null,
                      ),
                    ],
                  ),
                ),

                if (index < buckets.length - 1)
                  const SizedBox(width: ActivityWatchTimeChart._barSpacing),
              ],
            ],
          ),
        );

        if (requiredWidth <= availableWidth) {
          return chart;
        }

        return SingleChildScrollView(
          key: const ValueKey<String>('detailed-statistics-watch-time-scroll'),
          scrollDirection: Axis.horizontal,
          child: chart,
        );
      },
    );
  }
}

final class _WatchTimeBar extends StatelessWidget {
  const _WatchTimeBar({required this.bucket, required this.maximumMinutes});

  final StatisticsActivityBucket bucket;
  final int maximumMinutes;

  @override
  Widget build(BuildContext context) {
    final double heightFraction = maximumMinutes > 0
        ? bucket.watchTimeMinutes / maximumMinutes
        : 0;

    final double totalHeight =
        ActivityWatchTimeChart._chartHeight * heightFraction;

    final double episodeFraction = bucket.watchTimeMinutes > 0
        ? bucket.episodeWatchTimeMinutes / bucket.watchTimeMinutes
        : 0;

    final double movieFraction = bucket.watchTimeMinutes > 0
        ? bucket.movieWatchTimeMinutes / bucket.watchTimeMinutes
        : 0;

    final String tooltip = _tooltipFor(bucket);

    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: tooltip,
        child: SizedBox(
          height: ActivityWatchTimeChart._chartHeight,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              borderRadius: AppRadius.borderLarge,
              child: SizedBox(
                key: ValueKey<String>(
                  'detailed-statistics-watch-time-bar-'
                  '${bucket.startDate.toIso8601String()}',
                ),
                height: math.max(
                  totalHeight,
                  bucket.watchTimeMinutes > 0 ? 4 : 0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    if (movieFraction > 0)
                      Expanded(
                        flex: _fractionFlex(movieFraction),
                        child: Container(color: AppColors.textSecondary),
                      ),

                    if (episodeFraction > 0)
                      Expanded(
                        flex: _fractionFlex(episodeFraction),
                        child: Container(color: AppColors.textPrimary),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _ActivityAxisLabel extends StatelessWidget {
  const _ActivityAxisLabel({required this.bucket});

  final StatisticsActivityBucket bucket;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        StatisticsActivityBucketLabelFormatter.formatAxisLabel(bucket),
        key: ValueKey<String>(
          'detailed-statistics-watch-time-label-'
          '${bucket.startDate.toIso8601String()}',
        ),
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

final class _EmptyWatchTimeChart extends StatelessWidget {
  const _EmptyWatchTimeChart();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('detailed-statistics-watch-time-empty'),
      height:
          ActivityWatchTimeChart._chartHeight +
          ActivityWatchTimeChart._axisLabelHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: AppRadius.borderLarge,
      ),
      child: Text(
        'No viewing activity in this period.',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

final class _WatchTimeLegend extends StatelessWidget {
  const _WatchTimeLegend();

  @override
  Widget build(BuildContext context) {
    return const Row(
      key: ValueKey<String>('detailed-statistics-watch-time-legend'),
      children: <Widget>[
        _LegendItem(label: 'Shows', color: AppColors.textPrimary),
        SizedBox(width: AppSpacing.lg),
        _LegendItem(label: 'Movies', color: AppColors.textSecondary),
      ],
    );
  }
}

final class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        const SizedBox(width: AppSpacing.xs),

        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

int _fractionFlex(double fraction) {
  return (fraction * 10000).round().clamp(1, 10000);
}

String _tooltipFor(StatisticsActivityBucket bucket) {
  final String dateLabel =
      StatisticsActivityBucketLabelFormatter.formatTooltipDate(bucket);

  return '$dateLabel\n'
      '${formatStatisticsWatchTime(bucket.watchTimeMinutes)} total · '
      '${formatStatisticsWatchTime(bucket.episodeWatchTimeMinutes)} Shows · '
      '${formatStatisticsWatchTime(bucket.movieWatchTimeMinutes)} Movies';
}
