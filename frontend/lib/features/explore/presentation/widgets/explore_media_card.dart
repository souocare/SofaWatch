import 'package:flutter/material.dart';
import 'package:sofawatch/app/theme/tokens/app_radius.dart';
import 'package:sofawatch/app/theme/tokens/app_spacing.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_item.dart';

class ExploreMediaCard extends StatelessWidget {
  const ExploreMediaCard({required this.item, this.onAdd, super.key});

  final ExploreMediaItem item;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey<String>(
        'explore-media-'
        '${item.mediaType.name}-${item.tmdbId}',
      ),
      width: 132,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Poster(item: item, onAdd: onAdd),
          const SizedBox(height: AppSpacing.sm),
          _Title(item: item),
          const SizedBox(height: AppSpacing.xs),
          _Metadata(item: item),
        ],
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.item, required this.onAdd});

  final ExploreMediaItem item;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2 / 3,
      child: ClipRRect(
        borderRadius: AppRadius.borderLarge,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            _PosterContent(item: item),
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: _AddButton(item: item, onPressed: onAdd),
            ),
          ],
        ),
      ),
    );
  }
}

class _PosterContent extends StatelessWidget {
  const _PosterContent({required this.item});

  final ExploreMediaItem item;

  @override
  Widget build(BuildContext context) {
    final Uri? posterUrl = item.posterUrl;

    if (posterUrl == null) {
      return _Placeholder(item: item);
    }

    return Image.network(
      posterUrl.toString(),
      key: ValueKey<String>(
        'explore-media-poster-'
        '${item.mediaType.name}-${item.tmdbId}',
      ),
      fit: BoxFit.cover,
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
            return _Placeholder(item: item);
          },
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.item, required this.onPressed});

  final ExploreMediaItem item;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: item.isShow
          ? 'Add ${item.title} to Library'
          : 'Add ${item.title} to Watchlist',
      child: Material(
        color: colors.surface.withValues(alpha: 0.88),
        shape: const CircleBorder(),
        elevation: 2,
        child: InkWell(
          key: ValueKey<String>(
            'explore-media-add-'
            '${item.mediaType.name}-${item.tmdbId}',
          ),
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              Icons.add_rounded,
              size: 22,
              color: onPressed != null
                  ? colors.onSurface
                  : colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.item});

  final ExploreMediaItem item;

  @override
  Widget build(BuildContext context) {
    return Text(
      item.title,
      key: ValueKey<String>(
        'explore-media-title-'
        '${item.mediaType.name}-${item.tmdbId}',
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _Metadata extends StatelessWidget {
  const _Metadata({required this.item});

  final ExploreMediaItem item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final TextStyle? textStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Row(
      children: <Widget>[
        Icon(
          item.isShow ? Icons.tv_rounded : Icons.movie_rounded,
          key: ValueKey<String>(
            'explore-media-type-'
            '${item.mediaType.name}-${item.tmdbId}',
          ),
          size: 13,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        if (item.releaseYear != null) ...<Widget>[
          const SizedBox(width: AppSpacing.xs),
          Text(
            item.releaseYear.toString(),
            key: ValueKey<String>(
              'explore-media-year-'
              '${item.mediaType.name}-${item.tmdbId}',
            ),
            style: textStyle,
          ),
        ],
        const Spacer(),
        Icon(
          Icons.star_rounded,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 2),
        Text(
          item.voteAverage.toStringAsFixed(1),
          key: ValueKey<String>(
            'explore-media-rating-'
            '${item.mediaType.name}-${item.tmdbId}',
          ),
          style: textStyle,
        ),
      ],
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.item});

  final ExploreMediaItem item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: ValueKey<String>(
        'explore-media-placeholder-'
        '${item.mediaType.name}-${item.tmdbId}',
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Center(
        child: Icon(
          item.isShow ? Icons.tv_outlined : Icons.movie_outlined,
          size: 32,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
