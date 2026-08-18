import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/core/widgets/section_failure_card.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_activity_cubit.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_activity_state.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_summary_cubit.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_summary_state.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_summary.dart';
import 'package:sofawatch/features/statistics/presentation/formatters/statistics_watch_time_formatter.dart';

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
        return switch (state) {
          StatisticsActivityInitial() ||
          StatisticsActivityLoading() => const _ActivityLoading(),

          StatisticsActivitySuccess(:final activity) => _ActivityLoaded(
            activity: activity,
          ),

          StatisticsActivityFailure(:final error) => SectionFailureCard(
            failureKey: 'detailed-statistics-activity-failure',
            error: error,
            onRetry: context.read<StatisticsActivityCubit>().retry,
          ),
        };
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
  const _ActivityLoaded({required this.activity});

  final StatisticsActivity activity;

  @override
  Widget build(BuildContext context) {
    /*
     * This is intentionally only the page shell.
     *
     * The real Activity visualizations are added in the next unit. Keeping
     * this placeholder tied to real loaded data lets us validate routing,
     * dependency injection and loading/error behavior independently first.
     */
    return Container(
      key: const ValueKey<String>('detailed-statistics-activity'),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Text(
        '${activity.days.length} days of activity loaded',
        key: const ValueKey<String>('detailed-statistics-activity-loaded'),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
