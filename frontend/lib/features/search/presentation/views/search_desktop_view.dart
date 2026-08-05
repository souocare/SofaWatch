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
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () {
          _closeSearch(context);
        },
      },
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: _maximumModalWidth,
                maxHeight: _maximumModalHeight,
                minHeight: _minimumModalHeight,
              ),
              child: Material(
                key: const ValueKey<String>('search-desktop-modal'),
                color: colorScheme.surface,
                elevation: 24,
                clipBehavior: Clip.antiAlias,
                borderRadius: BorderRadius.circular(28),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'Search',
                              key: const ValueKey<String>(
                                'search-desktop-title',
                              ),
                              style: theme.textTheme.headlineMedium,
                            ),
                          ),
                          IconButton(
                            key: const ValueKey<String>(
                              'search-desktop-close-button',
                            ),
                            tooltip: 'Close search',
                            onPressed: () {
                              _closeSearch(context);
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const SearchTextField(autofocus: true),
                      const SizedBox(height: AppSpacing.xl),
                      Divider(height: 1, color: colorScheme.outlineVariant),
                      const SizedBox(height: AppSpacing.xl),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Search for movies and TV shows.',
                            key: const ValueKey<String>(
                              'search-desktop-placeholder',
                            ),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
