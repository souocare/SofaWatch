import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/theme/tokens/app_breakpoints.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_cubit.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_state.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_genre.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_network.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_season.dart';
import 'package:sofawatch/features/show_details/presentation/widgets/show_details_seasons_section.dart';

class ShowDetailsPage extends StatelessWidget {
  const ShowDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: BlocBuilder<ShowDetailsCubit, ShowDetailsState>(
          builder: (BuildContext context, ShowDetailsState state) {
            return switch (state) {
              ShowDetailsInitial() ||
              ShowDetailsLoading() => const _ShowDetailsLoading(),
              ShowDetailsSuccess(:final details) => _ShowDetailsContent(
                details: details,
              ),
              ShowDetailsFailure(:final error) => _ShowDetailsFailure(
                isTimeout: error.isTimeout,
                onRetry: context.read<ShowDetailsCubit>().retry,
              ),
            };
          },
        ),
      ),
    );
  }
}

class _ShowDetailsContent extends StatelessWidget {
  const _ShowDetailsContent({required this.details});

  final ShowDetails details;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isDesktop = constraints.maxWidth >= AppBreakpoints.tablet;

        return SingleChildScrollView(
          key: const ValueKey<String>('show-details-content'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _ShowHero(details: details, isDesktop: isDesktop),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: isDesktop ? AppSpacing.xxxl : AppSpacing.xl,
                      right: isDesktop ? AppSpacing.xxxl : AppSpacing.xl,
                      top: AppSpacing.xxl,
                      bottom: AppSpacing.section,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (_hasTagline(details)) ...<Widget>[
                          _Tagline(tagline: details.tagline!),
                          const SizedBox(height: AppSpacing.xxl),
                        ],

                        if (details.genres.isNotEmpty) ...<Widget>[
                          _Genres(genres: details.genres),
                          const SizedBox(height: AppSpacing.xxxl),
                        ],

                        _Overview(overview: details.overview),

                        const SizedBox(height: AppSpacing.section),

                        _SeriesInfo(details: details),

                        if (details.seasons.isNotEmpty) ...<Widget>[
                          const SizedBox(height: AppSpacing.section),
                          ShowDetailsSeasonsSection(seasons: details.seasons),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _hasTagline(ShowDetails details) {
    return details.tagline?.trim().isNotEmpty ?? false;
  }
}

class _ShowHero extends StatelessWidget {
  const _ShowHero({required this.details, required this.isDesktop});

  final ShowDetails details;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final double heroHeight = isDesktop ? 420 : 360;

    return SizedBox(
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _BackdropImage(url: details.backdropUrl),

          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: <double>[0, 0.45, 1],
                colors: <Color>[
                  Colors.transparent,
                  Color(0x66000000),
                  AppColors.surface,
                ],
              ),
            ),
          ),

          Positioned(
            top: AppSpacing.lg,
            right: AppSpacing.lg,
            child: IconButton.filledTonal(
              key: const ValueKey<String>('show-details-close-button'),
              onPressed: context.pop,
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Close',
            ),
          ),

          Positioned(
            left: isDesktop ? AppSpacing.extraHuge : AppSpacing.xl,
            right: isDesktop ? AppSpacing.extraHuge : AppSpacing.xl,
            bottom: AppSpacing.xxl,
            child: _HeroContent(details: details, isDesktop: isDesktop),
          ),
        ],
      ),
    );
  }
}

class _HeroContent extends StatelessWidget {
  const _HeroContent({required this.details, required this.isDesktop});

  final ShowDetails details;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        _PosterImage(url: details.posterUrl, width: isDesktop ? 150 : 112),

        SizedBox(width: isDesktop ? AppSpacing.xxxl : AppSpacing.lg),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  details.title,
                  key: const ValueKey<String>('show-details-title'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      (isDesktop
                              ? Theme.of(context).textTheme.headlineLarge
                              : Theme.of(context).textTheme.headlineMedium)
                          ?.copyWith(fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: AppSpacing.sm),

                _HeroSubtitle(details: details),

                if (details.voteAverage > 0) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  _RatingBadge(
                    rating: details.voteAverage,
                    voteCount: details.voteCount,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroSubtitle extends StatelessWidget {
  const _HeroSubtitle({required this.details});

  final ShowDetails details;

  @override
  Widget build(BuildContext context) {
    final List<String> values = <String>[
      _dateRange(details),
      if (details.status.trim().isNotEmpty) details.status,
    ].where((String value) => value.isNotEmpty).toList(growable: false);

    return Text(
      values.join(' • '),
      key: const ValueKey<String>('show-details-subtitle'),
      style: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
    );
  }

  String _dateRange(ShowDetails details) {
    final int? start = details.releaseYear;

    if (start == null) {
      return '';
    }

    if (details.inProduction) {
      return '$start – Present';
    }

    final int? end = details.endYear;

    if (end == null || end == start) {
      return start.toString();
    }

    return '$start – $end';
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating, required this.voteCount});

  final double rating;
  final int voteCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey<String>('show-details-rating'),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(Icons.star_rounded, size: 19),
        const SizedBox(width: AppSpacing.xs),
        Text(
          rating.toStringAsFixed(1),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (voteCount > 0) ...<Widget>[
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${_formatCount(voteCount)} votes',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }

    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }

    return count.toString();
  }
}

class _Tagline extends StatelessWidget {
  const _Tagline({required this.tagline});

  final String tagline;

  @override
  Widget build(BuildContext context) {
    return Text(
      tagline,
      key: const ValueKey<String>('show-details-tagline'),
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: AppColors.textSecondary,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

class _Genres extends StatelessWidget {
  const _Genres({required this.genres});

  final List<ShowDetailsGenre> genres;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const ValueKey<String>('show-details-genres'),
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: genres
          .map((ShowDetailsGenre genre) {
            return _GenreChip(
              key: ValueKey<String>('show-details-genre-${genre.tmdbId}'),
              genre: genre.name,
            );
          })
          .toList(growable: false),
    );
  }
}

class _GenreChip extends StatelessWidget {
  const _GenreChip({required this.genre, super.key});

  final String genre;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderFull,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Text(genre, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.overview});

  final String? overview;

  @override
  Widget build(BuildContext context) {
    return _DetailsSection(
      title: 'Overview',
      child: Text(
        _resolvedOverview(),
        key: const ValueKey<String>('show-details-overview'),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppColors.textSecondary,
          height: 1.5,
        ),
      ),
    );
  }

  String _resolvedOverview() {
    final String? value = overview?.trim();

    if (value == null || value.isEmpty) {
      return 'No overview is available for this series.';
    }

    return value;
  }
}

class _SeriesInfo extends StatelessWidget {
  const _SeriesInfo({required this.details});

  final ShowDetails details;

  @override
  Widget build(BuildContext context) {
    final List<_InfoItem> items = <_InfoItem>[
      _InfoItem(
        icon: Icons.calendar_today_rounded,
        label: 'Aired',
        value: _dateRange(),
      ),
      _InfoItem(icon: Icons.tv_rounded, label: 'Status', value: details.status),
      if (details.showType.trim().isNotEmpty)
        _InfoItem(
          icon: Icons.category_outlined,
          label: 'Type',
          value: details.showType,
        ),
      _InfoItem(
        icon: Icons.video_library_outlined,
        label: 'Seasons',
        value: details.numberOfSeasons.toString(),
      ),
      _InfoItem(
        icon: Icons.playlist_play_rounded,
        label: 'Episodes',
        value: details.numberOfEpisodes.toString(),
      ),
      if (details.primaryEpisodeRunTime != null)
        _InfoItem(
          icon: Icons.schedule_rounded,
          label: 'Runtime',
          value: '~${details.primaryEpisodeRunTime} min',
        ),
      if (details.originalLanguage.trim().isNotEmpty)
        _InfoItem(
          icon: Icons.language_rounded,
          label: 'Language',
          value: details.originalLanguage.toUpperCase(),
        ),
    ];

    return _DetailsSection(
      title: 'Series Info',
      child: Column(
        children: <Widget>[
          _InfoGrid(items: items),

          if (details.networks.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.xxl),
            _Networks(networks: details.networks),
          ],
        ],
      ),
    );
  }

  String _dateRange() {
    final int? start = details.releaseYear;

    if (start == null) {
      return 'Unknown';
    }

    if (details.inProduction) {
      return '$start – Present';
    }

    final int? end = details.endYear;

    if (end == null || end == start) {
      return start.toString();
    }

    return '$start – $end';
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});

  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool useTwoColumns = constraints.maxWidth >= 600;

        if (!useTwoColumns) {
          return Column(
            children: items
                .map((_InfoItem item) {
                  return _InfoRow(item: item);
                })
                .toList(growable: false),
          );
        }

        return Wrap(
          spacing: AppSpacing.xxl,
          runSpacing: AppSpacing.sm,
          children: items
              .map((_InfoItem item) {
                return SizedBox(
                  width: (constraints.maxWidth - AppSpacing.xxl) / 2,
                  child: _InfoRow(item: item),
                );
              })
              .toList(growable: false),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.item});

  final _InfoItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          Icon(item.icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 82,
            child: Text(
              item.label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              item.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

final class _InfoItem {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _Networks extends StatelessWidget {
  const _Networks({required this.networks});

  final List<ShowDetailsNetwork> networks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Networks',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),

        const SizedBox(height: AppSpacing.md),

        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: networks
              .map((ShowDetailsNetwork network) {
                return DecoratedBox(
                  key: ValueKey<String>(
                    'show-details-network-${network.tmdbId}',
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: AppRadius.borderMedium,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      network.name,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),

        const SizedBox(height: AppSpacing.lg),

        child,
      ],
    );
  }
}

class _BackdropImage extends StatelessWidget {
  const _BackdropImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = url;

    if (imageUrl == null || imageUrl.isEmpty) {
      return const ColoredBox(color: AppColors.surfaceLow);
    }

    return Image.network(
      imageUrl,
      key: const ValueKey<String>('show-details-backdrop'),
      fit: BoxFit.cover,
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
            return const ColoredBox(color: AppColors.surfaceLow);
          },
    );
  }
}

class _PosterImage extends StatelessWidget {
  const _PosterImage({required this.url, required this.width});

  final String? url;
  final double width;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.borderLarge,
      child: SizedBox(
        width: width,
        child: AspectRatio(aspectRatio: 2 / 3, child: _buildImage()),
      ),
    );
  }

  Widget _buildImage() {
    final String? imageUrl = url;

    if (imageUrl == null || imageUrl.isEmpty) {
      return const _PosterPlaceholder();
    }

    return Image.network(
      imageUrl,
      key: const ValueKey<String>('show-details-poster'),
      fit: BoxFit.cover,
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
            return const _PosterPlaceholder();
          },
    );
  }
}

class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      key: ValueKey<String>('show-details-poster-placeholder'),
      color: AppColors.surfaceHigh,
      child: Center(child: Icon(Icons.tv_rounded, color: AppColors.textMuted)),
    );
  }
}

class _ShowDetailsLoading extends StatelessWidget {
  const _ShowDetailsLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: ValueKey<String>('show-details-loading'),
      child: CircularProgressIndicator(),
    );
  }
}

class _ShowDetailsFailure extends StatelessWidget {
  const _ShowDetailsFailure({required this.isTimeout, required this.onRetry});

  final bool isTimeout;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey<String>('show-details-failure'),
      child: Padding(
        padding: AppSpacing.cardPaddingLarge,
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
              isTimeout
                  ? 'Loading the series took too long'
                  : 'Could not load this series',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: AppSpacing.sm),

            Text(
              'Please try again.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),

            const SizedBox(height: AppSpacing.xl),

            FilledButton.icon(
              key: const ValueKey<String>('show-details-retry'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
