import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity_period.dart';
import 'package:sofawatch/features/statistics/presentation/formatters/statistics_watch_time_formatter.dart';

final class ActivityHeatmap extends StatelessWidget {
  const ActivityHeatmap({
    required this.activity,
    required this.period,
    super.key,
  });

  static const double _cellSize = 12;
  static const double _cellSpacing = 3;

  final StatisticsActivity activity;
  final StatisticsActivityPeriod period;

  @override
  Widget build(BuildContext context) {
    final List<DailyStatisticsActivity> days = _visibleDays(
      activity: activity,
      period: period,
    );

    final int maximumMinutes = days.fold<int>(0, (
      int maximum,
      DailyStatisticsActivity day,
    ) {
      return math.max(maximum, day.watchTimeMinutes);
    });

    return Container(
      key: const ValueKey<String>('detailed-statistics-activity-heatmap'),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Activity heatmap',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_isLimitedToOneYear(period))
                Text(
                  'Last 365 days',
                  key: const ValueKey<String>(
                    'detailed-statistics-activity-heatmap-range',
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          if (days.isEmpty)
            const _EmptyHeatmap()
          else
            _HeatmapGrid(days: days, maximumMinutes: maximumMinutes),

          const SizedBox(height: AppSpacing.md),

          const _HeatmapLegend(),
        ],
      ),
    );
  }
}

final class _HeatmapGrid extends StatelessWidget {
  const _HeatmapGrid({required this.days, required this.maximumMinutes});

  final List<DailyStatisticsActivity> days;
  final int maximumMinutes;

  @override
  Widget build(BuildContext context) {
    final List<List<DailyStatisticsActivity?>> weeks = _buildCalendarWeeks(
      days,
    );

    return SingleChildScrollView(
      key: const ValueKey<String>(
        'detailed-statistics-activity-heatmap-scroll',
      ),
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (int weekIndex = 0; weekIndex < weeks.length; weekIndex++) ...[
            Column(
              children: <Widget>[
                for (final DailyStatisticsActivity? day in weeks[weekIndex])
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: ActivityHeatmap._cellSpacing,
                    ),
                    child: day == null
                        ? const SizedBox(
                            width: ActivityHeatmap._cellSize,
                            height: ActivityHeatmap._cellSize,
                          )
                        : _HeatmapCell(
                            day: day,
                            maximumMinutes: maximumMinutes,
                          ),
                  ),
              ],
            ),
            if (weekIndex < weeks.length - 1)
              const SizedBox(width: ActivityHeatmap._cellSpacing),
          ],
        ],
      ),
    );
  }
}

final class _HeatmapCell extends StatelessWidget {
  const _HeatmapCell({required this.day, required this.maximumMinutes});

  final DailyStatisticsActivity day;
  final int maximumMinutes;

  @override
  Widget build(BuildContext context) {
    final int level = _intensityLevel(
      minutes: day.watchTimeMinutes,
      maximumMinutes: maximumMinutes,
    );

    final String tooltip = _tooltipFor(day);

    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: tooltip,
        child: Container(
          key: ValueKey<String>(
            'detailed-statistics-activity-heatmap-day-'
            '${_dateOnly(day.day).toIso8601String()}',
          ),
          width: ActivityHeatmap._cellSize,
          height: ActivityHeatmap._cellSize,
          decoration: BoxDecoration(
            color: _colorForLevel(level),
            borderRadius: BorderRadius.circular(3),
            border: level == 0
                ? Border.all(color: AppColors.outlineVariant)
                : null,
          ),
        ),
      ),
    );
  }
}

final class _EmptyHeatmap extends StatelessWidget {
  const _EmptyHeatmap();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey<String>('detailed-statistics-activity-heatmap-empty'),
      height: 80,
      child: Center(
        child: Text(
          'No activity available for this period.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

final class _HeatmapLegend extends StatelessWidget {
  const _HeatmapLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey<String>(
        'detailed-statistics-activity-heatmap-legend',
      ),
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Text(
          'Less',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(width: AppSpacing.sm),
        for (int level = 0; level <= 4; level++) ...<Widget>[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _colorForLevel(level),
              borderRadius: BorderRadius.circular(2),
              border: level == 0
                  ? Border.all(color: AppColors.outlineVariant)
                  : null,
            ),
          ),
          if (level < 4) const SizedBox(width: AppSpacing.xs),
        ],
        const SizedBox(width: AppSpacing.sm),
        Text(
          'More',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

List<DailyStatisticsActivity> _visibleDays({
  required StatisticsActivity activity,
  required StatisticsActivityPeriod period,
}) {
  if (!_isLimitedToOneYear(period) || activity.days.length <= 365) {
    return activity.days;
  }

  return activity.days.sublist(activity.days.length - 365);
}

bool _isLimitedToOneYear(StatisticsActivityPeriod period) {
  return period == StatisticsActivityPeriod.year1 ||
      period == StatisticsActivityPeriod.all;
}

List<List<DailyStatisticsActivity?>> _buildCalendarWeeks(
  List<DailyStatisticsActivity> days,
) {
  if (days.isEmpty) {
    return const <List<DailyStatisticsActivity?>>[];
  }

  final List<DailyStatisticsActivity> sorted =
      List<DailyStatisticsActivity>.from(days)..sort(
        (DailyStatisticsActivity a, DailyStatisticsActivity b) =>
            a.day.compareTo(b.day),
      );

  final List<List<DailyStatisticsActivity?>> weeks =
      <List<DailyStatisticsActivity?>>[];

  List<DailyStatisticsActivity?> currentWeek =
      List<DailyStatisticsActivity?>.filled(7, null);

  for (final DailyStatisticsActivity day in sorted) {
    final int weekdayIndex = day.day.weekday - 1;

    if (currentWeek[weekdayIndex] != null) {
      weeks.add(currentWeek);

      currentWeek = List<DailyStatisticsActivity?>.filled(7, null);
    }

    currentWeek[weekdayIndex] = day;

    if (weekdayIndex == DateTime.sunday - 1) {
      weeks.add(currentWeek);

      currentWeek = List<DailyStatisticsActivity?>.filled(7, null);
    }
  }

  if (currentWeek.any((DailyStatisticsActivity? day) => day != null)) {
    weeks.add(currentWeek);
  }

  return weeks;
}

int _intensityLevel({required int minutes, required int maximumMinutes}) {
  if (minutes <= 0 || maximumMinutes <= 0) {
    return 0;
  }

  final double fraction = minutes / maximumMinutes;

  if (fraction <= 0.25) {
    return 1;
  }

  if (fraction <= 0.50) {
    return 2;
  }

  if (fraction <= 0.75) {
    return 3;
  }

  return 4;
}

Color _colorForLevel(int level) {
  return switch (level) {
    0 => AppColors.surface,
    1 => AppColors.textSecondary.withValues(alpha: 0.30),
    2 => AppColors.textSecondary.withValues(alpha: 0.50),
    3 => AppColors.textPrimary.withValues(alpha: 0.70),
    _ => AppColors.textPrimary,
  };
}

String _tooltipFor(DailyStatisticsActivity day) {
  final DateTime date = _dateOnly(day.day);

  return '${date.day}/${date.month}/${date.year}\n'
      '${formatStatisticsWatchTime(day.watchTimeMinutes)} watched · '
      '${day.episodesWatched} ${_episodeLabel(day.episodesWatched)} · '
      '${day.moviesWatched} ${_movieLabel(day.moviesWatched)}';
}

String _episodeLabel(int count) {
  return count == 1 ? 'Episode' : 'Episodes';
}

String _movieLabel(int count) {
  return count == 1 ? 'Movie' : 'Movies';
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}
