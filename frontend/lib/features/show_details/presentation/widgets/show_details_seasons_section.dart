import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_season_state.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_seasons_cubit.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_episode.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_season.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_season_progress.dart';

class ShowDetailsSeasonsSection extends StatelessWidget {
  const ShowDetailsSeasonsSection({required this.seasons, super.key});

  final List<ShowDetailsSeason> seasons;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('show-details-seasons-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Seasons',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.lg),
        BlocBuilder<ShowDetailsSeasonsCubit, Map<int, ShowDetailsSeasonState>>(
          builder:
              (BuildContext context, Map<int, ShowDetailsSeasonState> state) {
                return Column(
                  children: <Widget>[
                    for (
                      int index = 0;
                      index < seasons.length;
                      index++
                    ) ...<Widget>[
                      _SeasonAccordion(
                        season: seasons[index],
                        state:
                            state[seasons[index].seasonNumber] ??
                            const ShowDetailsSeasonState(),
                      ),
                      if (index != seasons.length - 1)
                        const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                );
              },
        ),
      ],
    );
  }
}

class _SeasonAccordion extends StatelessWidget {
  const _SeasonAccordion({required this.season, required this.state});

  final ShowDetailsSeason season;
  final ShowDetailsSeasonState state;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: ValueKey<String>('show-details-season-${season.seasonNumber}'),
      decoration: const BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.borderLarge,
        child: Column(
          children: <Widget>[
            _SeasonHeader(
              season: season,
              expanded: state.isExpanded,
              progress: state.progress,
              onPressed: () {
                context.read<ShowDetailsSeasonsCubit>().toggleSeason(
                  season.seasonNumber,
                );
              },
            ),
            if (state.isExpanded)
              _ExpandedSeasonContent(season: season, state: state),
          ],
        ),
      ),
    );
  }
}

class _SeasonHeader extends StatelessWidget {
  const _SeasonHeader({
    required this.season,
    required this.expanded,
    required this.progress,
    required this.onPressed,
  });

  final ShowDetailsSeason season;
  final bool expanded;
  final ShowDetailsSeasonProgress? progress;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ShowDetailsSeasonProgress? currentProgress = progress;

    final String episodeLabel;

    if (currentProgress != null && currentProgress.hasAiredEpisodes) {
      episodeLabel =
          '${currentProgress.watchedAiredEpisodes}'
          ' / '
          '${currentProgress.airedEpisodes}'
          ' aired episodes';
    } else {
      episodeLabel =
          '${season.episodeCount} '
          '${season.episodeCount == 1 ? 'Episode' : 'Episodes'}';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey<String>(
          'show-details-season-toggle-${season.seasonNumber}',
        ),
        onTap: onPressed,
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            season.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),

                        if (currentProgress?.caughtUp ?? false)
                          const Icon(Icons.check_circle_rounded, size: 18),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    Text(
                      episodeLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),

                    if (currentProgress != null &&
                        currentProgress.hasAiredEpisodes) ...<Widget>[
                      const SizedBox(height: AppSpacing.md),

                      ClipRRect(
                        borderRadius: AppRadius.borderFull,
                        child: LinearProgressIndicator(
                          key: ValueKey<String>(
                            'show-details-season-progress-${season.seasonNumber}',
                          ),
                          value: currentProgress.airedProgressValue,
                          minHeight: 5,
                          backgroundColor: AppColors.surfaceLow,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              AnimatedRotation(
                duration: const Duration(milliseconds: 180),
                turns: expanded ? 0.5 : 0,
                child: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandedSeasonContent extends StatelessWidget {
  const _ExpandedSeasonContent({required this.season, required this.state});

  final ShowDetailsSeason season;
  final ShowDetailsSeasonState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const _SeasonLoading();
    }

    if (state.hasError) {
      return _SeasonFailure(
        seasonNumber: season.seasonNumber,
        message:
            state.error?.message ??
            'Could not load the episodes for this season.',
      );
    }

    if (state.episodes.isEmpty) {
      return const _SeasonEmpty();
    }

    return _EpisodeList(
      seasonNumber: season.seasonNumber,
      episodes: state.episodes,
    );
  }
}

class _SeasonLoading extends StatelessWidget {
  const _SeasonLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      key: ValueKey<String>('show-details-season-loading'),
      padding: AppSpacing.cardPaddingLarge,
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _SeasonFailure extends StatelessWidget {
  const _SeasonFailure({required this.seasonNumber, required this.message});

  final int seasonNumber;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: ValueKey<String>('show-details-season-failure-$seasonNumber'),
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.tonalIcon(
            key: ValueKey<String>('show-details-season-retry-$seasonNumber'),
            onPressed: () {
              context.read<ShowDetailsSeasonsCubit>().retrySeason(seasonNumber);
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _SeasonEmpty extends StatelessWidget {
  const _SeasonEmpty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey<String>('show-details-season-empty'),
      padding: AppSpacing.cardPadding,
      child: Text(
        'No episodes are available for this season.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _EpisodeList extends StatelessWidget {
  const _EpisodeList({required this.seasonNumber, required this.episodes});

  final int seasonNumber;
  final List<ShowDetailsEpisode> episodes;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey<String>('show-details-season-episodes-$seasonNumber'),
      children: <Widget>[
        const Divider(height: 1),
        for (int index = 0; index < episodes.length; index++) ...<Widget>[
          _EpisodeRow(seasonNumber: seasonNumber, episode: episodes[index]),
          if (index != episodes.length - 1)
            const Divider(
              height: 1,
              indent: AppSpacing.lg,
              endIndent: AppSpacing.lg,
            ),
        ],
      ],
    );
  }
}

class _EpisodeRow extends StatelessWidget {
  const _EpisodeRow({required this.seasonNumber, required this.episode});

  final int seasonNumber;
  final ShowDetailsEpisode episode;

  @override
  Widget build(BuildContext context) {
    final bool hasImage =
        episode.stillUrl != null && episode.stillUrl!.trim().isNotEmpty;

    return Padding(
      key: ValueKey<String>('show-details-episode-${episode.id}'),
      padding: AppSpacing.cardPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (hasImage) ...<Widget>[
            _EpisodeImage(url: episode.stillUrl!),
            const SizedBox(width: AppSpacing.lg),
          ],
          Expanded(
            child: _EpisodeInformation(
              seasonNumber: seasonNumber,
              episode: episode,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _EpisodeStatusButton(episode: episode),
        ],
      ),
    );
  }
}

class _EpisodeImage extends StatelessWidget {
  const _EpisodeImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.borderMedium,
      child: SizedBox(
        width: 112,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder:
                (BuildContext context, Object error, StackTrace? stackTrace) {
                  return const SizedBox.shrink();
                },
          ),
        ),
      ),
    );
  }
}

class _EpisodeInformation extends StatelessWidget {
  const _EpisodeInformation({
    required this.seasonNumber,
    required this.episode,
  });

  final int seasonNumber;
  final ShowDetailsEpisode episode;

  @override
  Widget build(BuildContext context) {
    final String code =
        'S${seasonNumber.toString().padLeft(2, '0')}'
        'E${episode.episodeNumber.toString().padLeft(2, '0')}';

    final List<String> metadata = <String>[
      if (episode.runtime != null) '${episode.runtime} min',
      if (episode.airDate != null)
        MaterialLocalizations.of(context).formatMediumDate(episode.airDate!),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '$code  ${episode.title}',
          key: ValueKey<String>('show-details-episode-title-${episode.id}'),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (metadata.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            metadata.join(' • '),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
        if (episode.overview?.trim().isNotEmpty ?? false) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            episode.overview!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

class _EpisodeStatusButton extends StatelessWidget {
  const _EpisodeStatusButton({required this.episode});

  final ShowDetailsEpisode episode;

  @override
  Widget build(BuildContext context) {
    /*
     * O estado watched ainda será ligado ao backend na próxima passagem.
     *
     * Já deixamos o elemento visual no layout para não termos de alterar
     * novamente a geometria de cada episode row.
     */
    return IconButton(
      key: ValueKey<String>('show-details-episode-watched-${episode.id}'),
      onPressed: null,
      tooltip: 'Not watched',
      icon: const Icon(Icons.radio_button_unchecked_rounded),
    );
  }
}
