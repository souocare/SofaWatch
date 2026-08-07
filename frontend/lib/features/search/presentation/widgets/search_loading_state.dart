import 'package:flutter/material.dart';
import 'package:sofawatch/app/theme/tokens/app_radius.dart';
import 'package:sofawatch/app/theme/tokens/app_spacing.dart';

class SearchLoadingState extends StatelessWidget {
  const SearchLoadingState({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Searching',
      child: ListView.separated(
        key: const ValueKey<String>('search-loading-state'),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: compact ? 4 : 5,
        separatorBuilder: (BuildContext context, int index) {
          return const Divider(height: 1);
        },
        itemBuilder: (BuildContext context, int index) {
          return _SearchResultSkeleton(compact: compact);
        },
      ),
    );
  }
}

class _SearchResultSkeleton extends StatelessWidget {
  const _SearchResultSkeleton({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final double posterWidth = compact ? 52 : 60;
    final double posterHeight = posterWidth * 1.5;

    final Color skeletonColor = colorScheme.surfaceContainerHighest;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? AppSpacing.sm : AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: posterWidth,
            height: posterHeight,
            decoration: BoxDecoration(
              color: skeletonColor,
              borderRadius: AppRadius.borderSmall,
            ),
          ),
          SizedBox(width: compact ? AppSpacing.md : AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                FractionallySizedBox(
                  widthFactor: 0.72,
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: skeletonColor,
                      borderRadius: AppRadius.borderSmall,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FractionallySizedBox(
                  widthFactor: 0.42,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: skeletonColor,
                      borderRadius: AppRadius.borderSmall,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
