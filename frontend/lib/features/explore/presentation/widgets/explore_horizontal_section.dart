import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/app/theme/tokens/app_spacing.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_item.dart';
import 'package:sofawatch/features/explore/presentation/widgets/explore_media_card.dart';
import 'package:sofawatch/features/library/application/cubit/library_cubit.dart';
import 'package:sofawatch/features/library/application/cubit/library_item_operation.dart';
import 'package:sofawatch/features/library/application/cubit/library_state.dart';
import 'package:sofawatch/features/library/domain/models/library_media_key.dart';
import 'package:sofawatch/features/library/domain/models/library_media_type.dart';

class ExploreHorizontalSection extends StatelessWidget {
  const ExploreHorizontalSection({required this.items, this.title, super.key});

  final String? title;
  final List<ExploreMediaItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final String? sectionTitle = title;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (sectionTitle != null) ...<Widget>[
          Text(
            sectionTitle,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        SizedBox(
          height: 270,
          child: ListView.separated(
            key: ValueKey<String>(
              'explore-horizontal-section-'
              '${sectionTitle ?? 'untitled'}',
            ),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (BuildContext context, int index) {
              return const SizedBox(width: AppSpacing.lg);
            },
            itemBuilder: (BuildContext context, int index) {
              return _LibraryAwareExploreMediaCard(item: items[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _LibraryAwareExploreMediaCard extends StatelessWidget {
  const _LibraryAwareExploreMediaCard({required this.item});

  final ExploreMediaItem item;

  @override
  Widget build(BuildContext context) {
    final LibraryMediaKey key = LibraryMediaKey(
      mediaType: item.isShow ? LibraryMediaType.show : LibraryMediaType.movie,
      tmdbId: item.tmdbId,
    );

    return BlocSelector<LibraryCubit, LibraryState, LibraryItemOperation>(
      selector: (LibraryState state) {
        return state.operationFor(key);
      },
      builder: (BuildContext context, LibraryItemOperation operation) {
        return ExploreMediaCard(
          item: item,
          operation: operation,
          onAdd: item.inLibrary || operation.isAdding || operation.isAdded
              ? null
              : () {
                  context.read<LibraryCubit>().addToLibrary(key);
                },
        );
      },
    );
  }
}
