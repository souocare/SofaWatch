import 'package:flutter/material.dart';
import 'package:sofawatch/app/theme/tokens/app_spacing.dart';
import 'package:sofawatch/features/search/domain/entities/search_result.dart';
import 'package:sofawatch/features/search/presentation/widgets/search_result_row.dart';

class SearchResultsSection extends StatelessWidget {
  const SearchResultsSection({
    required this.results,
    required this.onResultPressed,
    required this.scrollable,
    this.onResultActionPressed,
    this.compact = false,
    super.key,
  });

  final List<SearchResult> results;
  final ValueChanged<SearchResult> onResultPressed;
  final ValueChanged<SearchResult>? onResultActionPressed;

  /// Mobile usa uma lista com scroll próprio.
  ///
  /// Desktop usa uma lista não scrollável porque já está dentro de um
  /// SingleChildScrollView.
  final bool scrollable;

  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const SizedBox.shrink();
    }

    if (scrollable) {
      return CustomScrollView(
        key: const ValueKey<String>('search-results-scroll-view'),
        slivers: <Widget>[
          const SliverToBoxAdapter(child: _SearchResultsHeader()),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
          SliverList.separated(
            itemCount: results.length,
            itemBuilder: (BuildContext context, int index) {
              return _buildResultRow(results[index]);
            },
            separatorBuilder: (BuildContext context, int index) {
              return const Divider(height: 1);
            },
          ),
        ],
      );
    }

    return Column(
      key: const ValueKey<String>('search-results-column'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _SearchResultsHeader(),
        const SizedBox(height: AppSpacing.md),
        for (int index = 0; index < results.length; index++) ...<Widget>[
          _buildResultRow(results[index]),
          if (index < results.length - 1) const Divider(height: 1),
        ],
      ],
    );
  }

  Widget _buildResultRow(SearchResult result) {
    return SearchResultRow(
      result: result,
      compact: compact,
      onPressed: () {
        onResultPressed(result);
      },
      onActionPressed: onResultActionPressed == null
          ? null
          : () {
              onResultActionPressed!(result);
            },
    );
  }
}

class _SearchResultsHeader extends StatelessWidget {
  const _SearchResultsHeader();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Top Results',
      key: const ValueKey<String>('search-top-results-title'),
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}
