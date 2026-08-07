import 'package:flutter/material.dart';
import 'package:sofawatch/app/theme/tokens/app_spacing.dart';
import 'package:sofawatch/core/errors/app_exception.dart';

class SearchFailureState extends StatelessWidget {
  const SearchFailureState({
    required this.error,
    required this.onRetry,
    super.key,
  });

  final AppException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final _SearchFailurePresentation presentation =
        _SearchFailurePresentation.fromException(error);

    return Center(
      key: const ValueKey<String>('search-failure-state'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              presentation.icon,
              size: 40,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              presentation.title,
              key: const ValueKey<String>('search-failure-title'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              presentation.message,
              key: const ValueKey<String>('search-failure-message'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.tonalIcon(
              key: const ValueKey<String>('search-failure-retry'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchFailurePresentation {
  const _SearchFailurePresentation({
    required this.title,
    required this.message,
    required this.icon,
  });

  factory _SearchFailurePresentation.fromException(AppException error) {
    if (error.isTimeout) {
      return const _SearchFailurePresentation(
        title: 'Search took too long',
        message: 'The server did not respond in time. Please try again.',
        icon: Icons.schedule_rounded,
      );
    }

    if (error.type == AppExceptionType.connection) {
      return const _SearchFailurePresentation(
        title: 'Could not connect',
        message: 'Check your connection to the SofaWatch server and try again.',
        icon: Icons.wifi_off_rounded,
      );
    }

    return switch (error.code) {
      'tmdb_unavailable' => const _SearchFailurePresentation(
        title: 'Search is temporarily unavailable',
        message:
            'The movie and TV information service is not responding right now.',
        icon: Icons.cloud_off_rounded,
      ),
      'tmdb_not_configured' => const _SearchFailurePresentation(
        title: 'Search is not available',
        message: 'The search provider has not been configured on this server.',
        icon: Icons.settings_outlined,
      ),
      'tmdb_invalid_response' => const _SearchFailurePresentation(
        title: 'Something went wrong',
        message: 'We could not process the search results. Please try again.',
        icon: Icons.error_outline_rounded,
      ),
      _ => switch (error.type) {
        AppExceptionType.invalidData => const _SearchFailurePresentation(
          title: 'Something went wrong',
          message: 'We could not process the search results. Please try again.',
          icon: Icons.error_outline_rounded,
        ),
        AppExceptionType.server => const _SearchFailurePresentation(
          title: 'Search is unavailable',
          message:
              'The server could not complete the search. Please try again.',
          icon: Icons.cloud_off_rounded,
        ),
        _ => const _SearchFailurePresentation(
          title: 'Something went wrong',
          message: 'We could not complete the search. Please try again.',
          icon: Icons.error_outline_rounded,
        ),
      },
    };
  }

  final String title;
  final String message;
  final IconData icon;
}
