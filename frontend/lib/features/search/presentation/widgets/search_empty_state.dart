import 'package:flutter/material.dart';
import 'package:sofawatch/app/theme/tokens/app_spacing.dart';

class SearchEmptyState extends StatelessWidget {
  const SearchEmptyState({required this.query, super.key});

  final String query;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Center(
      key: const ValueKey<String>('search-empty-state'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.search_off_rounded,
              size: 40,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No results for "$query"',
              key: const ValueKey<String>('search-empty-title'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Try another title or change the selected filter.',
              key: const ValueKey<String>('search-empty-message'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
