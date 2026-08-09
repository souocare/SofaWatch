import 'package:flutter/material.dart';
import 'package:sofawatch/app/theme/tokens/app_radius.dart';
import 'package:sofawatch/app/theme/tokens/app_spacing.dart';

class ExploreTrendingLoading extends StatelessWidget {
  const ExploreTrendingLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('explore-trending-loading'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _LoadingSection(),
        const SizedBox(height: AppSpacing.xxxl),
        _LoadingSection(),
      ],
    );
  }
}

class _LoadingSection extends StatelessWidget {
  const _LoadingSection();

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 150,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppRadius.borderSmall,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            separatorBuilder: (BuildContext context, int index) {
              return const SizedBox(width: AppSpacing.lg);
            },
            itemBuilder: (BuildContext context, int index) {
              return SizedBox(
                width: 132,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    AspectRatio(
                      aspectRatio: 2 / 3,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: AppRadius.borderLarge,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: AppRadius.borderSmall,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
