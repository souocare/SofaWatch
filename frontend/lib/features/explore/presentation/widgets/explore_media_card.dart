import 'package:flutter/material.dart';
import 'package:sofawatch/app/theme/tokens/app_radius.dart';
import 'package:sofawatch/app/theme/tokens/app_spacing.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_item.dart';

class ExploreMediaCard extends StatelessWidget {
  const ExploreMediaCard({required this.item, super.key});

  final ExploreMediaItem item;

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
          _Poster(item: item),
          const SizedBox(height: AppSpacing.sm),
          Text(
            item.title,
            key: ValueKey<String>(
              'explore-media-title-'
              '${item.mediaType.name}-${item.tmdbId}',
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (item.releaseYear != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              item.releaseYear.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.item});

  final ExploreMediaItem item;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2 / 3,
      child: ClipRRect(
        borderRadius: AppRadius.borderLarge,
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final Uri? posterUrl = item.posterUrl;

    if (posterUrl == null) {
      return _Placeholder(item: item);
    }

    return Image.network(
      posterUrl.toString(),
      fit: BoxFit.cover,
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
            return _Placeholder(item: item);
          },
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.item});

  final ExploreMediaItem item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Center(
        child: Icon(
          item.isShow ? Icons.tv_outlined : Icons.movie_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
