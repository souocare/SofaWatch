import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/core/errors/app_error_message_mapper.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/core/widgets/section_failure_card.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_activity_cubit.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_activity_state.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_summary_cubit.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_summary_state.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_summary.dart';
import 'package:sofawatch/features/statistics/presentation/formatters/statistics_watch_time_formatter.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity_period.dart';
import 'package:sofawatch/features/statistics/presentation/widgets/activity_watch_time_chart.dart';
import 'package:sofawatch/features/statistics/presentation/widgets/activity_viewing_count_chart.dart';
import 'package:sofawatch/features/statistics/presentation/widgets/activity_heatmap.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_habits_cubit.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_habits_state.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_habits.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_content_insights_cubit.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_content_insights_state.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_content_insights.dart';

class DetailedStatisticsPage extends StatelessWidget {
  const DetailedStatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey<String>('detailed-statistics-page'),
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          key: const ValueKey<String>('detailed-statistics-scroll-view'),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.mobileHorizontalPadding,
            AppSpacing.xxl,
            AppSpacing.mobileHorizontalPadding,
            AppSpacing.section,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxContentWidth,
              ),
              child: Column(
                key: const ValueKey<String>('detailed-statistics-content'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const _DetailedStatisticsHeader(),

                  const SizedBox(height: AppSpacing.xxl),

                  const _OverviewSection(),

                  const SizedBox(height: AppSpacing.section),

                  const _ActivityBody(),

                  const SizedBox(height: AppSpacing.section),

                  const _WatchingHabitsSection(),

                  const SizedBox(height: AppSpacing.section),

                  const _ContentInsightsSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailedStatisticsHeader extends StatelessWidget {
  const _DetailedStatisticsHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        IconButton(
          key: const ValueKey<String>('detailed-statistics-back'),
          tooltip: 'Back',
          onPressed: () {
            context.pop();
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),

        const SizedBox(width: AppSpacing.sm),

        Expanded(
          child: Text(
            'Detailed Statistics',
            key: const ValueKey<String>('detailed-statistics-title'),
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('detailed-statistics-overview'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Overview',
          key: const ValueKey<String>('detailed-statistics-overview-title'),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: AppSpacing.md),

        BlocBuilder<StatisticsSummaryCubit, StatisticsSummaryState>(
          builder: (BuildContext context, StatisticsSummaryState state) {
            return switch (state) {
              StatisticsSummaryInitial() ||
              StatisticsSummaryLoading() => const _OverviewLoading(),

              StatisticsSummarySuccess(:final summary) => _OverviewContent(
                summary: summary,
              ),

              StatisticsSummaryFailure(:final error) => SectionFailureCard(
                failureKey: 'detailed-statistics-overview-failure',
                error: error,
                onRetry: context.read<StatisticsSummaryCubit>().retry,
              ),
            };
          },
        ),
      ],
    );
  }
}

class _OverviewContent extends StatelessWidget {
  const _OverviewContent({required this.summary});

  final StatisticsSummary summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool useFourColumns = constraints.maxWidth >= 720;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            GridView.count(
              key: const ValueKey<String>('detailed-statistics-overview-grid'),
              crossAxisCount: useFourColumns ? 4 : 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: useFourColumns ? 1.1 : 1.0,
              children: <Widget>[
                _OverviewCard(
                  cardKey: 'detailed-statistics-watch-time',
                  icon: Icons.schedule_rounded,
                  label: 'Watch time',
                  value: formatStatisticsWatchTime(summary.watchTimeMinutes),
                  supportingText:
                      '${formatStatisticsWatchTime(summary.rewatchTimeMinutes)} rewatched',
                ),
                _OverviewCard(
                  cardKey: 'detailed-statistics-episodes',
                  icon: Icons.play_circle_rounded,
                  label: 'Episodes watched',
                  value: summary.episodes.watchCount.toString(),
                  supportingText:
                      '${summary.episodes.uniqueCount} unique · '
                      '${summary.episodes.rewatchCount} '
                      '${_rewatchLabel(summary.episodes.rewatchCount)}',
                ),
                _OverviewCard(
                  cardKey: 'detailed-statistics-movies',
                  icon: Icons.movie_rounded,
                  label: 'Movies watched',
                  value: summary.movies.watchCount.toString(),
                  supportingText:
                      '${summary.movies.uniqueCount} unique · '
                      '${summary.movies.rewatchCount} '
                      '${_rewatchLabel(summary.movies.rewatchCount)}',
                ),
                _OverviewCard(
                  cardKey: 'detailed-statistics-shows',
                  icon: Icons.tv_rounded,
                  label: 'Shows watched',
                  value: summary.showsWatched.toString(),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            _MediaTimeSplit(
              episodeMinutes: summary.episodes.watchTimeMinutes,
              movieMinutes: summary.movies.watchTimeMinutes,
            ),
          ],
        );
      },
    );
  }
}

String _rewatchLabel(int count) {
  return count == 1 ? 'rewatch' : 'rewatches';
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.cardKey,
    required this.icon,
    required this.label,
    required this.value,
    this.supportingText,
  });

  final String cardKey;
  final IconData icon;
  final String label;
  final String value;
  final String? supportingText;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey<String>(cardKey),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 22, color: AppColors.textSecondary),

          const SizedBox(height: AppSpacing.sm),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: AppSpacing.xs),

          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),

          if (supportingText != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              supportingText!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _MediaTimeSplit extends StatelessWidget {
  const _MediaTimeSplit({
    required this.episodeMinutes,
    required this.movieMinutes,
  });

  final int episodeMinutes;
  final int movieMinutes;

  @override
  Widget build(BuildContext context) {
    final int total = episodeMinutes + movieMinutes;

    final double showsFraction = total > 0 ? episodeMinutes / total : 0;

    final double moviesFraction = total > 0 ? movieMinutes / total : 0;

    return Container(
      key: const ValueKey<String>('detailed-statistics-media-time-split'),
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
            'Time watching media',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: AppSpacing.lg),

          ClipRRect(
            borderRadius: AppRadius.borderLarge,
            child: SizedBox(
              key: const ValueKey<String>('detailed-statistics-media-time-bar'),
              height: 12,
              child: total == 0
                  ? Container(color: AppColors.outlineVariant)
                  : Row(
                      children: <Widget>[
                        if (showsFraction > 0)
                          Expanded(
                            flex: _fractionFlex(showsFraction),
                            child: Container(color: AppColors.textPrimary),
                          ),
                        if (moviesFraction > 0)
                          Expanded(
                            flex: _fractionFlex(moviesFraction),
                            child: Container(color: AppColors.textSecondary),
                          ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          _MediaSplitRow(
            label: 'Shows',
            watchTime: formatStatisticsWatchTime(episodeMinutes),
            percentage: _percentage(showsFraction),
          ),

          const SizedBox(height: AppSpacing.sm),

          _MediaSplitRow(
            label: 'Movies',
            watchTime: formatStatisticsWatchTime(movieMinutes),
            percentage: _percentage(moviesFraction),
          ),
        ],
      ),
    );
  }
}

int _fractionFlex(double fraction) {
  return (fraction * 10000).round().clamp(1, 10000);
}

String _percentage(double fraction) {
  return '${(fraction * 100).round()}%';
}

class _MediaSplitRow extends StatelessWidget {
  const _MediaSplitRow({
    required this.label,
    required this.watchTime,
    required this.percentage,
  });

  final String label;
  final String watchTime;
  final String percentage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Text(watchTime, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(width: AppSpacing.md),
        SizedBox(
          width: 44,
          child: Text(
            percentage,
            textAlign: TextAlign.end,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _OverviewLoading extends StatelessWidget {
  const _OverviewLoading();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      key: const ValueKey<String>('detailed-statistics-overview-loading'),
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.0,
      children: const <Widget>[
        _OverviewSkeleton(),
        _OverviewSkeleton(),
        _OverviewSkeleton(),
        _OverviewSkeleton(),
      ],
    );
  }
}

class _OverviewSkeleton extends StatelessWidget {
  const _OverviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
    );
  }
}

class _ActivityBody extends StatelessWidget {
  const _ActivityBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StatisticsActivityCubit, StatisticsActivityState>(
      builder: (BuildContext context, StatisticsActivityState state) {
        return Column(
          key: const ValueKey<String>('detailed-statistics-activity-section'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Activity over time',
              key: const ValueKey<String>('detailed-statistics-activity-title'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: AppSpacing.md),

            _ActivityPeriodSelector(
              selectedPeriod: _selectedPeriodFor(state),
              pendingPeriod: _pendingPeriodFor(state),
              enabled: state is! StatisticsActivityLoading,
            ),

            const SizedBox(height: AppSpacing.lg),

            switch (state) {
              StatisticsActivityInitial() ||
              StatisticsActivityLoading() => const _ActivityLoading(),

              StatisticsActivitySuccess(:final activity, :final period) =>
                _ActivityLoaded(activity: activity, period: period),

              StatisticsActivityFailure(:final error) => SectionFailureCard(
                failureKey: 'detailed-statistics-activity-failure',
                error: error,
                onRetry: context.read<StatisticsActivityCubit>().retry,
              ),
            },

            if (state case StatisticsActivitySuccess(
              :final periodChangeError?,
            )) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              _ActivityPeriodChangeFailure(error: periodChangeError),
            ],
          ],
        );
      },
    );
  }
}

class _ActivityLoading extends StatelessWidget {
  const _ActivityLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('detailed-statistics-activity-loading'),
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(),
    );
  }
}

class _ActivityLoaded extends StatelessWidget {
  const _ActivityLoaded({required this.activity, required this.period});

  final StatisticsActivity activity;
  final StatisticsActivityPeriod period;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('detailed-statistics-activity'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ActivityWatchTimeChart(activity: activity, period: period),

        const SizedBox(height: AppSpacing.md),

        ActivityViewingCountChart(activity: activity, period: period),

        const SizedBox(height: AppSpacing.md),

        ActivityHeatmap(activity: activity, period: period),
      ],
    );
  }
}

StatisticsActivityPeriod _selectedPeriodFor(StatisticsActivityState state) {
  return switch (state) {
    StatisticsActivityLoading(:final period) => period,
    StatisticsActivitySuccess(:final period) => period,
    StatisticsActivityFailure(:final period) => period,
    StatisticsActivityInitial() => StatisticsActivityCubit.defaultPeriod,
  };
}

StatisticsActivityPeriod? _pendingPeriodFor(StatisticsActivityState state) {
  return switch (state) {
    StatisticsActivitySuccess(:final pendingPeriod) => pendingPeriod,
    _ => null,
  };
}

class _ActivityPeriodSelector extends StatelessWidget {
  const _ActivityPeriodSelector({
    required this.selectedPeriod,
    required this.pendingPeriod,
    required this.enabled,
  });

  final StatisticsActivityPeriod selectedPeriod;
  final StatisticsActivityPeriod? pendingPeriod;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey<String>(
        'detailed-statistics-activity-period-selector',
      ),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: StatisticsActivityPeriod.values
            .map(
              (StatisticsActivityPeriod period) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: _ActivityPeriodButton(
                  period: period,
                  isSelected: selectedPeriod == period,
                  isPending: pendingPeriod == period,
                  enabled: enabled,
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _ActivityPeriodButton extends StatelessWidget {
  const _ActivityPeriodButton({
    required this.period,
    required this.isSelected,
    required this.isPending,
    required this.enabled,
  });

  final StatisticsActivityPeriod period;
  final bool isSelected;
  final bool isPending;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final bool canPress = enabled && !isPending;

    return ChoiceChip(
      key: ValueKey<String>('detailed-statistics-period-${period.apiValue}'),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(period.label),
          if (isPending) ...<Widget>[
            const SizedBox(width: AppSpacing.xs),
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: canPress
          ? (_) {
              context.read<StatisticsActivityCubit>().changePeriod(period);
            }
          : null,
    );
  }
}

class _ActivityPeriodChangeFailure extends StatelessWidget {
  const _ActivityPeriodChangeFailure({required this.error});

  final AppException error;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey<String>('detailed-statistics-activity-period-error'),
      children: <Widget>[
        const Icon(
          Icons.error_outline_rounded,
          size: 18,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            AppErrorMessageMapper.map(error),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _WatchingHabitsSection extends StatelessWidget {
  const _WatchingHabitsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('detailed-statistics-watching-habits'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Watching habits',
          key: const ValueKey<String>(
            'detailed-statistics-watching-habits-title',
          ),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: AppSpacing.md),

        BlocBuilder<StatisticsHabitsCubit, StatisticsHabitsState>(
          builder: (BuildContext context, StatisticsHabitsState state) {
            return switch (state) {
              StatisticsHabitsInitial() ||
              StatisticsHabitsLoading() => const _WatchingHabitsLoading(),

              StatisticsHabitsSuccess(:final habits) => _WatchingHabitsContent(
                habits: habits,
              ),

              StatisticsHabitsFailure(:final error) => SectionFailureCard(
                failureKey: 'detailed-statistics-watching-habits-failure',
                error: error,
                onRetry: context.read<StatisticsHabitsCubit>().retry,
              ),
            };
          },
        ),
      ],
    );
  }
}

class _WatchingHabitsContent extends StatelessWidget {
  const _WatchingHabitsContent({required this.habits});

  final StatisticsHabits habits;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = switch (constraints.maxWidth) {
          >= 720 => 3,
          >= 520 => 2,
          _ => 1,
        };

        final double totalSpacing = AppSpacing.sm * (columns - 1);

        final double cardWidth =
            (constraints.maxWidth - totalSpacing) / columns;

        return Wrap(
          key: const ValueKey<String>(
            'detailed-statistics-watching-habits-content',
          ),
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            SizedBox(
              width: cardWidth,
              child: _WatchingHabitCard(
                cardKey: 'detailed-statistics-current-streak',
                icon: Icons.local_fire_department_rounded,
                value: habits.currentStreakDays.toString(),
                label: 'Current streak',
                supportingText: _dayLabel(habits.currentStreakDays),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _WatchingHabitCard(
                cardKey: 'detailed-statistics-longest-streak',
                icon: Icons.emoji_events_rounded,
                value: habits.longestStreakDays.toString(),
                label: 'Longest streak',
                supportingText: _dayLabel(habits.longestStreakDays),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _WatchingHabitCard(
                cardKey: 'detailed-statistics-biggest-marathon',
                icon: Icons.timer_rounded,
                value: formatStatisticsWatchTime(
                  habits.biggestMarathonWatchTimeMinutes,
                ),
                label: 'Biggest marathon',
                supportingText: _formatStatisticsDay(habits.biggestMarathonDay),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _WatchingHabitCard(
                cardKey: 'detailed-statistics-longest-binge',
                icon: Icons.playlist_play_rounded,
                value: habits.longestBingeEpisodeCount.toString(),
                label: 'Longest binge',
                supportingText: _formatBingeSupportingText(
                  episodeCount: habits.longestBingeEpisodeCount,
                  day: habits.longestBingeDay,
                ),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _WatchingHabitCard(
                cardKey: 'detailed-statistics-average-active-day',
                icon: Icons.av_timer_rounded,
                value: formatStatisticsWatchTime(
                  habits.averageActiveDayWatchTimeMinutes,
                ),
                label: 'Average active day',
                supportingText: 'per active day',
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _WatchingHabitCard(
                cardKey: 'detailed-statistics-most-active-weekday',
                icon: Icons.calendar_today_rounded,
                value: habits.mostActiveWeekday ?? '—',
                label: 'Most active weekday',
                supportingText: _watchLabel(habits.mostActiveWeekdayWatchCount),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WatchingHabitCard extends StatelessWidget {
  const _WatchingHabitCard({
    required this.cardKey,
    required this.icon,
    required this.value,
    required this.label,
    required this.supportingText,
  });

  final String cardKey;
  final IconData icon;
  final String value;
  final String label;
  final String supportingText;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey<String>(cardKey),
      constraints: const BoxConstraints(minHeight: 112),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.borderLarge,
              border: Border.all(color: AppColors.outlineVariant),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: AppColors.textSecondary),
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  supportingText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WatchingHabitsLoading extends StatelessWidget {
  const _WatchingHabitsLoading();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final int columns = switch (constraints.maxWidth) {
          >= 720 => 3,
          >= 520 => 2,
          _ => 1,
        };

        final double totalSpacing = AppSpacing.sm * (columns - 1);

        final double cardWidth =
            (constraints.maxWidth - totalSpacing) / columns;

        return Wrap(
          key: const ValueKey<String>(
            'detailed-statistics-watching-habits-loading',
          ),
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            for (int index = 0; index < 6; index++)
              SizedBox(width: cardWidth, child: const _WatchingHabitSkeleton()),
          ],
        );
      },
    );
  }
}

class _WatchingHabitSkeleton extends StatelessWidget {
  const _WatchingHabitSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
    );
  }
}

class _ContentInsightsSection extends StatelessWidget {
  const _ContentInsightsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('detailed-statistics-content-insights'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Content insights',
          key: const ValueKey<String>(
            'detailed-statistics-content-insights-title',
          ),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: AppSpacing.md),

        BlocBuilder<
          StatisticsContentInsightsCubit,
          StatisticsContentInsightsState
        >(
          builder:
              (BuildContext context, StatisticsContentInsightsState state) {
                return switch (state) {
                  StatisticsContentInsightsInitial() ||
                  StatisticsContentInsightsLoading() =>
                    const _ContentInsightsLoading(),

                  StatisticsContentInsightsSuccess(:final insights) =>
                    _ContentInsightsContent(insights: insights),

                  StatisticsContentInsightsFailure(:final error) =>
                    SectionFailureCard(
                      failureKey:
                          'detailed-statistics-content-insights-failure',
                      error: error,
                      onRetry: context
                          .read<StatisticsContentInsightsCubit>()
                          .retry,
                    ),
                };
              },
        ),
      ],
    );
  }
}

class _ContentInsightsContent extends StatelessWidget {
  const _ContentInsightsContent({required this.insights});

  final StatisticsContentInsights insights;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>(
        'detailed-statistics-content-insights-content',
      ),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _ShowInsightGroup(
          groupKey: 'detailed-statistics-most-watched-shows',
          title: 'Most watched Shows',
          items: insights.mostWatchedShows,
          valueBuilder: (StatisticsShowInsight item) {
            return _watchLabel(item.watchCount);
          },
        ),

        const SizedBox(height: AppSpacing.lg),

        _ShowInsightGroup(
          groupKey: 'detailed-statistics-most-rewatched-shows',
          title: 'Most rewatched Shows',
          items: insights.mostRewatchedShows,
          valueBuilder: (StatisticsShowInsight item) {
            return _rewatchCountLabel(item.rewatchCount);
          },
        ),

        const SizedBox(height: AppSpacing.lg),

        _EpisodeInsightGroup(items: insights.mostRewatchedEpisodes),

        const SizedBox(height: AppSpacing.lg),

        _MovieInsightGroup(items: insights.mostRewatchedMovies),

        const SizedBox(height: AppSpacing.lg),

        _GenreInsightGroup(
          groupKey: 'detailed-statistics-top-show-genres',
          title: 'Top Show genres',
          items: insights.topShowGenres,
        ),

        const SizedBox(height: AppSpacing.lg),

        _GenreInsightGroup(
          groupKey: 'detailed-statistics-top-movie-genres',
          title: 'Top Movie genres',
          items: insights.topMovieGenres,
        ),
      ],
    );
  }
}

class _ContentInsightsLoading extends StatelessWidget {
  const _ContentInsightsLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>(
        'detailed-statistics-content-insights-loading',
      ),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const <Widget>[
        _ContentInsightSkeleton(),

        SizedBox(height: AppSpacing.sm),

        _ContentInsightSkeleton(),

        SizedBox(height: AppSpacing.sm),

        _ContentInsightSkeleton(),
      ],
    );
  }
}

class _ContentInsightSkeleton extends StatelessWidget {
  const _ContentInsightSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
    );
  }
}

class _ShowInsightGroup extends StatelessWidget {
  const _ShowInsightGroup({
    required this.groupKey,
    required this.title,
    required this.items,
    required this.valueBuilder,
  });

  final String groupKey;
  final String title;
  final List<StatisticsShowInsight> items;
  final String Function(StatisticsShowInsight item) valueBuilder;

  @override
  Widget build(BuildContext context) {
    return _ContentInsightGroup(
      groupKey: groupKey,
      title: title,
      isEmpty: items.isEmpty,
      children: <Widget>[
        for (int index = 0; index < items.length; index++)
          _ContentInsightMediaRow(
            rowKey: '$groupKey-${items[index].showId}',
            rank: index + 1,
            imageUrl: items[index].posterUrl,
            imageAspectRatio: 2 / 3,
            fallbackIcon: Icons.tv_rounded,
            title: items[index].title,
            supportingText: valueBuilder(items[index]),
          ),
      ],
    );
  }
}

class _EpisodeInsightGroup extends StatelessWidget {
  const _EpisodeInsightGroup({required this.items});

  final List<StatisticsEpisodeInsight> items;

  @override
  Widget build(BuildContext context) {
    const String groupKey = 'detailed-statistics-most-rewatched-episodes';

    return _ContentInsightGroup(
      groupKey: groupKey,
      title: 'Most rewatched Episodes',
      isEmpty: items.isEmpty,
      children: <Widget>[
        for (int index = 0; index < items.length; index++)
          _ContentInsightMediaRow(
            rowKey: '$groupKey-${items[index].episodeId}',
            rank: index + 1,
            imageUrl: items[index].stillUrl,
            imageAspectRatio: 16 / 9,
            fallbackIcon: Icons.play_circle_outline_rounded,
            title: items[index].episodeTitle,
            subtitle:
                '${items[index].showTitle} · '
                'S${_twoDigits(items[index].seasonNumber)}'
                'E${_twoDigits(items[index].episodeNumber)}',
            supportingText: _rewatchCountLabel(items[index].rewatchCount),
          ),
      ],
    );
  }
}

class _MovieInsightGroup extends StatelessWidget {
  const _MovieInsightGroup({required this.items});

  final List<StatisticsMovieInsight> items;

  @override
  Widget build(BuildContext context) {
    const String groupKey = 'detailed-statistics-most-rewatched-movies';

    return _ContentInsightGroup(
      groupKey: groupKey,
      title: 'Most rewatched Movies',
      isEmpty: items.isEmpty,
      children: <Widget>[
        for (int index = 0; index < items.length; index++)
          _ContentInsightMediaRow(
            rowKey: '$groupKey-${items[index].movieId}',
            rank: index + 1,
            imageUrl: items[index].posterUrl,
            imageAspectRatio: 2 / 3,
            fallbackIcon: Icons.movie_rounded,
            title: items[index].title,
            supportingText: _rewatchCountLabel(items[index].rewatchCount),
          ),
      ],
    );
  }
}

class _GenreInsightGroup extends StatelessWidget {
  const _GenreInsightGroup({
    required this.groupKey,
    required this.title,
    required this.items,
  });

  final String groupKey;
  final String title;
  final List<StatisticsGenreInsight> items;

  @override
  Widget build(BuildContext context) {
    return _ContentInsightGroup(
      groupKey: groupKey,
      title: title,
      isEmpty: items.isEmpty,
      children: <Widget>[
        for (int index = 0; index < items.length; index++)
          _GenreInsightRow(
            rowKey: '$groupKey-${items[index].genreId}',
            rank: index + 1,
            item: items[index],
          ),
      ],
    );
  }
}

class _ContentInsightGroup extends StatelessWidget {
  const _ContentInsightGroup({
    required this.groupKey,
    required this.title,
    required this.isEmpty,
    required this.children,
  });

  final String groupKey;
  final String title;
  final bool isEmpty;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey<String>(groupKey),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          title,
          key: ValueKey<String>('$groupKey-title'),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),

        const SizedBox(height: AppSpacing.sm),

        if (isEmpty)
          _ContentInsightEmptyState(emptyKey: '$groupKey-empty')
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: AppRadius.borderLarge,
              border: Border.all(color: AppColors.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: <Widget>[
                for (
                  int index = 0;
                  index < children.length;
                  index++
                ) ...<Widget>[
                  children[index],
                  if (index < children.length - 1)
                    const Divider(height: 1, color: AppColors.outlineVariant),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ContentInsightMediaRow extends StatelessWidget {
  const _ContentInsightMediaRow({
    required this.rowKey,
    required this.rank,
    required this.imageUrl,
    required this.imageAspectRatio,
    required this.fallbackIcon,
    required this.title,
    required this.supportingText,
    this.subtitle,
  });

  final String rowKey;
  final int rank;
  final String? imageUrl;
  final double imageAspectRatio;
  final IconData fallbackIcon;
  final String title;
  final String? subtitle;
  final String supportingText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: ValueKey<String>(rowKey),
      padding: AppSpacing.cardPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          _ContentInsightArtwork(
            imageUrl: imageUrl,
            aspectRatio: imageAspectRatio,
            fallbackIcon: fallbackIcon,
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),

                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.xs),

                Text(
                  supportingText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentInsightArtwork extends StatelessWidget {
  const _ContentInsightArtwork({
    required this.imageUrl,
    required this.aspectRatio,
    required this.fallbackIcon,
  });

  final String? imageUrl;
  final double aspectRatio;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final String? normalizedUrl = imageUrl?.trim();

    /*
     * Posters use 2:3 while Episode stills use 16:9.
     *
     * Keeping a fixed height gives every ranked row a predictable vertical
     * rhythm while AspectRatio derives the appropriate width.
     */
    const double height = 64;

    return ClipRRect(
      borderRadius: AppRadius.borderMedium,
      child: SizedBox(
        height: height,
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: normalizedUrl == null || normalizedUrl.isEmpty
              ? _ContentInsightArtworkFallback(icon: fallbackIcon)
              : Image.network(
                  normalizedUrl,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (
                        BuildContext context,
                        Object error,
                        StackTrace? stackTrace,
                      ) {
                        return _ContentInsightArtworkFallback(
                          icon: fallbackIcon,
                        );
                      },
                ),
        ),
      ),
    );
  }
}

class _ContentInsightArtworkFallback extends StatelessWidget {
  const _ContentInsightArtworkFallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      alignment: Alignment.center,
      child: Icon(icon, size: 24, color: AppColors.textSecondary),
    );
  }
}

class _GenreInsightRow extends StatelessWidget {
  const _GenreInsightRow({
    required this.rowKey,
    required this.rank,
    required this.item,
  });

  final String rowKey;
  final int rank;
  final StatisticsGenreInsight item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: ValueKey<String>(rowKey),
      padding: AppSpacing.cardPadding,
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 32,
            child: Text(
              '#$rank',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.sm),

          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.borderLarge,
              border: Border.all(color: AppColors.outlineVariant),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.local_movies_outlined,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          Text(
            _watchLabel(item.watchCount),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ContentInsightEmptyState extends StatelessWidget {
  const _ContentInsightEmptyState({required this.emptyKey});

  final String emptyKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey<String>(emptyKey),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.insights_outlined,
            size: 20,
            color: AppColors.textSecondary,
          ),

          const SizedBox(width: AppSpacing.sm),

          Expanded(
            child: Text(
              'Not enough viewing history yet.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

String _twoDigits(int value) {
  return value.toString().padLeft(2, '0');
}

String _dayLabel(int days) {
  return days == 1 ? 'day' : 'days';
}

String _formatStatisticsDay(DateTime? day) {
  if (day == null) {
    return 'No known day';
  }

  const List<String> months = <String>[
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

  return '${day.day} ${months[day.month - 1]} ${day.year}';
}

String _formatBingeSupportingText({
  required int episodeCount,
  required DateTime? day,
}) {
  final String episodeLabel = episodeCount == 1 ? 'episode' : 'episodes';

  if (day == null) {
    return episodeLabel;
  }

  return '$episodeLabel · ${_formatStatisticsDay(day)}';
}

String _watchLabel(int count) {
  return count == 1 ? '1 watch' : '$count watches';
}

String _rewatchCountLabel(int count) {
  return count == 1 ? '1 rewatch' : '$count rewatches';
}
