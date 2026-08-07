import 'package:flutter/material.dart';
import 'package:sofawatch/app/theme/tokens/app_radius.dart';
import 'package:sofawatch/app/theme/tokens/app_spacing.dart';
import 'package:sofawatch/features/search/domain/entities/search_result.dart';

class SearchResultRow extends StatelessWidget {
  const SearchResultRow({
    required this.result,
    required this.onPressed,
    this.onActionPressed,
    this.compact = false,
    super.key,
  });

  final SearchResult result;
  final VoidCallback onPressed;

  /// A operação real de Watchlist/Biblioteca será implementada no ponto 13.14.
  final VoidCallback? onActionPressed;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final double thumbnailWidth = compact ? 52 : 60;
    final double thumbnailHeight = compact ? 76 : 88;

    return Semantics(
      button: true,
      label: 'Open ${result.title}',
      child: Material(
        key: ValueKey<String>(
          'search-result-${result.mediaType.name}-${result.tmdbId}',
        ),
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: AppRadius.borderMedium,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? AppSpacing.sm : AppSpacing.md,
              vertical: compact ? AppSpacing.sm : AppSpacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _SearchResultThumbnail(
                  result: result,
                  width: thumbnailWidth,
                  height: thumbnailHeight,
                ),
                SizedBox(width: compact ? AppSpacing.md : AppSpacing.lg),
                Expanded(
                  child: _SearchResultInformation(
                    result: result,
                    compact: compact,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _SearchResultAction(
                  result: result,
                  onPressed: onActionPressed,
                  compact: compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchResultThumbnail extends StatelessWidget {
  const _SearchResultThumbnail({
    required this.result,
    required this.width,
    required this.height,
  });

  final SearchResult result;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      key: ValueKey<String>(
        'search-result-thumbnail-${result.mediaType.name}-${result.tmdbId}',
      ),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.borderSmall,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Icon(
        result.isShow ? Icons.tv_outlined : Icons.movie_outlined,
        color: colorScheme.onSurfaceVariant,
        size: 26,
      ),
    );
  }
}

class _SearchResultInformation extends StatelessWidget {
  const _SearchResultInformation({required this.result, required this.compact});

  final SearchResult result;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          result.title,
          key: ValueKey<String>(
            'search-result-title-${result.mediaType.name}-${result.tmdbId}',
          ),
          maxLines: compact ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          key: ValueKey<String>(
            'search-result-metadata-${result.mediaType.name}-${result.tmdbId}',
          ),
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              result.isShow ? 'Show' : 'Movie',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (result.releaseYear != null) ...<Widget>[
              const SizedBox(width: 8),
              Text(
                '•',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                result.releaseYear.toString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _SearchResultAction extends StatelessWidget {
  const _SearchResultAction({
    required this.result,
    required this.onPressed,
    required this.compact,
  });

  final SearchResult result;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final String tooltip = result.isShow
        ? 'Add show to library'
        : 'Add movie to Watchlist';

    return IconButton(
      key: ValueKey<String>(
        'search-result-action-${result.mediaType.name}-${result.tmdbId}',
      ),
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      icon: const Icon(Icons.add_rounded),
    );
  }
}
