import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/core/widgets/server_network_image.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_cubit.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_state.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_genre.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_network.dart';
import 'package:sofawatch/features/show_details/presentation/widgets/show_details_library_action.dart';
import 'package:sofawatch/features/show_details/presentation/widgets/show_details_seasons_section.dart';

class ShowDetailsPage extends StatelessWidget {
  const ShowDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocBuilder<ShowDetailsCubit, ShowDetailsState>(
        builder: (BuildContext context, ShowDetailsState state) {
          return switch (state) {
            ShowDetailsInitial() ||
            ShowDetailsLoading() => const _ShowDetailsLoading(),
            ShowDetailsSuccess(:final details) => _ShowDetailsContent(
              details: details,
            ),
            ShowDetailsFailure(:final error) => SafeArea(
              child: _ShowDetailsFailure(
                isTimeout: error.isTimeout,
                onRetry: context.read<ShowDetailsCubit>().retry,
              ),
            ),
          };
        },
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
              _ShowDetailsBody(details: details, isDesktop: isDesktop),
            ],
          ),
        );
      },
    );
  }
}

class _ShowDetailsBody extends StatelessWidget {
  const _ShowDetailsBody({required this.details, required this.isDesktop});

  final ShowDetails details;
  final bool isDesktop;

  bool _hasAdditionalInfo(ShowDetails details) {
    final String originalTitle = details.originalTitle.trim();

    final bool hasDistinctOriginalTitle =
        originalTitle.isNotEmpty && originalTitle != details.title.trim();

    return hasDistinctOriginalTitle || details.networks.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
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
              _ShowPrimaryDetails(details: details),

              const SizedBox(height: AppSpacing.section),

              _SeriesInfo(details: details),

              if (details.seasons.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.section),
                ShowDetailsSeasonsSection(seasons: details.seasons),
              ],

              if (_hasAdditionalInfo(details)) ...<Widget>[
                const SizedBox(height: AppSpacing.section),
                _AdditionalInfo(details: details),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ShowPrimaryDetails extends StatelessWidget {
  const _ShowPrimaryDetails({required this.details});

  final ShowDetails details;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (_hasTagline) ...<Widget>[
          _Tagline(tagline: details.tagline!.trim()),
          const SizedBox(height: AppSpacing.xxl),
        ],

        ShowDetailsLibraryAction(tmdbId: details.tmdbId),

        if (details.genres.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.xxl),
          _Genres(genres: details.genres),
        ],

        const SizedBox(height: AppSpacing.xxxl),

        _Overview(overview: details.overview),
      ],
    );
  }

  bool get _hasTagline {
    return details.tagline?.trim().isNotEmpty ?? false;
  }
}

class _ShowHero extends StatelessWidget {
  const _ShowHero({required this.details, required this.isDesktop});

  final ShowDetails details;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final double topSafeArea = MediaQuery.paddingOf(context).top;
    final double heroHeight = isDesktop ? 440 : 380 + topSafeArea;

    return SizedBox(
      key: const ValueKey<String>('show-details-hero'),
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _BackdropImage(url: details.backdropUrl),

          _HeroBackdropOverlay(isDesktop: isDesktop),

          Positioned(
            top: topSafeArea + AppSpacing.lg,
            right: AppSpacing.lg,
            child: IconButton.filledTonal(
              key: const ValueKey<String>('show-details-close-button'),
              onPressed: context.pop,
              tooltip: 'Close',
              icon: const Icon(Icons.close_rounded),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: AppSpacing.xxl,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop
                        ? AppSpacing.extraHuge
                        : AppSpacing.xl,
                  ),
                  child: _HeroContent(details: details, isDesktop: isDesktop),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBackdropOverlay extends StatelessWidget {
  const _HeroBackdropOverlay({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: <double>[0, 0.38, 0.62, 0.82, 1],
              colors: <Color>[
                Color(0x10000000),
                Color(0x26000000),
                Color(0x66000000),
                Color(0xCC000000),
                AppColors.surface,
              ],
            ),
          ),
        ),

        if (isDesktop)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: <double>[0, 0.42, 0.75, 1],
                colors: <Color>[
                  Color(0x99000000),
                  Color(0x55000000),
                  Color(0x16000000),
                  Colors.transparent,
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _HeroContent extends StatelessWidget {
  const _HeroContent({required this.details, required this.isDesktop});

  final ShowDetails details;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final double posterWidth = isDesktop ? 154 : 108;

    return Row(
      key: const ValueKey<String>('show-details-hero-content'),
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        _PosterImage(url: details.posterUrl, width: posterWidth),

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
                  maxLines: isDesktop ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style:
                      (isDesktop
                              ? Theme.of(context).textTheme.headlineLarge
                              : Theme.of(context).textTheme.headlineMedium)
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.02,
                            letterSpacing: -0.4,
                          ),
                ),

                const SizedBox(height: AppSpacing.sm),

                _HeroSubtitle(details: details),

                if (details.voteAverage > 0) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  _RatingBadge(
                    rating: details.voteAverage,
                    voteCount: details.voteCount,
                    showVoteCount: isDesktop,
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
  const _RatingBadge({
    required this.rating,
    required this.voteCount,
    required this.showVoteCount,
  });

  final double rating;
  final int voteCount;
  final bool showVoteCount;

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
        if (showVoteCount && voteCount > 0) ...<Widget>[
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
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderFull,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          genre,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.overview});

  final String? overview;

  @override
  Widget build(BuildContext context) {
    final String resolvedOverview = _resolvedOverview();
    final bool hasOverview = overview?.trim().isNotEmpty ?? false;

    return _DetailsSection(
      title: 'Overview',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Text(
          resolvedOverview,
          key: const ValueKey<String>('show-details-overview'),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: hasOverview ? AppColors.textSecondary : AppColors.textMuted,
            height: 1.55,
            fontStyle: hasOverview ? FontStyle.normal : FontStyle.italic,
          ),
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
      _InfoItem(label: 'Aired', value: _dateRange()),
      if (details.status.trim().isNotEmpty)
        _InfoItem(label: 'Status', value: details.status),
      if (details.showType.trim().isNotEmpty)
        _InfoItem(label: 'Type', value: details.showType),
      _InfoItem(label: 'Seasons', value: details.numberOfSeasons.toString()),
      _InfoItem(label: 'Episodes', value: details.numberOfEpisodes.toString()),
      if (details.primaryEpisodeRunTime != null)
        _InfoItem(
          label: 'Runtime',
          value: '~${details.primaryEpisodeRunTime} min',
        ),
      if (details.originalLanguage.trim().isNotEmpty)
        _InfoItem(
          label: 'Language',
          value: details.originalLanguage.toUpperCase(),
        ),
    ];

    return _DetailsSection(
      title: 'Series Info',
      child: _InfoGrid(items: items),
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
    return Wrap(
      key: const ValueKey<String>('show-details-series-info'),
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.sm,
      children: items
          .map((_InfoItem item) {
            return _CompactInfoItem(item: item);
          })
          .toList(growable: false),
    );
  }
}

class _CompactInfoItem extends StatelessWidget {
  const _CompactInfoItem({required this.item});

  final _InfoItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          item.label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          item.value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

final class _InfoItem {
  const _InfoItem({required this.label, required this.value});

  final String label;
  final String value;
}

class _AdditionalInfo extends StatelessWidget {
  const _AdditionalInfo({required this.details});

  final ShowDetails details;

  @override
  Widget build(BuildContext context) {
    final String originalTitle = details.originalTitle.trim();

    final bool hasDistinctOriginalTitle =
        originalTitle.isNotEmpty && originalTitle != details.title.trim();

    return _DetailsSection(
      title: 'Additional Info',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (hasDistinctOriginalTitle)
            _AdditionalInfoItem(label: 'Original title', value: originalTitle),

          if (hasDistinctOriginalTitle && details.networks.isNotEmpty)
            const SizedBox(height: AppSpacing.xxl),

          if (details.networks.isNotEmpty)
            _Networks(networks: details.networks),
        ],
      ),
    );
  }
}

class _AdditionalInfoItem extends StatelessWidget {
  const _AdditionalInfoItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
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
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: AppRadius.borderFull,
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: Text(
                      network.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
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

    return ServerNetworkImage(
      imageUrl: imageUrl,
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

    return ServerNetworkImage(
      imageUrl: imageUrl,
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
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isDesktop = constraints.maxWidth >= AppBreakpoints.tablet;

        return SingleChildScrollView(
          key: const ValueKey<String>('show-details-loading'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _ShowDetailsHeroSkeleton(isDesktop: isDesktop),
              _ShowDetailsBodySkeleton(isDesktop: isDesktop),
            ],
          ),
        );
      },
    );
  }
}

class _ShowDetailsHeroSkeleton extends StatelessWidget {
  const _ShowDetailsHeroSkeleton({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final double heroHeight = isDesktop ? 420 : 360;

    return SizedBox(
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const ColoredBox(color: AppColors.surfaceLow),
          Positioned(
            left: isDesktop ? AppSpacing.extraHuge : AppSpacing.xl,
            right: isDesktop ? AppSpacing.extraHuge : AppSpacing.xl,
            bottom: AppSpacing.xxl,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                _SkeletonBlock(
                  width: isDesktop ? 150 : 112,
                  height: isDesktop ? 225 : 168,
                  borderRadius: AppRadius.borderLarge,
                ),
                SizedBox(width: isDesktop ? AppSpacing.xxxl : AppSpacing.lg),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const _SkeletonBlock(width: 260, height: 28),
                        const SizedBox(height: AppSpacing.md),
                        const _SkeletonBlock(width: 180, height: 16),
                        const SizedBox(height: AppSpacing.md),
                        const _SkeletonBlock(
                          width: 120,
                          height: 30,
                          borderRadius: AppRadius.borderFull,
                        ),
                      ],
                    ),
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

class _ShowDetailsBodySkeleton extends StatelessWidget {
  const _ShowDetailsBodySkeleton({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Padding(
          padding: EdgeInsets.only(
            left: isDesktop ? AppSpacing.xxxl : AppSpacing.xl,
            right: isDesktop ? AppSpacing.xxxl : AppSpacing.xl,
            top: AppSpacing.xxl,
            bottom: AppSpacing.section,
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _SkeletonBlock(width: 180, height: 18),
              SizedBox(height: AppSpacing.xxl),
              _SkeletonBlock(
                width: 150,
                height: 40,
                borderRadius: AppRadius.borderFull,
              ),
              SizedBox(height: AppSpacing.xxl),
              _SkeletonBlock(
                width: 250,
                height: 30,
                borderRadius: AppRadius.borderFull,
              ),
              SizedBox(height: AppSpacing.xxxl),
              _SkeletonBlock(width: 110, height: 24),
              SizedBox(height: AppSpacing.lg),
              _SkeletonBlock(width: double.infinity, height: 16),
              SizedBox(height: AppSpacing.sm),
              _SkeletonBlock(width: double.infinity, height: 16),
              SizedBox(height: AppSpacing.sm),
              _SkeletonBlock(width: 320, height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({
    required this.width,
    required this.height,
    this.borderRadius = AppRadius.borderMedium,
  });

  final double width;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: borderRadius,
      ),
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
