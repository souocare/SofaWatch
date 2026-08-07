import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_cubit.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_state.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details.dart';

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
    return SingleChildScrollView(
      key: const ValueKey<String>('show-details-content'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _ShowHero(details: details),
          Padding(
            padding: AppSpacing.cardPaddingLarge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (details.tagline?.isNotEmpty ?? false) ...<Widget>[
                  Text(
                    details.tagline!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
                _Metadata(details: details),
                if (details.genres.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.xl),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: details.genres
                        .map(
                          (String genre) => _GenreChip(
                            key: ValueKey<String>('show-details-genre-$genre'),
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
                  key: const ValueKey<String>('show-details-overview'),
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

  String _overview(ShowDetails details) {
    final String? overview = details.overview?.trim();

    if (overview == null || overview.isEmpty) {
      return 'No overview is available for this series.';
    }

    return overview;
  }
}

class _ShowHero extends StatelessWidget {
  const _ShowHero({required this.details});

  final ShowDetails details;

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
              key: const ValueKey<String>('show-details-close-button'),
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
                        key: const ValueKey<String>('show-details-title'),
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

  String _subtitle(ShowDetails details) {
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

class _Metadata extends StatelessWidget {
  const _Metadata({required this.details});

  final ShowDetails details;

  @override
  Widget build(BuildContext context) {
    final List<String> values = <String>[
      '${details.numberOfSeasons} ${details.numberOfSeasons == 1 ? 'season' : 'seasons'}',
      '${details.numberOfEpisodes} episodes',
      if (details.voteAverage > 0)
        '★ ${details.voteAverage.toStringAsFixed(1)}',
    ];

    return Text(
      values.join(' • '),
      key: const ValueKey<String>('show-details-metadata'),
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
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
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
