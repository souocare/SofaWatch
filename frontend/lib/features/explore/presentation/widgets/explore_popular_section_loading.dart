import 'package:flutter/material.dart';
import 'package:sofawatch/app/theme/tokens/app_radius.dart';
import 'package:sofawatch/app/theme/tokens/app_spacing.dart';

class ExplorePopularSectionLoading extends StatelessWidget {
  const ExplorePopularSectionLoading({required this.sectionKey, super.key});

  final String sectionKey;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey<String>('$sectionKey-loading'),
      height: 270,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 5,
        separatorBuilder: (BuildContext context, int index) {
          return const SizedBox(width: AppSpacing.lg);
        },
        itemBuilder: (BuildContext context, int index) {
          return const SizedBox(
            width: 132,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AspectRatio(aspectRatio: 2 / 3, child: _LoadingBlock()),
                SizedBox(height: AppSpacing.sm),
                SizedBox(width: 100, height: 14, child: _LoadingBlock()),
                SizedBox(height: AppSpacing.xs),
                SizedBox(width: 75, height: 12, child: _LoadingBlock()),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.borderLarge,
      ),
    );
  }
}
