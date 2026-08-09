import 'package:flutter/material.dart';
import 'package:sofawatch/app/theme/tokens/app_spacing.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_item.dart';
import 'package:sofawatch/features/explore/presentation/widgets/explore_media_card.dart';

class ExploreHorizontalSection extends StatelessWidget {
  const ExploreHorizontalSection({
    required this.title,
    required this.items,
    super.key,
  });

  final String title;
  final List<ExploreMediaItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 270,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (BuildContext context, int index) {
              return const SizedBox(width: AppSpacing.lg);
            },
            itemBuilder: (BuildContext context, int index) {
              return ExploreMediaCard(item: items[index]);
            },
          ),
        ),
      ],
    );
  }
}
