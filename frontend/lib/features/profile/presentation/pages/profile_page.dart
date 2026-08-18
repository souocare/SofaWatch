import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/core/errors/app_error_message_mapper.dart';
import 'package:sofawatch/features/profile/application/cubit/profile_cubit.dart';
import 'package:sofawatch/features/profile/application/cubit/profile_state.dart';
import 'package:sofawatch/features/profile/domain/models/profile_user.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/core/widgets/section_failure_card.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_summary_cubit.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_summary_state.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_summary.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/features/statistics/presentation/formatters/statistics_watch_time_formatter.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey<String>('profile-page'),
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          key: const ValueKey<String>('profile-scroll-view'),
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
                key: const ValueKey<String>('profile-content'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Profile',
                    key: const ValueKey<String>('profile-page-title'),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  const _ProfileBody(),

                  const SizedBox(height: AppSpacing.section),

                  const _ProfileStatisticsSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (BuildContext context, ProfileState state) {
        return switch (state) {
          ProfileInitial() || ProfileLoading() => const _ProfileLoading(),

          ProfileSuccess(:final user) => _ProfileContent(user: user),

          ProfileFailure(:final error) => _ProfileFailure(error: error),
        };
      },
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.user});

  final ProfileUser user;

  @override
  Widget build(BuildContext context) {
    return _ProfileIdentityCard(user: user);
  }
}

class _ProfileIdentityCard extends StatelessWidget {
  const _ProfileIdentityCard({required this.user});

  final ProfileUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('profile-user-card'),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Container(
            key: const ValueKey<String>('profile-user-avatar'),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.outlineVariant),
            ),
            alignment: Alignment.center,
            child: Text(
              _initialFor(user.displayName),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),

          const SizedBox(width: AppSpacing.lg),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  user.displayName,
                  key: const ValueKey<String>('profile-user-display-name'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  'SofaWatch profile',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

class _ProfileStatisticsSection extends StatelessWidget {
  const _ProfileStatisticsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('profile-statistics'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Statistics',
          key: const ValueKey<String>('profile-statistics-title'),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: AppSpacing.md),

        BlocBuilder<StatisticsSummaryCubit, StatisticsSummaryState>(
          builder: (BuildContext context, StatisticsSummaryState state) {
            return switch (state) {
              StatisticsSummaryInitial() ||
              StatisticsSummaryLoading() => const _ProfileStatisticsLoading(),

              StatisticsSummarySuccess(:final summary) =>
                _ProfileStatisticsContent(summary: summary),

              StatisticsSummaryFailure(:final error) => SectionFailureCard(
                failureKey: 'profile-statistics-failure',
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

class _ProfileStatisticsContent extends StatelessWidget {
  const _ProfileStatisticsContent({required this.summary});

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
              key: const ValueKey<String>('profile-statistics-grid'),
              crossAxisCount: useFourColumns ? 4 : 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: useFourColumns ? 1.15 : 1.3,
              children: <Widget>[
                _ProfileStatisticCard(
                  cardKey: 'profile-stat-shows',
                  icon: Icons.tv_rounded,
                  value: summary.showsWatched.toString(),
                  label: 'Shows',
                ),
                _ProfileStatisticCard(
                  cardKey: 'profile-stat-movies',
                  icon: Icons.movie_rounded,
                  value: summary.moviesWatched.toString(),
                  label: 'Movies',
                ),
                _ProfileStatisticCard(
                  cardKey: 'profile-stat-episodes',
                  icon: Icons.play_circle_rounded,
                  value: summary.episodesWatched.toString(),
                  label: 'Episodes',
                ),
                _ProfileStatisticCard(
                  cardKey: 'profile-stat-watch-time',
                  icon: Icons.schedule_rounded,
                  value: formatProfileWatchTime(summary.watchTimeMinutes),
                  label: 'Watch time',
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const ValueKey<String>(
                  'profile-detailed-statistics-action',
                ),
                onPressed: () {
                  context.pushNamed(AppRoute.detailedStatistics.name);
                },
                child: const Text('View detailed statistics →'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileStatisticCard extends StatelessWidget {
  const _ProfileStatisticCard({
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
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatisticsLoading extends StatelessWidget {
  const _ProfileStatisticsLoading();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      key: const ValueKey<String>('profile-statistics-loading'),
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      children: const <Widget>[
        _ProfileStatisticSkeleton(),
        _ProfileStatisticSkeleton(),
        _ProfileStatisticSkeleton(),
        _ProfileStatisticSkeleton(),
      ],
    );
  }
}

class _ProfileStatisticSkeleton extends StatelessWidget {
  const _ProfileStatisticSkeleton();

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

class _ProfileLoading extends StatelessWidget {
  const _ProfileLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      key: ValueKey<String>('profile-loading'),
      height: 120,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ProfileFailure extends StatelessWidget {
  const _ProfileFailure({required this.error});

  final AppException error;

  @override
  Widget build(BuildContext context) {
    final String message = AppErrorMessageMapper.map(error);

    return Container(
      key: const ValueKey<String>('profile-failure'),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            key: const ValueKey<String>('profile-retry'),
            onPressed: context.read<ProfileCubit>().retry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

String _initialFor(String displayName) {
  final String trimmed = displayName.trim();

  if (trimmed.isEmpty) {
    return '?';
  }

  return trimmed.characters.first.toUpperCase();
}

String formatProfileWatchTime(int totalMinutes) {
  if (totalMinutes <= 0) {
    return '0m';
  }

  final int days = totalMinutes ~/ (24 * 60);
  final int remainingAfterDays = totalMinutes % (24 * 60);

  final int hours = remainingAfterDays ~/ 60;
  final int minutes = remainingAfterDays % 60;

  if (days > 0) {
    if (hours > 0) {
      return '${days}d ${hours}h';
    }

    return '${days}d';
  }

  if (hours > 0) {
    if (minutes > 0) {
      return '${hours}h ${minutes}m';
    }

    return '${hours}h';
  }

  return '${minutes}m';
}
