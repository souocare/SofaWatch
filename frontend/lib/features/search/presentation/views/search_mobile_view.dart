import 'package:flutter/material.dart';
import 'package:sofawatch/app/theme/tokens/app_spacing.dart';

class SearchMobileView extends StatelessWidget {
  const SearchMobileView({super.key});

  static const double _bottomNavigationReservedSpace = 120;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey<String>('search-mobile-view'),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            _bottomNavigationReservedSpace,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Search',
                key: const ValueKey<String>('search-mobile-title'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: Center(
                  child: Text(
                    'Search for a movie or TV show.',
                    key: const ValueKey<String>('search-mobile-placeholder'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
