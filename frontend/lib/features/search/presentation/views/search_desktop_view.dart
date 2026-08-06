import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/route_paths.dart';
import 'package:sofawatch/app/theme/tokens/app_spacing.dart';
import 'package:sofawatch/features/search/presentation/widgets/search_text_field.dart';

class SearchDesktopView extends StatelessWidget {
  const SearchDesktopView({super.key});

  static const double _maximumModalWidth = 780;
  static const double _maximumModalHeight = 720;
  static const double _minimumModalHeight = 420;

  static const double _minimumViewportMargin = AppSpacing.lg;

  void _closeSearch(BuildContext context) {
    final GoRouter router = GoRouter.of(context);

    if (router.canPop()) {
      router.pop();
      return;
    }

    router.go(RoutePaths.home);
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () {
          _closeSearch(context);
        },
      },
      child: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double availableWidth = math.max(
              0,
              constraints.maxWidth - (_minimumViewportMargin * 2),
            );

            final double availableHeight = math.max(
              0,
              constraints.maxHeight - (_minimumViewportMargin * 2),
            );

            final double modalWidth = math.min(
              _maximumModalWidth,
              availableWidth,
            );

            final double modalMaximumHeight = math.min(
              _maximumModalHeight,
              availableHeight,
            );

            final double modalMinimumHeight = math.min(
              _minimumModalHeight,
              modalMaximumHeight,
            );

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: modalWidth,
                  maxWidth: modalWidth,
                  minHeight: modalMinimumHeight,
                  maxHeight: modalMaximumHeight,
                ),
                child: _SearchDesktopModal(
                  onClose: () {
                    _closeSearch(context);
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SearchDesktopModal extends StatelessWidget {
  const _SearchDesktopModal({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Material(
      key: const ValueKey<String>('search-desktop-modal'),
      color: colorScheme.surface,
      elevation: 24,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.lg,
              0,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Search',
                    key: const ValueKey<String>('search-desktop-title'),
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                IconButton(
                  key: const ValueKey<String>('search-desktop-close-button'),
                  tooltip: 'Close search',
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              0,
            ),
            child: SearchTextField(autofocus: true),
          ),
          const SizedBox(height: AppSpacing.xl),
          Divider(height: 1, color: colorScheme.outlineVariant),
          const Expanded(child: _SearchDesktopScrollableContent()),
        ],
      ),
    );
  }
}

class _SearchDesktopScrollableContent extends StatelessWidget {
  const _SearchDesktopScrollableContent();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      key: const ValueKey<String>('search-desktop-scrollable-content'),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 220),
        child: Center(
          child: Text(
            'Search for movies and TV shows.',
            key: const ValueKey<String>('search-desktop-placeholder'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
