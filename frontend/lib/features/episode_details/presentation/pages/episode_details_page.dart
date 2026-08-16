import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/app/theme/tokens/app_breakpoints.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/episode_details/application/cubit/episode_details_cubit.dart';
import 'package:sofawatch/features/episode_details/application/cubit/episode_details_operation.dart';
import 'package:sofawatch/features/episode_details/application/cubit/episode_details_state.dart';
import 'package:sofawatch/features/episode_details/domain/models/episode_details.dart';
import 'package:sofawatch/features/episode_details/domain/models/episode_details_episode.dart';
import 'package:sofawatch/features/episode_details/domain/models/episode_details_progress.dart';
import 'package:sofawatch/features/episode_details/domain/models/episode_details_show.dart';

class EpisodeDetailsPage extends StatelessWidget {
  const EpisodeDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: BlocConsumer<EpisodeDetailsCubit, EpisodeDetailsState>(
          listenWhen:
              (EpisodeDetailsState previous, EpisodeDetailsState current) {
                if (current is! EpisodeDetailsSuccess) {
                  return false;
                }

                if (!current.operation.hasFailed) {
                  return false;
                }

                if (previous is! EpisodeDetailsSuccess) {
                  return true;
                }

                return previous.operation != current.operation;
              },
          listener: (BuildContext context, EpisodeDetailsState state) {
            if (state is! EpisodeDetailsSuccess) {
              return;
            }

            final AppException? error = state.operation.error;

            if (error == null) {
              return;
            }

            final String message = switch (state.operation.intent) {
              EpisodeDetailsOperationIntent.markWatched =>
                error.code == 'episode_cannot_be_watched'
                    ? 'This episode has not aired yet.'
                    : error.isTimeout
                    ? 'Marking this episode as watched took too long.'
                    : 'Could not mark this episode as watched.',
              EpisodeDetailsOperationIntent.markUnwatched =>
                error.isTimeout
                    ? 'Marking this episode as unwatched took too long.'
                    : 'Could not mark this episode as unwatched.',
              EpisodeDetailsOperationIntent.rewatch =>
                error.code == 'episode_cannot_be_watched'
                    ? 'This episode has not aired yet.'
                    : error.isTimeout
                    ? 'Recording this rewatch took too long.'
                    : 'Could not record this rewatch.',
              null => 'Could not update this episode.',
            };

            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(message)));
          },
          builder: (BuildContext context, EpisodeDetailsState state) {
            return switch (state) {
              EpisodeDetailsInitial() ||
              EpisodeDetailsLoading() => const _EpisodeDetailsLoading(),
              EpisodeDetailsFailure(:final error) => _EpisodeDetailsFailure(
                error: error,
                onRetry: context.read<EpisodeDetailsCubit>().retry,
              ),
              EpisodeDetailsSuccess(:final details) => _EpisodeDetailsContent(
                details: details,
                operation: state.operation,
              ),
            };
          },
        ),
      ),
    );
  }
}

class _EpisodeDetailsLoading extends StatelessWidget {
  const _EpisodeDetailsLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: ValueKey<String>('episode-details-loading'),
      child: CircularProgressIndicator(),
    );
  }
}

class _EpisodeDetailsFailure extends StatelessWidget {
  const _EpisodeDetailsFailure({required this.error, required this.onRetry});

  final AppException error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey<String>('episode-details-failure'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                error.isTimeout
                    ? 'Loading this episode took too long.'
                    : 'Could not load this episode.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.tonalIcon(
                key: const ValueKey<String>('episode-details-retry'),
                onPressed: () {
                  onRetry();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EpisodeDetailsContent extends StatelessWidget {
  const _EpisodeDetailsContent({
    required this.details,
    required this.operation,
  });

  final EpisodeDetails details;
  final EpisodeDetailsOperation operation;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isDesktop = constraints.maxWidth >= AppBreakpoints.desktop;

        return CustomScrollView(
          key: const ValueKey<String>('episode-details-content'),
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: _EpisodeDetailsHeader(
                details: details,
                isDesktop: isDesktop,
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                isDesktop ? AppSpacing.xxxl : AppSpacing.xl,
                AppSpacing.xl,
                isDesktop ? AppSpacing.xxxl : AppSpacing.xl,
                AppSpacing.section,
              ),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: _EpisodeDetailsBody(
                      details: details,
                      operation: operation,
                      isDesktop: isDesktop,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EpisodeDetailsHeader extends StatelessWidget {
  const _EpisodeDetailsHeader({required this.details, required this.isDesktop});

  final EpisodeDetails details;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final EpisodeDetailsEpisode episode = details.episode;
    final EpisodeDetailsShow show = details.show;

    return Stack(
      children: <Widget>[
        SizedBox(
          height: isDesktop ? 360 : 280,
          width: double.infinity,
          child: _EpisodeBackdrop(
            imageUrl: episode.stillUrl ?? show.backdropUrl,
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.black.withValues(alpha: 0.15),
                  AppColors.surface.withValues(alpha: 0.92),
                  AppColors.surface,
                ],
                stops: const <double>[0, 0.72, 1],
              ),
            ),
          ),
        ),
        Positioned(
          top: AppSpacing.md,
          left: AppSpacing.md,
          child: IconButton.filledTonal(
            key: const ValueKey<String>('episode-details-close'),
            tooltip: 'Close',
            onPressed: context.pop,
            icon: const Icon(Icons.close_rounded),
          ),
        ),
        Positioned(
          left: isDesktop ? AppSpacing.xxxl : AppSpacing.xl,
          right: isDesktop ? AppSpacing.xxxl : AppSpacing.xl,
          bottom: AppSpacing.xl,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _ShowLink(show: show),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    details.episodeCode,
                    key: const ValueKey<String>('episode-details-episode-code'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    episode.title,
                    key: const ValueKey<String>('episode-details-title'),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: isDesktop
                        ? Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          )
                        : Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EpisodeBackdrop extends StatelessWidget {
  const _EpisodeBackdrop({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final String? url = imageUrl;

    if (url == null || url.isEmpty) {
      return const ColoredBox(
        key: ValueKey<String>('episode-details-artwork-placeholder'),
        color: AppColors.surfaceHigh,
        child: Center(
          child: Icon(Icons.tv_rounded, size: 64, color: AppColors.textMuted),
        ),
      );
    }

    return Image.network(
      url,
      key: const ValueKey<String>('episode-details-artwork'),
      fit: BoxFit.cover,
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
            return const ColoredBox(
              key: ValueKey<String>('episode-details-artwork-error'),
              color: AppColors.surfaceHigh,
              child: Center(
                child: Icon(
                  Icons.tv_rounded,
                  size: 64,
                  color: AppColors.textMuted,
                ),
              ),
            );
          },
    );
  }
}

class _ShowLink extends StatelessWidget {
  const _ShowLink({required this.show});

  final EpisodeDetailsShow show;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const ValueKey<String>('episode-details-show-link'),
      borderRadius: AppRadius.borderMedium,
      onTap: () {
        context.pushNamed(
          AppRoute.showDetails.name,
          pathParameters: <String, String>{'showId': show.tmdbId.toString()},
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              child: Text(
                show.title,
                key: const ValueKey<String>('episode-details-show-title'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _EpisodeDetailsBody extends StatelessWidget {
  const _EpisodeDetailsBody({
    required this.details,
    required this.operation,
    required this.isDesktop,
  });

  final EpisodeDetails details;
  final EpisodeDetailsOperation operation;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final Widget metadata = _EpisodeMetadata(details: details);

    final bool canWatch = details.episode.isAvailableToWatchOn(DateTime.now());

    final Widget viewingStatus = _ViewingStatus(
      progress: details.progress,
      operation: operation,
      canWatch: canWatch,
      hasKnownAirDate: details.episode.airDate != null,
      onMarkWatched: context.read<EpisodeDetailsCubit>().markWatched,
      onMarkUnwatched: context.read<EpisodeDetailsCubit>().markUnwatched,
      onRewatch: context.read<EpisodeDetailsCubit>().rewatch,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: metadata),
              const SizedBox(width: AppSpacing.xxl),
              SizedBox(width: 300, child: viewingStatus),
            ],
          )
        else ...<Widget>[
          metadata,
          const SizedBox(height: AppSpacing.xl),
          viewingStatus,
        ],
        if (details.episode.overview case final String overview
            when overview.trim().isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.section),
          Text(
            'Overview',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            overview,
            key: const ValueKey<String>('episode-details-overview'),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}

class _EpisodeMetadata extends StatelessWidget {
  const _EpisodeMetadata({required this.details});

  final EpisodeDetails details;

  @override
  Widget build(BuildContext context) {
    final EpisodeDetailsEpisode episode = details.episode;

    final List<_MetadataValue> values = <_MetadataValue>[
      _MetadataValue(
        icon: Icons.calendar_today_outlined,
        value: episode.airDate == null
            ? 'Air date unknown'
            : MaterialLocalizations.of(
                context,
              ).formatMediumDate(episode.airDate!),
      ),
      if (episode.runtime != null)
        _MetadataValue(
          icon: Icons.schedule_rounded,
          value: '${episode.runtime} min',
        ),
      if (episode.voteAverage > 0)
        _MetadataValue(
          icon: Icons.star_rounded,
          value: episode.voteAverage.toStringAsFixed(1),
        ),
      _MetadataValue(
        icon: Icons.video_library_outlined,
        value: details.season.title,
      ),
    ];

    return Wrap(
      key: const ValueKey<String>('episode-details-metadata'),
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.md,
      children: values
          .map((_MetadataValue value) => _MetadataChip(value: value))
          .toList(growable: false),
    );
  }
}

class _MetadataValue {
  const _MetadataValue({required this.icon, required this.value});

  final IconData icon;
  final String value;
}

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({required this.value});

  final _MetadataValue value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(value.icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          value.value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _ViewingStatus extends StatelessWidget {
  const _ViewingStatus({
    required this.progress,
    required this.operation,
    required this.canWatch,
    required this.hasKnownAirDate,
    required this.onMarkWatched,
    required this.onMarkUnwatched,
    required this.onRewatch,
  });

  final EpisodeDetailsProgress progress;
  final EpisodeDetailsOperation operation;

  final Future<void> Function() onMarkWatched;
  final Future<void> Function() onMarkUnwatched;
  final Future<void> Function() onRewatch;
  final bool canWatch;
  final bool hasKnownAirDate;

  @override
  Widget build(BuildContext context) {
    final bool isUpdating = operation.isUpdating;

    final bool isRewatching =
        isUpdating && operation.intent == EpisodeDetailsOperationIntent.rewatch;

    final bool isChangingWatchedState = isUpdating && !isRewatching;

    return DecoratedBox(
      key: const ValueKey<String>('episode-details-viewing-status'),
      decoration: const BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
      ),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  progress.isWatched
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: progress.isWatched
                      ? AppColors.primary
                      : AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    progress.isWatched ? 'Watched' : 'Not watched',
                    key: const ValueKey<String>(
                      'episode-details-watched-state',
                    ),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (!canWatch && !progress.isWatched) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Row(
                key: const ValueKey<String>('episode-details-not-aired'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(
                    Icons.schedule_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      hasKnownAirDate
                          ? 'This episode has not aired yet.'
                          : 'This episode does not have a known air date yet.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (progress.hasWatchHistory) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              _ViewingStatusRow(
                label: 'Times watched',
                value: progress.watchCount.toString(),
              ),
              if (progress.lastWatchedAt != null) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                _ViewingStatusRow(
                  label: 'Last watched',
                  value: _formatDateTime(context, progress.lastWatchedAt!),
                ),
              ],
            ],

            const SizedBox(height: AppSpacing.lg),

            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                key: const ValueKey<String>('episode-details-watched-action'),
                onPressed: isUpdating || (!progress.isWatched && !canWatch)
                    ? null
                    : () {
                        if (progress.isWatched) {
                          onMarkUnwatched();
                        } else {
                          onMarkWatched();
                        }
                      },
                icon: isChangingWatchedState
                    ? const SizedBox(
                        key: ValueKey<String>(
                          'episode-details-watched-action-progress',
                        ),
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        progress.isWatched
                            ? Icons.visibility_off_outlined
                            : Icons.check_rounded,
                      ),
                label: Text(
                  isChangingWatchedState
                      ? 'Updating…'
                      : progress.isWatched
                      ? 'Mark as unwatched'
                      : !canWatch
                      ? 'Not available yet'
                      : 'Mark as watched',
                ),
              ),
            ),

            if (progress.hasWatchHistory) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  key: const ValueKey<String>('episode-details-rewatch-action'),
                  onPressed: isUpdating || !canWatch ? null : onRewatch,
                  icon: isRewatching
                      ? const SizedBox(
                          key: ValueKey<String>(
                            'episode-details-rewatch-action-progress',
                          ),
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.replay_rounded),
                  label: Text(isRewatching ? 'Recording…' : 'Watched again'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(BuildContext context, DateTime value) {
    final MaterialLocalizations localizations = MaterialLocalizations.of(
      context,
    );

    final DateTime localValue = value.toLocal();

    return '${localizations.formatMediumDate(localValue)} • '
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(localValue))}';
  }
}

class _ViewingStatusRow extends StatelessWidget {
  const _ViewingStatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
