import 'package:flutter/material.dart';
import 'package:sofawatch/app/theme/tokens/app_spacing.dart';
import 'package:sofawatch/features/search/presentation/widgets/search_text_field.dart';

class SearchDesktopView extends StatelessWidget {
  const SearchDesktopView({super.key});

  static const double _maximumModalWidth = 780;
  static const double _maximumModalHeight = 720;
  static const double _minimumModalHeight = 420;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
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
                    Text(
                      'Search',
                      key: const ValueKey<String>('search-desktop-title'),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const SearchTextField(),
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
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
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
    );
  }
}
