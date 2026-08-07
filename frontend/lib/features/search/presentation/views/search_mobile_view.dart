import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/app/theme/tokens/app_spacing.dart';
import 'package:sofawatch/features/search/application/bloc/search_bloc.dart';
import 'package:sofawatch/features/search/application/bloc/search_state.dart';
import 'package:sofawatch/features/search/domain/entities/search_result.dart';
import 'package:sofawatch/features/search/presentation/widgets/search_minimum_characters_hint.dart';
import 'package:sofawatch/features/search/presentation/widgets/search_results_section.dart';

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
              const Expanded(child: _SearchMobileContent()),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchMobileContent extends StatelessWidget {
  const _SearchMobileContent();

  void _openResult(SearchResult result) {
    // A navegação para preview será implementada no ponto 13.12.
  }

  void _handleResultAction(SearchResult result) {
    // A ação de Watchlist/Biblioteca será implementada no ponto 13.14.
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
      buildWhen: (SearchState previous, SearchState current) {
        return previous.query != current.query ||
            previous.results != current.results;
      },
      builder: (BuildContext context, SearchState state) {
        if (state.needsMoreCharacters) {
          return SearchMinimumCharactersHint(
            remainingCharacters: state.remainingCharacters,
          );
        }

        if (state.hasResults) {
          return SearchResultsSection(
            results: state.results.data!.results,
            scrollable: true,
            compact: true,
            onResultPressed: _openResult,
            onResultActionPressed: _handleResultAction,
          );
        }

        return const _SearchMobilePlaceholder();
      },
    );
  }
}

class _SearchMobilePlaceholder extends StatelessWidget {
  const _SearchMobilePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Search for a movie or TV show.',
        key: const ValueKey<String>('search-mobile-placeholder'),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
