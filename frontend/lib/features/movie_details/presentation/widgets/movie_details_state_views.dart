import 'package:flutter/material.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';

class MovieDetailsLoadingView extends StatelessWidget {
  const MovieDetailsLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey<String>('movie-details-loading'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _HeroSkeleton(),

          Padding(
            padding: AppSpacing.cardPaddingLarge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const _SkeletonLine(
                  key: ValueKey<String>('movie-details-loading-action'),
                  width: 180,
                  height: 42,
                  radius: 24,
                ),

                const SizedBox(height: AppSpacing.xxl),

                const _SkeletonLine(
                  key: ValueKey<String>('movie-details-loading-tagline'),
                  width: 260,
                  height: 18,
                ),

                const SizedBox(height: AppSpacing.xxl),

                const Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: <Widget>[
                    _SkeletonLine(width: 88, height: 30, radius: 18),
                    _SkeletonLine(width: 104, height: 30, radius: 18),
                    _SkeletonLine(width: 76, height: 30, radius: 18),
                  ],
                ),

                const SizedBox(height: AppSpacing.xxxl),

                const _SkeletonLine(
                  key: ValueKey<String>('movie-details-loading-overview-title'),
                  width: 110,
                  height: 22,
                ),

                const SizedBox(height: AppSpacing.lg),

                const _SkeletonLine(width: double.infinity, height: 16),

                const SizedBox(height: AppSpacing.sm),

                const _SkeletonLine(width: double.infinity, height: 16),

                const SizedBox(height: AppSpacing.sm),

                const _SkeletonLine(width: 280, height: 16),

                const SizedBox(height: AppSpacing.section),

                const _SkeletonLine(
                  key: ValueKey<String>('movie-details-loading-info-title'),
                  width: 120,
                  height: 22,
                ),

                const SizedBox(height: AppSpacing.lg),

                const _InfoRowSkeleton(),

                const SizedBox(height: AppSpacing.sm),

                const _InfoRowSkeleton(),

                const SizedBox(height: AppSpacing.sm),

                const _InfoRowSkeleton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey<String>('movie-details-loading-hero'),
      height: 360,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const ColoredBox(color: AppColors.surfaceLow),

          const Positioned(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            bottom: AppSpacing.xxl,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                _SkeletonLine(width: 112, height: 168, radius: 16),

                SizedBox(width: AppSpacing.lg),

                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _SkeletonLine(width: 220, height: 28),

                        SizedBox(height: AppSpacing.sm),

                        _SkeletonLine(width: 150, height: 18),

                        SizedBox(height: AppSpacing.md),

                        _SkeletonLine(width: 110, height: 18),
                      ],
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

class _InfoRowSkeleton extends StatelessWidget {
  const _InfoRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          _SkeletonLine(width: 18, height: 18, radius: 9),

          SizedBox(width: AppSpacing.md),

          _SkeletonLine(width: 82, height: 14),

          SizedBox(width: AppSpacing.sm),

          Expanded(child: _SkeletonLine(width: double.infinity, height: 14)),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({
    required this.width,
    required this.height,
    this.radius = 8,
    super.key,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class MovieDetailsFailureView extends StatelessWidget {
  const MovieDetailsFailureView({
    required this.isTimeout,
    required this.onRetry,
    super.key,
  });

  final bool isTimeout;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey<String>('movie-details-failure'),
      child: Padding(
        padding: AppSpacing.cardPaddingLarge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: AppColors.textMuted,
            ),

            const SizedBox(height: AppSpacing.lg),

            Text(
              isTimeout
                  ? 'Loading the movie took too long'
                  : 'Could not load this movie',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: AppSpacing.sm),

            Text(
              'Please try again.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),

            const SizedBox(height: AppSpacing.xl),

            FilledButton.icon(
              key: const ValueKey<String>('movie-details-retry'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
