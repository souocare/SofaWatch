import 'package:flutter/material.dart';

class SearchMinimumCharactersHint extends StatelessWidget {
  const SearchMinimumCharactersHint({
    required this.remainingCharacters,
    super.key,
  });

  final int remainingCharacters;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final String message = remainingCharacters == 1
        ? 'Type 1 more character to search.'
        : 'Type $remainingCharacters more characters to search.';

    return Center(
      child: Text(
        message,
        key: const ValueKey<String>('search-minimum-characters-hint'),
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}
