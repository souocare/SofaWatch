import 'package:flutter/material.dart';
import 'package:sofawatch/app/theme/tokens/app_radius.dart';
import 'package:sofawatch/app/theme/tokens/app_spacing.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_item.dart';
import 'package:sofawatch/features/library/application/cubit/library_item_operation.dart';

class ExploreMediaCard extends StatelessWidget {
  const ExploreMediaCard({
    required this.item,
    required this.operation,
    this.onAdd,
    super.key,
  });

  final ExploreMediaItem item;
  final LibraryItemOperation operation;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final bool isAdded = item.inLibrary || operation.isAdded;

    final bool isAdding = operation.isAdding;

    return SizedBox(
      key: ValueKey<String>(
        'explore-media-'
        '${item.mediaType.name}-${item.tmdbId}',
      ),
      width: 132,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Poster(
            item: item,
            isAdded: isAdded,
            isAdding: isAdding,
            onAdd: onAdd,
          ),
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
  const _Poster({
    required this.item,
    required this.isAdded,
    required this.isAdding,
    required this.onAdd,
  });

  final ExploreMediaItem item;
  final bool isAdded;
  final bool isAdding;
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
              child: _LibraryButton(
                item: item,
                isAdded: isAdded,
                isAdding: isAdding,
                onPressed: onAdd,
              ),
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

class _LibraryButton extends StatelessWidget {
  const _LibraryButton({
    required this.item,
    required this.isAdded,
    required this.isAdding,
    required this.onPressed,
  });

  final ExploreMediaItem item;
  final bool isAdded;
  final bool isAdding;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    final String tooltip = _tooltip;

    final String semanticLabel = _semanticLabel;

    final bool isInteractive = !isAdded && !isAdding && onPressed != null;

    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: isInteractive,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: colors.surface.withValues(alpha: 0.88),
          shape: const CircleBorder(),
          elevation: 2,
          child: InkWell(
            key: ValueKey<String>(
              'explore-media-library-action-'
              '${item.mediaType.name}-${item.tmdbId}',
            ),
            customBorder: const CircleBorder(),
            onTap: isInteractive ? onPressed : null,
            child: SizedBox(
              width: 34,
              height: 34,
              child: Center(child: _buildIndicator(context)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    if (isAdding) {
      return SizedBox(
        key: ValueKey<String>(
          'explore-media-library-loading-'
          '${item.mediaType.name}-${item.tmdbId}',
        ),
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colors.onSurface,
        ),
      );
    }

    if (isAdded) {
      return Icon(
        Icons.check_rounded,
        key: ValueKey<String>(
          'explore-media-library-added-'
          '${item.mediaType.name}-${item.tmdbId}',
        ),
        size: 22,
        color: colors.onSurface,
      );
    }

    return Icon(
      Icons.add_rounded,
      key: ValueKey<String>(
        'explore-media-library-add-'
        '${item.mediaType.name}-${item.tmdbId}',
      ),
      size: 22,
      color: colors.onSurface,
    );
  }

  String get _tooltip {
    if (isAdding) {
      return item.isShow ? 'Adding to Library' : 'Adding to Watchlist';
    }

    if (isAdded) {
      return item.isShow ? 'Already in Library' : 'Already in Watchlist';
    }

    return item.isShow ? 'Add to Library' : 'Add to Watchlist';
  }

  String get _semanticLabel {
    if (isAdding) {
      return item.isShow
          ? 'Adding ${item.title} to Library'
          : 'Adding ${item.title} to Watchlist';
    }

    if (isAdded) {
      return item.isShow
          ? '${item.title} is in Library'
          : '${item.title} is in Watchlist';
    }

    return item.isShow
        ? 'Add ${item.title} to Library'
        : 'Add ${item.title} to Watchlist';
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
      softWrap: false,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        height: 1.15,
      ),
    );
  }
}

class _Metadata extends StatelessWidget {
  const _Metadata({required this.item});

  final ExploreMediaItem item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final Color metadataColor = theme.colorScheme.onSurfaceVariant;

    final TextStyle? textStyle = theme.textTheme.bodySmall?.copyWith(
      color: metadataColor,
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
          color: metadataColor,
        ),
        if (item.releaseYear != null) ...<Widget>[
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              item.releaseYear.toString(),
              key: ValueKey<String>(
                'explore-media-year-'
                '${item.mediaType.name}-${item.tmdbId}',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
        ],
        const Spacer(),
        Icon(Icons.star_rounded, size: 14, color: metadataColor),
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
