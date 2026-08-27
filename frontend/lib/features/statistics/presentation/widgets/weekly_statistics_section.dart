import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/core/widgets/section_failure_card.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_cubit.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_state.dart';
import 'package:sofawatch/features/statistics/domain/models/weekly_statistics.dart';

class WeeklyStatisticsSection extends StatelessWidget {
  const WeeklyStatisticsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StatisticsCubit, StatisticsState>(
      builder: (BuildContext context, StatisticsState state) {
        return Column(
          key: const ValueKey<String>('home-your-week'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Your Week',
              key: const ValueKey<String>('home-your-week-title'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            switch (state) {
              StatisticsInitial() ||
              StatisticsLoading() => const _WeeklyStatisticsLoading(),

              StatisticsSuccess(:final statistics) => _WeeklyStatisticsContent(
                statistics: statistics,
              ),

              StatisticsFailure(:final error) => SectionFailureCard(
                failureKey: 'home-your-week-failure',
                error: error,
                onRetry: context.read<StatisticsCubit>().retry,
              ),
            },
          ],
        );
      },
    );
  }
}

class _WeeklyStatisticsContent extends StatelessWidget {
  const _WeeklyStatisticsContent({required this.statistics});

  final WeeklyStatistics statistics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool useHorizontalScroll = constraints.maxWidth < 360;

        if (useHorizontalScroll) {
          return SingleChildScrollView(
            key: const ValueKey<String>('home-your-week-horizontal-scroll'),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: 116,
                  child: _WeeklyStatisticCard(
                    cardKey: 'home-stat-episodes',
                    icon: Icons.tv_rounded,
                    value: statistics.episodesWatched.toString(),
                    label: 'Episodes',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 116,
                  child: _WeeklyStatisticCard(
                    cardKey: 'home-stat-movies',
                    icon: Icons.movie_rounded,
                    value: statistics.moviesWatched.toString(),
                    label: 'Movies',
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 116,
                  child: _WeeklyStatisticCard(
                    cardKey: 'home-stat-watch-time',
                    icon: Icons.schedule_rounded,
                    value: formatWatchTime(statistics.watchTimeMinutes),
                    label: 'Watch time',
                  ),
                ),
              ],
            ),
          );
        }

        return Row(
          key: const ValueKey<String>('home-your-week-cards'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _WeeklyStatisticCard(
                cardKey: 'home-stat-episodes',
                icon: Icons.tv_rounded,
                value: statistics.episodesWatched.toString(),
                label: 'Episodes',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _WeeklyStatisticCard(
                cardKey: 'home-stat-movies',
                icon: Icons.movie_rounded,
                value: statistics.moviesWatched.toString(),
                label: 'Movies',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _WeeklyStatisticCard(
                cardKey: 'home-stat-watch-time',
                icon: Icons.schedule_rounded,
                value: formatWatchTime(statistics.watchTimeMinutes),
                label: 'Watch time',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WeeklyStatisticCard extends StatelessWidget {
  const _WeeklyStatisticCard({
    required this.cardKey,
    required this.icon,
    required this.value,
    required this.label,
  });

  final String cardKey;
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;

    final bool compact = width < AppBreakpoints.mobile;

    final bool veryCompact = width < 340;

    return Container(
      key: ValueKey<String>(cardKey),
      constraints: BoxConstraints(minHeight: veryCompact ? 92 : 104),
      padding: EdgeInsets.all(
        veryCompact
            ? AppSpacing.sm
            : compact
            ? AppSpacing.md
            : AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Icon(
            icon,
            size: veryCompact
                ? 17
                : compact
                ? 19
                : 21,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                (veryCompact
                        ? Theme.of(context).textTheme.titleMedium
                        : compact
                        ? Theme.of(context).textTheme.titleLarge
                        : Theme.of(context).textTheme.headlineSmall)
                    ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyStatisticsLoading extends StatelessWidget {
  const _WeeklyStatisticsLoading();

  @override
  Widget build(BuildContext context) {
    return const Row(
      key: ValueKey<String>('home-your-week-loading'),
      children: <Widget>[
        Expanded(child: _WeeklyStatisticSkeleton()),
        SizedBox(width: AppSpacing.sm),
        Expanded(child: _WeeklyStatisticSkeleton()),
        SizedBox(width: AppSpacing.sm),
        Expanded(child: _WeeklyStatisticSkeleton()),
      ],
    );
  }
}

class _WeeklyStatisticSkeleton extends StatelessWidget {
  const _WeeklyStatisticSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

String formatWatchTime(int totalMinutes) {
  if (totalMinutes <= 0) {
    return '0m';
  }

  final int hours = totalMinutes ~/ 60;
  final int minutes = totalMinutes % 60;

  if (hours == 0) {
    return '${minutes}m';
  }

  if (minutes == 0) {
    return '${hours}h';
  }

  return '${hours}h ${minutes}m';
}
