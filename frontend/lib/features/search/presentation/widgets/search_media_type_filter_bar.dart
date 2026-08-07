import 'package:flutter/material.dart';
import 'package:sofawatch/app/theme/tokens/app_spacing.dart';
import 'package:sofawatch/features/search/domain/models/search_media_type_filter.dart';

class SearchMediaTypeFilterBar extends StatelessWidget {
  const SearchMediaTypeFilterBar({
    required this.selectedFilter,
    required this.onFilterChanged,
    this.compact = false,
    super.key,
  });

  final SearchMediaTypeFilter selectedFilter;
  final ValueChanged<SearchMediaTypeFilter> onFilterChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey<String>('search-media-type-filter-scroll'),
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        key: const ValueKey<String>('search-media-type-filter-bar'),
        children: <Widget>[
          _SearchFilterChip(
            filter: SearchMediaTypeFilter.all,
            label: 'All',
            selected: selectedFilter == SearchMediaTypeFilter.all,
            compact: compact,
            onPressed: onFilterChanged,
          ),
          const SizedBox(width: AppSpacing.sm),
          _SearchFilterChip(
            filter: SearchMediaTypeFilter.show,
            label: 'Shows',
            selected: selectedFilter == SearchMediaTypeFilter.show,
            compact: compact,
            onPressed: onFilterChanged,
          ),
          const SizedBox(width: AppSpacing.sm),
          _SearchFilterChip(
            filter: SearchMediaTypeFilter.movie,
            label: 'Movies',
            selected: selectedFilter == SearchMediaTypeFilter.movie,
            compact: compact,
            onPressed: onFilterChanged,
          ),
        ],
      ),
    );
  }
}

class _SearchFilterChip extends StatelessWidget {
  const _SearchFilterChip({
    required this.filter,
    required this.label,
    required this.selected,
    required this.compact,
    required this.onPressed,
  });

  final SearchMediaTypeFilter filter;
  final String label;
  final bool selected;
  final bool compact;
  final ValueChanged<SearchMediaTypeFilter> onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: '$label search filter',
      child: Material(
        color: selected
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          key: ValueKey<String>('search-filter-${filter.name}'),
          onTap: () {
            onPressed(filter);
          },
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 18,
              vertical: compact ? 7 : 9,
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
