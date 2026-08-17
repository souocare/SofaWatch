import 'package:flutter/material.dart';
import 'package:sofawatch/app/theme/tokens/app_colors.dart';
import 'package:sofawatch/app/theme/tokens/app_radius.dart';
import 'package:sofawatch/app/theme/tokens/app_spacing.dart';
import 'package:sofawatch/features/search/domain/entities/search_result.dart';

class SearchResultRow extends StatelessWidget {
  const SearchResultRow({
    required this.result,
    required this.onPressed,
    this.onActionPressed,
    this.compact = false,
    this.actionLoading = false,
    this.actionAdded = false,
    super.key,
  });

  final SearchResult result;
  final VoidCallback onPressed;

  final VoidCallback? onActionPressed;

  /// Mobile usa uma apresentação mais compacta.
  final bool compact;

  final bool actionAdded;

  /// Permite mostrar feedback visual enquanto a ação lateral está em curso.
  final bool actionLoading;

  @override
  Widget build(BuildContext context) {
    final double thumbnailWidth = compact ? 52 : 60;
    final double thumbnailHeight = thumbnailWidth * 1.5;

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
                  isLoading: actionLoading,
                  isAdded: actionAdded,
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
    return SizedBox(
      key: ValueKey<String>(
        'search-result-thumbnail-${result.mediaType.name}-${result.tmdbId}',
      ),
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: AppRadius.borderSmall,
        child: AspectRatio(
          aspectRatio: 2 / 3,
          child: _buildThumbnailContent(context),
        ),
      ),
    );
  }

  Widget _buildThumbnailContent(BuildContext context) {
    final Uri? posterUrl = result.posterUrl;

    if (posterUrl == null) {
      return _SearchResultPosterPlaceholder(result: result);
    }

    return Image.network(
      posterUrl.toString(),
      key: ValueKey<String>(
        'search-result-poster-${result.mediaType.name}-${result.tmdbId}',
      ),
      fit: BoxFit.cover,
      frameBuilder:
          (
            BuildContext context,
            Widget child,
            int? frame,
            bool wasSynchronouslyLoaded,
          ) {
            if (wasSynchronouslyLoaded || frame != null) {
              return child;
            }

            return _SearchResultPosterPlaceholder(
              result: result,
              showLoadingIndicator: true,
            );
          },
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
            return _SearchResultPosterPlaceholder(result: result);
          },
    );
  }
}

class _SearchResultPosterPlaceholder extends StatelessWidget {
  const _SearchResultPosterPlaceholder({
    required this.result,
    this.showLoadingIndicator = false,
  });

  final SearchResult result;
  final bool showLoadingIndicator;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      key: ValueKey<String>(
        'search-result-poster-placeholder-'
        '${result.mediaType.name}-${result.tmdbId}',
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Center(
        child: showLoadingIndicator
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                result.isShow ? Icons.tv_outlined : Icons.movie_outlined,
                color: colorScheme.onSurfaceVariant,
                size: 26,
              ),
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
    required this.isLoading,
    required this.isAdded,
  });

  final SearchResult result;
  final VoidCallback? onPressed;
  final bool compact;
  final bool isLoading;
  final bool isAdded;

  String get _addLabel {
    return result.isShow ? 'Add to Library' : 'Add to Watchlist';
  }

  String get _tooltip {
    if (isLoading) {
      return result.isShow ? 'Adding to Library' : 'Adding to Watchlist';
    }

    if (isAdded) {
      return result.isShow ? 'Added to Library' : 'Added to Watchlist';
    }

    return _addLabel;
  }

  String get _semanticsLabel {
    if (isLoading) {
      return result.isShow
          ? 'Adding ${result.title} to Library'
          : 'Adding ${result.title} to Watchlist';
    }

    if (isAdded) {
      return result.isShow
          ? '${result.title} is in Library'
          : '${result.title} is in Watchlist';
    }

    return result.isShow
        ? 'Add ${result.title} to Library'
        : 'Add ${result.title} to Watchlist';
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final VoidCallback? effectiveOnPressed = isLoading || isAdded
        ? null
        : onPressed;

    final Key key = ValueKey<String>(
      'search-result-action-'
      '${result.mediaType.name}-${result.tmdbId}',
    );

    return Semantics(
      container: true,
      explicitChildNodes: false,
      label: _semanticsLabel,
      button: true,
      enabled: effectiveOnPressed != null,
      child: ExcludeSemantics(
        child: Tooltip(
          message: _tooltip,
          child: compact
              ? _buildCompactAction(
                  key: key,
                  colorScheme: colorScheme,
                  onPressed: effectiveOnPressed,
                )
              : _buildDesktopAction(key: key, onPressed: effectiveOnPressed),
        ),
      ),
    );
  }

  Widget _buildCompactAction({
    required Key key,
    required ColorScheme colorScheme,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      key: key,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      icon: _buildIcon(size: 20, defaultColor: colorScheme.onSurface),
    );
  }

  Widget _buildDesktopAction({
    required Key key,
    required VoidCallback? onPressed,
  }) {
    return TextButton.icon(
      key: key,
      onPressed: onPressed,
      icon: _buildIcon(size: 18),
      label: Text(
        isAdded ? 'Added' : _addLabel,
        style: isAdded ? const TextStyle(color: AppColors.success) : null,
      ),
    );
  }

  Widget _buildIcon({required double size, Color? defaultColor}) {
    if (isLoading) {
      return SizedBox.square(
        key: ValueKey<String>(
          'search-result-action-loading-'
          '${result.mediaType.name}-${result.tmdbId}',
        ),
        dimension: size,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Icon(
      isAdded ? Icons.check_rounded : Icons.add_rounded,
      key: ValueKey<String>(
        isAdded
            ? 'search-result-action-added-'
                  '${result.mediaType.name}-${result.tmdbId}'
            : 'search-result-action-add-'
                  '${result.mediaType.name}-${result.tmdbId}',
      ),
      color: isAdded ? AppColors.success : defaultColor,
    );
  }
}
