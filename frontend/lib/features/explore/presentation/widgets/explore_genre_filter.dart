import 'package:flutter/material.dart';
import 'package:sofawatch/app/theme/tokens/app_spacing.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_genre.dart';

class ExploreGenreFilter extends StatelessWidget {
  const ExploreGenreFilter({
    required this.genres,
    required this.selectedGenreId,
    required this.onChanged,
    required this.keyPrefix,
    super.key,
  });

  final List<ExploreGenre> genres;
  final int? selectedGenreId;
  final ValueChanged<int?> onChanged;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        key: ValueKey<String>('$keyPrefix-genre-filter'),
        scrollDirection: Axis.horizontal,
        itemCount: genres.length + 1,
        separatorBuilder: (BuildContext context, int index) {
          return const SizedBox(width: AppSpacing.sm);
        },
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return _GenreChip(
              key: ValueKey<String>('$keyPrefix-genre-all'),
              label: 'All Genres',
              selected: selectedGenreId == null,
              onSelected: () {
                onChanged(null);
              },
            );
          }

          final ExploreGenre genre = genres[index - 1];

          return _GenreChip(
            key: ValueKey<String>('$keyPrefix-genre-${genre.id}'),
            label: genre.name,
            selected: selectedGenreId == genre.id,
            onSelected: () {
              onChanged(genre.id);
            },
          );
        },
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  const _GenreChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) {
        onSelected();
      },
    );
  }
}
