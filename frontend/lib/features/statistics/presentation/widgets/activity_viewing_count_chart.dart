import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity_period.dart';
import 'package:sofawatch/features/statistics/presentation/formatters/statistics_activity_bucket_label_formatter.dart';
import 'package:sofawatch/features/statistics/presentation/mappers/statistics_activity_axis_label_selector.dart';
import 'package:sofawatch/features/statistics/presentation/mappers/statistics_activity_bucket_builder.dart';
import 'package:sofawatch/features/statistics/presentation/models/statistics_activity_bucket.dart';

final class ActivityViewingCountChart extends StatelessWidget {
  const ActivityViewingCountChart({
    required this.activity,
    required this.period,
    super.key,
  });

  static const double _chartHeight = 180;
  static const double _axisLabelHeight = 32;

  static const double _minimumGroupWidth = 18;
  static const double _maximumGroupWidth = 42;
  static const double _groupSpacing = 8;
  static const double _barGap = 3;

  final StatisticsActivity activity;
  final StatisticsActivityPeriod period;

  @override
  Widget build(BuildContext context) {
    final List<StatisticsActivityBucket> buckets =
        StatisticsActivityBucketBuilder.build(
          activity: activity,
          period: period,
        );

    final int totalEpisodes = buckets.fold<int>(0, (
      int total,
      StatisticsActivityBucket bucket,
    ) {
      return total + bucket.episodesWatched;
    });

    final int totalMovies = buckets.fold<int>(0, (
      int total,
      StatisticsActivityBucket bucket,
    ) {
      return total + bucket.moviesWatched;
    });

    return Container(
      key: const ValueKey<String>('detailed-statistics-viewing-count-chart'),
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
            'Episodes & Movies watched',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: AppSpacing.xs),

          Text(
            '$totalEpisodes episodes · $totalMovies movies',
            key: const ValueKey<String>(
              'detailed-statistics-viewing-count-total',
            ),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          if (buckets.isEmpty || (totalEpisodes == 0 && totalMovies == 0))
            const _EmptyViewingCountChart()
          else
            _ViewingCountBars(buckets: buckets, period: period),

          const SizedBox(height: AppSpacing.lg),

          const _ViewingCountLegend(),
        ],
      ),
    );
  }
}

final class _ViewingCountBars extends StatelessWidget {
  const _ViewingCountBars({required this.buckets, required this.period});

  final List<StatisticsActivityBucket> buckets;
  final StatisticsActivityPeriod period;

  @override
  Widget build(BuildContext context) {
    final int maximumCount = buckets.fold<int>(0, (
      int maximum,
      StatisticsActivityBucket bucket,
    ) {
      return math.max(
        maximum,
        math.max(bucket.episodesWatched, bucket.moviesWatched),
      );
    });

    final Set<int> labelIndexes = StatisticsActivityAxisLabelSelector.select(
      buckets: buckets,
      period: period,
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double availableWidth = constraints.maxWidth;

        final double calculatedGroupWidth =
            (availableWidth -
                ((buckets.length - 1) *
                    ActivityViewingCountChart._groupSpacing)) /
            buckets.length;

        final double groupWidth = calculatedGroupWidth.clamp(
          ActivityViewingCountChart._minimumGroupWidth,
          ActivityViewingCountChart._maximumGroupWidth,
        );

        final double requiredWidth =
            (groupWidth * buckets.length) +
            (ActivityViewingCountChart._groupSpacing *
                math.max(0, buckets.length - 1));

        final Widget chart = SizedBox(
          width: math.max(availableWidth, requiredWidth),
          height:
              ActivityViewingCountChart._chartHeight +
              ActivityViewingCountChart._axisLabelHeight,
          child: Row(
            key: const ValueKey<String>(
              'detailed-statistics-viewing-count-bars',
            ),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int index = 0; index < buckets.length; index++) ...<Widget>[
                SizedBox(
                  width: groupWidth,
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        height: ActivityViewingCountChart._chartHeight,
                        child: _ViewingCountBarGroup(
                          bucket: buckets[index],
                          maximumCount: maximumCount,
                        ),
                      ),

                      SizedBox(
                        height: ActivityViewingCountChart._axisLabelHeight,
                        child: labelIndexes.contains(index)
                            ? _ActivityAxisLabel(bucket: buckets[index])
                            : null,
                      ),
                    ],
                  ),
                ),

                if (index < buckets.length - 1)
                  const SizedBox(
                    width: ActivityViewingCountChart._groupSpacing,
                  ),
              ],
            ],
          ),
        );

        if (requiredWidth <= availableWidth) {
          return chart;
        }

        return SingleChildScrollView(
          key: const ValueKey<String>(
            'detailed-statistics-viewing-count-scroll',
          ),
          scrollDirection: Axis.horizontal,
          child: chart,
        );
      },
    );
  }
}

final class _ViewingCountBarGroup extends StatelessWidget {
  const _ViewingCountBarGroup({
    required this.bucket,
    required this.maximumCount,
  });

  final StatisticsActivityBucket bucket;
  final int maximumCount;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _tooltipFor(bucket),
      child: Semantics(
        label: _tooltipFor(bucket),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: _CountBar(
                key: ValueKey<String>(
                  'detailed-statistics-episodes-bar-'
                  '${bucket.startDate.toIso8601String()}',
                ),
                count: bucket.episodesWatched,
                maximumCount: maximumCount,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(width: ActivityViewingCountChart._barGap),

            Expanded(
              child: _CountBar(
                key: ValueKey<String>(
                  'detailed-statistics-movies-bar-'
                  '${bucket.startDate.toIso8601String()}',
                ),
                count: bucket.moviesWatched,
                maximumCount: maximumCount,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _CountBar extends StatelessWidget {
  const _CountBar({
    required this.count,
    required this.maximumCount,
    required this.color,
    super.key,
  });

  final int count;
  final int maximumCount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final double fraction = maximumCount > 0 ? count / maximumCount : 0;

    final double height = ActivityViewingCountChart._chartHeight * fraction;

    return SizedBox(
      height: ActivityViewingCountChart._chartHeight,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ClipRRect(
          borderRadius: AppRadius.borderLarge,
          child: Container(
            height: math.max(height, count > 0 ? 4 : 0),
            color: color,
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

final class _EmptyViewingCountChart extends StatelessWidget {
  const _EmptyViewingCountChart();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('detailed-statistics-viewing-count-empty'),
      height:
          ActivityViewingCountChart._chartHeight +
          ActivityViewingCountChart._axisLabelHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.outlineVariant),
        borderRadius: AppRadius.borderLarge,
      ),
      child: Text(
        'No Episodes or Movies watched in this period.',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

final class _ViewingCountLegend extends StatelessWidget {
  const _ViewingCountLegend();

  @override
  Widget build(BuildContext context) {
    return const Row(
      key: ValueKey<String>('detailed-statistics-viewing-count-legend'),
      children: <Widget>[
        _LegendItem(label: 'Episodes', color: AppColors.textPrimary),
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

String _tooltipFor(StatisticsActivityBucket bucket) {
  final String dateLabel =
      StatisticsActivityBucketLabelFormatter.formatTooltipDate(bucket);

  return '$dateLabel\n'
      '${bucket.episodesWatched} '
      '${_episodeLabel(bucket.episodesWatched)} · '
      '${bucket.moviesWatched} '
      '${_movieLabel(bucket.moviesWatched)}';
}

String _episodeLabel(int count) {
  return count == 1 ? 'Episode' : 'Episodes';
}

String _movieLabel(int count) {
  return count == 1 ? 'Movie' : 'Movies';
}
