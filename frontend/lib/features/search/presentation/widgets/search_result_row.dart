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
    this.actionLoading = false,
    this.actionAdded = false,
    super.key,
  });

  final SearchResult result;
  final VoidCallback onPressed;

  /// A operação real de Watchlist/Biblioteca será implementada no ponto 13.14.
  final VoidCallback? onActionPressed;

  /// Mobile usa uma apresentação mais compacta.
  final bool compact;

  final bool actionAdded;

  /// Permite mostrar feedback visual enquanto a ação lateral está em curso.
  ///
  /// A lógica real que controla este estado será ligada no ponto 13.14.
  final bool actionLoading;

  @override
  Widget build(BuildContext context) {
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
    required this.isLoading,
    required this.isAdded,
  });

  final SearchResult result;
  final VoidCallback? onPressed;
  final bool compact;
  final bool isLoading;
  final bool isAdded;

  String get _label {
    return result.isShow ? 'Add to Library' : 'Add to Watchlist';
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final VoidCallback? effectiveOnPressed = isLoading ? null : onPressed;

    final Key key = ValueKey<String>(
      'search-result-action-${result.mediaType.name}-${result.tmdbId}',
    );

    if (compact) {
      return IconButton(
        key: key,
        tooltip: isAdded ? 'Added' : _label,
        onPressed: effectiveOnPressed,
        visualDensity: VisualDensity.compact,
        icon: isLoading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                isAdded ? Icons.check_rounded : Icons.add_rounded,
                color: isAdded ? Colors.green : colorScheme.onSurface,
              ),
      );
    }

    return TextButton.icon(
      key: key,
      onPressed: effectiveOnPressed,
      icon: isLoading
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              isAdded ? Icons.check_rounded : Icons.add_rounded,
              color: isAdded ? Colors.green : null,
            ),
      label: Text(
        isAdded ? 'Added' : _label,
        style: isAdded ? const TextStyle(color: Colors.green) : null,
      ),
    );
  }
}
