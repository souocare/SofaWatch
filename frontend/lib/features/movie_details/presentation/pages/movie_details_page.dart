import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/features/movie_details/application/cubit/movie_details_cubit.dart';
import 'package:sofawatch/features/movie_details/application/cubit/movie_details_state.dart';
import 'package:sofawatch/features/movie_details/domain/models/movie_details.dart';

class MovieDetailsPage extends StatelessWidget {
  const MovieDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: BlocBuilder<MovieDetailsCubit, MovieDetailsState>(
          builder: (BuildContext context, MovieDetailsState state) {
            return switch (state) {
              MovieDetailsInitial() ||
              MovieDetailsLoading() => const _MovieDetailsLoading(),
              MovieDetailsSuccess(:final details) => _MovieDetailsContent(
                details: details,
              ),
              MovieDetailsFailure(:final error) => _MovieDetailsFailure(
                isTimeout: error.isTimeout,
                onRetry: context.read<MovieDetailsCubit>().retry,
              ),
            };
          },
        ),
      ),
    );
  }
}

class _MovieDetailsContent extends StatelessWidget {
  const _MovieDetailsContent({required this.details});

  final MovieDetails details;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey<String>('movie-details-content'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _MovieHero(details: details),
          Padding(
            padding: AppSpacing.cardPaddingLarge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (details.tagline?.trim().isNotEmpty ?? false) ...<Widget>[
                  Text(
                    details.tagline!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
                _MovieMetadata(details: details),
                if (details.genres.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.xl),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: details.genres
                        .map(
                          (String genre) => _GenreChip(
                            key: ValueKey<String>('movie-details-genre-$genre'),
                            genre: genre,
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
                const SizedBox(height: AppSpacing.xxxl),
                Text('Overview', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _overview(details),
                  key: const ValueKey<String>('movie-details-overview'),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _overview(MovieDetails details) {
    final String? overview = details.overview?.trim();

    if (overview == null || overview.isEmpty) {
      return 'No overview is available for this movie.';
    }

    return overview;
  }
}

class _MovieHero extends StatelessWidget {
  const _MovieHero({required this.details});

  final MovieDetails details;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 340,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _BackdropImage(url: details.backdropUrl),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Colors.transparent, AppColors.surface],
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.lg,
            right: AppSpacing.lg,
            child: IconButton.filledTonal(
              key: const ValueKey<String>('movie-details-close-button'),
              onPressed: context.pop,
              icon: const Icon(Icons.close),
              tooltip: 'Close',
            ),
          ),
          Positioned(
            left: AppSpacing.xxl,
            right: AppSpacing.xxl,
            bottom: AppSpacing.xxl,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                _PosterImage(url: details.posterUrl),
                const SizedBox(width: AppSpacing.xxl),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        details.title,
                        key: const ValueKey<String>('movie-details-title'),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _subtitle(details),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _subtitle(MovieDetails details) {
    final List<String> parts = <String>[
      if (details.releaseYear != null) details.releaseYear.toString(),
      if (details.status.trim().isNotEmpty) details.status,
    ];

    return parts.join(' • ');
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
      key: const ValueKey<String>('movie-details-backdrop'),
      fit: BoxFit.cover,
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
            return const ColoredBox(color: AppColors.surfaceLow);
          },
    );
  }
}

class _PosterImage extends StatelessWidget {
  const _PosterImage({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.borderLarge,
      child: SizedBox(
        width: 120,
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

class _MovieMetadata extends StatelessWidget {
  const _MovieMetadata({required this.details});

  final MovieDetails details;

  @override
  Widget build(BuildContext context) {
    final List<String> values = <String>[
      if (details.runtime != null && details.runtime! > 0)
        _formatRuntime(details.runtime!),
      if (details.voteAverage > 0)
        '★ ${details.voteAverage.toStringAsFixed(1)}',
    ];

    if (values.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      values.join(' • '),
      key: const ValueKey<String>('movie-details-metadata'),
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
    );
  }

  String _formatRuntime(int minutes) {
    final int hours = minutes ~/ 60;
    final int remainingMinutes = minutes % 60;

    if (hours == 0) {
      return '${remainingMinutes}m';
    }

    if (remainingMinutes == 0) {
      return '${hours}h';
    }

    return '${hours}h ${remainingMinutes}m';
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

class _MovieDetailsLoading extends StatelessWidget {
  const _MovieDetailsLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: ValueKey<String>('movie-details-loading'),
      child: CircularProgressIndicator(),
    );
  }
}

class _MovieDetailsFailure extends StatelessWidget {
  const _MovieDetailsFailure({required this.isTimeout, required this.onRetry});

  final bool isTimeout;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey<String>('movie-details-failure'),
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
                  ? 'Loading the movie took too long'
                  : 'Could not load this movie',
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
              key: const ValueKey<String>('movie-details-retry'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
