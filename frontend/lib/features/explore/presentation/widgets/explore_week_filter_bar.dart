import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/app/theme/tokens/app_spacing.dart';
import 'package:sofawatch/features/explore/application/cubit/explore_cubit.dart';
import 'package:sofawatch/features/explore/application/cubit/explore_state.dart';

class ExploreWeekFilterBar extends StatelessWidget {
  const ExploreWeekFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final ExploreWeekFilter selected = context.select(
      (ExploreCubit cubit) => cubit.state.weekFilter,
    );

    return Wrap(
      key: const ValueKey<String>('explore-week-filter-bar'),
      spacing: AppSpacing.sm,
      children: <Widget>[
        _FilterChip(
          label: 'All',
          filter: ExploreWeekFilter.all,
          selected: selected,
        ),
        _FilterChip(
          label: 'TV Shows',
          filter: ExploreWeekFilter.shows,
          selected: selected,
        ),
        _FilterChip(
          label: 'Movies',
          filter: ExploreWeekFilter.movies,
          selected: selected,
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.filter,
    required this.selected,
  });

  final String label;
  final ExploreWeekFilter filter;
  final ExploreWeekFilter selected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      key: ValueKey<String>('explore-week-filter-${filter.name}'),
      label: Text(label),
      selected: selected == filter,
      onSelected: (_) {
        context.read<ExploreCubit>().changeWeekFilter(filter);
      },
    );
  }
}
