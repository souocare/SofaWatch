import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/features/home/application/cubit/home_cubit.dart';
import 'package:sofawatch/features/home/application/cubit/home_state.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/shows/domain/models/upcoming_item.dart';

class UpcomingSection extends StatelessWidget {
  const UpcomingSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (HomeState previous, HomeState current) {
        return previous.upcoming != current.upcoming ||
            previous.isLoadingUpcoming != current.isLoadingUpcoming ||
            previous.upcomingError != current.upcomingError;
      },
      builder: (BuildContext context, HomeState state) {
        if (state.isLoadingUpcoming && state.upcoming.isEmpty) {
          return const _UpcomingLoading();
        }

        if (state.upcomingError != null && state.upcoming.isEmpty) {
          return const _UpcomingFailure();
        }

        if (state.upcoming.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          key: const ValueKey<String>('home-upcoming'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Upcoming',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Next 7 days',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            for (
              int index = 0;
              index < state.upcoming.length;
              index++
            ) ...<Widget>[
              _UpcomingCard(item: state.upcoming[index]),
              if (index < state.upcoming.length - 1)
                const SizedBox(height: AppSpacing.md),
            ],
          ],
        );
      },
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.item});

  final UpcomingItem item;

  @override
  Widget build(BuildContext context) {
    final bool isPlanning = item.libraryStatus == LibraryStatus.planning;

    return Material(
      color: AppColors.surfaceHigh,
      borderRadius: AppRadius.borderLarge,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey<String>('home-upcoming-${item.episode.id}'),
        onTap: () {
          context.pushNamed(
            AppRoute.episodeDetails.name,
            pathParameters: <String, String>{'episodeId': item.episode.id},
          );
        },
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            children: <Widget>[
              _EpisodeArtwork(
                imageUrl: item.episode.stillUrl ?? item.backdropUrl,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            item.showTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (isPlanning) ...<Widget>[
                          const SizedBox(width: AppSpacing.sm),
                          const _PlanningBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${item.episode.code} • ${item.episode.title}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: <Widget>[
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 15,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          _formatUpcomingDate(item.episode.airDate),
                          key: ValueKey<String>(
                            'home-upcoming-date-${item.episode.id}',
                          ),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    if (isPlanning) ...<Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'You haven’t started this show yet',
                        key: ValueKey<String>(
                          'home-upcoming-not-started-${item.episode.id}',
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EpisodeArtwork extends StatelessWidget {
  const _EpisodeArtwork({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.borderMedium,
      child: SizedBox(
        width: 104,
        height: 64,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: AppColors.surface),
          child: imageUrl == null
              ? const Center(
                  child: Icon(Icons.tv_outlined, color: AppColors.textMuted),
                )
              : Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (
                        BuildContext context,
                        Object error,
                        StackTrace? stackTrace,
                      ) {
                        return const Center(
                          child: Icon(
                            Icons.tv_outlined,
                            color: AppColors.textMuted,
                          ),
                        );
                      },
                ),
        ),
      ),
    );
  }
}

class _PlanningBadge extends StatelessWidget {
  const _PlanningBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('home-upcoming-planning-badge'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderFull,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Text(
        'Not started',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _UpcomingLoading extends StatelessWidget {
  const _UpcomingLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      key: ValueKey<String>('home-upcoming-loading'),
      height: 96,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _UpcomingFailure extends StatelessWidget {
  const _UpcomingFailure();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('home-upcoming-failure'),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          const Expanded(child: Text('Could not load upcoming episodes.')),
          TextButton(
            key: const ValueKey<String>('home-upcoming-retry'),
            onPressed: () {
              context.read<HomeCubit>().retryUpcoming();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

String _formatUpcomingDate(DateTime value) {
  const List<String> weekdays = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

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

  return '${weekdays[value.weekday - 1]}, '
      '${value.day} ${months[value.month - 1]}';
}
