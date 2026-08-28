import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/core/widgets/server_network_image.dart';
import 'package:sofawatch/features/movie_details/domain/models/movie_details.dart';

class MovieDetailsHero extends StatelessWidget {
  const MovieDetailsHero({
    required this.details,
    required this.isDesktop,
    super.key,
  });

  final MovieDetails details;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final double heroHeight = isDesktop ? 420 : 360;

    return SizedBox(
      key: const ValueKey<String>('movie-details-hero'),
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
              key: const ValueKey<String>('movie-details-close-button'),
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

  final MovieDetails details;
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
                  key: const ValueKey<String>('movie-details-title'),
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

  final MovieDetails details;

  bool _isUpcoming(DateTime? releaseDate) {
    if (releaseDate == null) {
      return false;
    }

    final DateTime today = DateUtils.dateOnly(DateTime.now());
    final DateTime releaseDay = DateUtils.dateOnly(releaseDate);

    return releaseDay.isAfter(today);
  }

  @override
  Widget build(BuildContext context) {
    final bool isUpcoming = _isUpcoming(details.releaseDate);

    final List<String> values = <String>[
      if (details.releaseYear != null) details.releaseYear.toString(),
      if (isUpcoming)
        'Upcoming'
      else if (details.status.trim().isNotEmpty)
        details.status,
    ];

    return Text(
      values.join(' • '),
      key: const ValueKey<String>('movie-details-subtitle'),
      style: Theme.of(
        context,
      ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating, required this.voteCount});

  final double rating;
  final int voteCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey<String>('movie-details-rating'),
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(Icons.star_rounded, size: 19),
        const SizedBox(width: AppSpacing.xs),
        Text(
          rating.toStringAsFixed(1),
          key: const ValueKey<String>('movie-details-rating-value'),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (voteCount > 0) ...<Widget>[
          const SizedBox(width: AppSpacing.sm),
          Text(
            '${_formatCount(voteCount)} votes',
            key: const ValueKey<String>('movie-details-vote-count'),
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

class _BackdropImage extends StatelessWidget {
  const _BackdropImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = url?.trim();

    if (imageUrl == null || imageUrl.isEmpty) {
      return const ColoredBox(
        key: ValueKey<String>('movie-details-backdrop-placeholder'),
        color: AppColors.surfaceLow,
      );
    }

    return ServerNetworkImage(
      imageUrl: imageUrl,
      key: const ValueKey<String>('movie-details-backdrop'),
      fit: BoxFit.cover,
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
            return const ColoredBox(
              key: ValueKey<String>('movie-details-backdrop-placeholder'),
              color: AppColors.surfaceLow,
            );
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
        key: const ValueKey<String>('movie-details-poster-container'),
        width: width,
        child: AspectRatio(aspectRatio: 2 / 3, child: _buildImage()),
      ),
    );
  }

  Widget _buildImage() {
    final String? imageUrl = url?.trim();

    if (imageUrl == null || imageUrl.isEmpty) {
      return const _PosterPlaceholder();
    }

    return ServerNetworkImage(
      imageUrl: imageUrl,
      key: const ValueKey<String>('movie-details-poster'),
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
      key: ValueKey<String>('movie-details-poster-placeholder'),
      color: AppColors.surfaceHigh,
      child: Center(
        child: Icon(Icons.movie_rounded, color: AppColors.textMuted),
      ),
    );
  }
}
