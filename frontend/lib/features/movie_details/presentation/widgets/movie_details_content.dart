import 'package:flutter/material.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/features/movie_details/domain/models/movie_details.dart';
import 'package:sofawatch/features/movie_details/presentation/widgets/movie_details_hero.dart';
import 'package:sofawatch/features/movie_details/presentation/widgets/movie_details_library_action.dart';

class MovieDetailsContent extends StatelessWidget {
  const MovieDetailsContent({required this.details, super.key});

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
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isDesktop = constraints.maxWidth >= AppBreakpoints.tablet;
        final bool isUpcoming = _isUpcoming(details.releaseDate);

        return SingleChildScrollView(
          key: const ValueKey<String>('movie-details-content'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              MovieDetailsHero(details: details, isDesktop: isDesktop),

              Center(
                child: ConstrainedBox(
                  key: const ValueKey<String>('movie-details-body-container'),
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
                        MovieDetailsLibraryAction(
                          tmdbId: details.tmdbId,
                          movieId: details.id,
                          isUpcoming: isUpcoming,
                        ),

                        const SizedBox(height: AppSpacing.xxl),

                        if (details.tagline?.trim().isNotEmpty ??
                            false) ...<Widget>[
                          _Tagline(tagline: details.tagline!),

                          const SizedBox(height: AppSpacing.xxl),
                        ],

                        if (details.genres.isNotEmpty) ...<Widget>[
                          _Genres(genres: details.genres),

                          const SizedBox(height: AppSpacing.xxxl),
                        ],

                        _Overview(overview: details.overview),

                        const SizedBox(height: AppSpacing.section),

                        _MovieInfo(details: details),
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
}

class _Genres extends StatelessWidget {
  const _Genres({required this.genres});

  final List<String> genres;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const ValueKey<String>('movie-details-genres'),
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: genres
          .map(
            (String genre) => _GenreChip(
              key: ValueKey<String>('movie-details-genre-$genre'),
              genre: genre,
            ),
          )
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

class _Tagline extends StatelessWidget {
  const _Tagline({required this.tagline});

  final String tagline;

  @override
  Widget build(BuildContext context) {
    return Text(
      tagline,
      key: const ValueKey<String>('movie-details-tagline'),
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: AppColors.textSecondary,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.overview});

  final String? overview;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Overview',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),

        const SizedBox(height: AppSpacing.lg),

        Text(
          _resolvedOverview(),
          key: const ValueKey<String>('movie-details-overview'),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  String _resolvedOverview() {
    final String? value = overview?.trim();

    if (value == null || value.isEmpty) {
      return 'No overview is available for this movie.';
    }

    return value;
  }
}

class _MovieInfo extends StatelessWidget {
  const _MovieInfo({required this.details});

  final MovieDetails details;

  @override
  Widget build(BuildContext context) {
    final List<_InfoItem> items = <_InfoItem>[
      _InfoItem(
        key: const ValueKey<String>('movie-details-release-date'),
        icon: Icons.calendar_today_rounded,
        label: 'Release',
        value: _releaseDate(context),
      ),

      if (details.runtime != null && details.runtime! > 0)
        _InfoItem(
          key: const ValueKey<String>('movie-details-runtime'),
          icon: Icons.schedule_rounded,
          label: 'Runtime',
          value: _formatRuntime(details.runtime!),
        ),

      if (details.status.trim().isNotEmpty)
        _InfoItem(
          key: const ValueKey<String>('movie-details-status'),
          icon: Icons.info_outline_rounded,
          label: 'Status',
          value: details.status.trim(),
        ),

      if (_shouldShowOriginalTitle(details))
        _InfoItem(
          key: const ValueKey<String>('movie-details-original-title'),
          icon: Icons.title_rounded,
          label: 'Original title',
          value: details.originalTitle.trim(),
        ),
      if (details.originalLanguage.trim().isNotEmpty)
        _InfoItem(
          key: const ValueKey<String>('movie-details-original-language'),
          icon: Icons.language_rounded,
          label: 'Language',
          value: details.originalLanguage.trim().toUpperCase(),
        ),
    ];

    return _DetailsSection(
      title: 'Movie Info',
      child: _InfoGrid(items: items),
    );
  }

  String _releaseDate(BuildContext context) {
    final DateTime? releaseDate = details.releaseDate;

    if (releaseDate == null) {
      return 'Unknown';
    }

    return MaterialLocalizations.of(context).formatMediumDate(releaseDate);
  }

  bool _shouldShowOriginalTitle(MovieDetails details) {
    final String originalTitle = details.originalTitle.trim();
    final String title = details.title.trim();

    return originalTitle.isNotEmpty && originalTitle != title;
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
                .map((_InfoItem item) => _InfoRow(item: item))
                .toList(growable: false),
          );
        }

        return Wrap(
          spacing: AppSpacing.xxl,
          runSpacing: AppSpacing.sm,
          children: items
              .map(
                (_InfoItem item) => SizedBox(
                  width: (constraints.maxWidth - AppSpacing.xxl) / 2,
                  child: _InfoRow(item: item),
                ),
              )
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
      key: item.key,
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
    this.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final Key? key;
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
