import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/app/theme/tokens/app_design_tokens.dart';
import 'package:sofawatch/core/errors/app_error_message_mapper.dart';
import 'package:sofawatch/features/profile/application/cubit/profile_cubit.dart';
import 'package:sofawatch/features/profile/application/cubit/profile_state.dart';
import 'package:sofawatch/features/profile/domain/models/profile_user.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/core/widgets/section_failure_card.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_summary_cubit.dart';
import 'package:sofawatch/features/statistics/application/cubit/statistics_summary_state.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_summary.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/features/statistics/presentation/formatters/statistics_watch_time_formatter.dart';
import 'package:sofawatch/features/library/application/cubit/library_preview_cubit.dart';
import 'package:sofawatch/features/library/application/cubit/library_preview_state.dart';
import 'package:sofawatch/features/library/domain/models/library_preview.dart';
import 'package:sofawatch/features/history/application/cubit/history_preview_cubit.dart';
import 'package:sofawatch/features/history/application/cubit/history_preview_state.dart';
import 'package:sofawatch/features/history/domain/models/history_episode_item.dart';
import 'package:sofawatch/features/history/domain/models/history_movie_item.dart';
import 'package:sofawatch/features/history/domain/models/history_preview.dart';
import 'package:sofawatch/features/server/application/cubit/server_health_cubit.dart';
import 'package:sofawatch/features/server/application/cubit/server_health_state.dart';
import 'package:sofawatch/features/server/domain/models/server_health.dart';
import 'package:sofawatch/features/server/domain/repositories/server_repository.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey<String>('profile-page'),
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          key: const ValueKey<String>('profile-scroll-view'),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.mobileHorizontalPadding,
            AppSpacing.xxl,
            AppSpacing.mobileHorizontalPadding,
            AppSpacing.section,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxContentWidth,
              ),
              child: Column(
                key: const ValueKey<String>('profile-content'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Profile',
                    key: const ValueKey<String>('profile-page-title'),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  const _ProfileBody(),

                  const SizedBox(height: AppSpacing.section),

                  const _ProfileStatisticsSection(),

                  const SizedBox(height: AppSpacing.section),

                  const _ProfileLibrarySection(),

                  const SizedBox(height: AppSpacing.section),

                  const _ProfileHistorySection(),

                  const _ProfileServerGate(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (BuildContext context, ProfileState state) {
        return switch (state) {
          ProfileInitial() || ProfileLoading() => const _ProfileLoading(),

          ProfileSuccess(:final user) => _ProfileContent(user: user),

          ProfileFailure(:final error) => _ProfileFailure(error: error),
        };
      },
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.user});

  final ProfileUser user;

  @override
  Widget build(BuildContext context) {
    return _ProfileIdentityCard(user: user);
  }
}

class _ProfileIdentityCard extends StatelessWidget {
  const _ProfileIdentityCard({required this.user});

  final ProfileUser user;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('profile-user-card'),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Container(
            key: const ValueKey<String>('profile-user-avatar'),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.outlineVariant),
            ),
            alignment: Alignment.center,
            child: Text(
              _initialFor(user.displayName),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),

          const SizedBox(width: AppSpacing.lg),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  user.displayName,
                  key: const ValueKey<String>('profile-user-display-name'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  'SofaWatch profile',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
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

class _ProfileStatisticsSection extends StatelessWidget {
  const _ProfileStatisticsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('profile-statistics'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Statistics',
          key: const ValueKey<String>('profile-statistics-title'),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: AppSpacing.md),

        BlocBuilder<StatisticsSummaryCubit, StatisticsSummaryState>(
          builder: (BuildContext context, StatisticsSummaryState state) {
            return switch (state) {
              StatisticsSummaryInitial() ||
              StatisticsSummaryLoading() => const _ProfileStatisticsLoading(),

              StatisticsSummarySuccess(:final summary) =>
                _ProfileStatisticsContent(summary: summary),

              StatisticsSummaryFailure(:final error) => SectionFailureCard(
                failureKey: 'profile-statistics-failure',
                error: error,
                onRetry: context.read<StatisticsSummaryCubit>().retry,
              ),
            };
          },
        ),
      ],
    );
  }
}

class _ProfileStatisticsContent extends StatelessWidget {
  const _ProfileStatisticsContent({required this.summary});

  final StatisticsSummary summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool useFourColumns = constraints.maxWidth >= 720;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            GridView.count(
              key: const ValueKey<String>('profile-statistics-grid'),
              crossAxisCount: useFourColumns ? 4 : 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: useFourColumns ? 1.15 : 1.3,
              children: <Widget>[
                _ProfileStatisticCard(
                  cardKey: 'profile-stat-shows',
                  icon: Icons.tv_rounded,
                  value: summary.showsWatched.toString(),
                  label: 'Shows',
                ),
                _ProfileStatisticCard(
                  cardKey: 'profile-stat-movies',
                  icon: Icons.movie_rounded,
                  value: summary.moviesWatched.toString(),
                  label: 'Movies',
                ),
                _ProfileStatisticCard(
                  cardKey: 'profile-stat-episodes',
                  icon: Icons.play_circle_rounded,
                  value: summary.episodesWatched.toString(),
                  label: 'Episodes',
                ),
                _ProfileStatisticCard(
                  cardKey: 'profile-stat-watch-time',
                  icon: Icons.schedule_rounded,
                  value: formatProfileWatchTime(summary.watchTimeMinutes),
                  label: 'Watch time',
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const ValueKey<String>(
                  'profile-detailed-statistics-action',
                ),
                onPressed: () {
                  context.pushNamed(AppRoute.detailedStatistics.name);
                },
                child: const Text('View detailed statistics →'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileStatisticCard extends StatelessWidget {
  const _ProfileStatisticCard({
    required this.cardKey,
    required this.icon,
    required this.value,
    required this.label,
  });

  final String cardKey;
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey<String>(cardKey),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 22, color: AppColors.textSecondary),

          const SizedBox(height: AppSpacing.sm),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: AppSpacing.xs),

          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatisticsLoading extends StatelessWidget {
  const _ProfileStatisticsLoading();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      key: const ValueKey<String>('profile-statistics-loading'),
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      children: const <Widget>[
        _ProfileStatisticSkeleton(),
        _ProfileStatisticSkeleton(),
        _ProfileStatisticSkeleton(),
        _ProfileStatisticSkeleton(),
      ],
    );
  }
}

class _ProfileStatisticSkeleton extends StatelessWidget {
  const _ProfileStatisticSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
    );
  }
}

class _ProfileLoading extends StatelessWidget {
  const _ProfileLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      key: ValueKey<String>('profile-loading'),
      height: 120,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ProfileFailure extends StatelessWidget {
  const _ProfileFailure({required this.error});

  final AppException error;

  @override
  Widget build(BuildContext context) {
    final String message = AppErrorMessageMapper.map(error);

    return Container(
      key: const ValueKey<String>('profile-failure'),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            key: const ValueKey<String>('profile-retry'),
            onPressed: context.read<ProfileCubit>().retry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

String _initialFor(String displayName) {
  final String trimmed = displayName.trim();

  if (trimmed.isEmpty) {
    return '?';
  }

  return trimmed.characters.first.toUpperCase();
}

String formatProfileWatchTime(int totalMinutes) {
  if (totalMinutes <= 0) {
    return '0m';
  }

  final int days = totalMinutes ~/ (24 * 60);
  final int remainingAfterDays = totalMinutes % (24 * 60);

  final int hours = remainingAfterDays ~/ 60;
  final int minutes = remainingAfterDays % 60;

  if (days > 0) {
    if (hours > 0) {
      return '${days}d ${hours}h';
    }

    return '${days}d';
  }

  if (hours > 0) {
    if (minutes > 0) {
      return '${hours}h ${minutes}m';
    }

    return '${hours}h';
  }

  return '${minutes}m';
}

class _ProfileLibrarySection extends StatelessWidget {
  const _ProfileLibrarySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('profile-library'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Library',
          key: const ValueKey<String>('profile-library-title'),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: AppSpacing.md),

        BlocBuilder<LibraryPreviewCubit, LibraryPreviewState>(
          builder: (BuildContext context, LibraryPreviewState state) {
            return switch (state) {
              LibraryPreviewInitial() ||
              LibraryPreviewLoading() => const _ProfileLibraryLoading(),

              LibraryPreviewSuccess(:final preview) => _ProfileLibraryContent(
                preview: preview,
              ),

              LibraryPreviewFailure(:final error) => SectionFailureCard(
                failureKey: 'profile-library-failure',
                error: error,
                onRetry: context.read<LibraryPreviewCubit>().retry,
              ),
            };
          },
        ),
      ],
    );
  }
}

class _ProfileLibraryContent extends StatelessWidget {
  const _ProfileLibraryContent({required this.preview});

  final LibraryPreview preview;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('profile-library-content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _ProfileLibraryGroup(
          groupKey: 'profile-library-shows',
          title: 'Shows',
          isEmpty: preview.shows.isEmpty,
          emptyMessage: 'No Shows in your Library yet.',
          onSeeAll: () {
            context.pushNamed(
              AppRoute.libraryCollection.name,
              queryParameters: const <String, String>{'tab': 'shows'},
            );
          },
          children: preview.shows
              .map(
                (LibraryPreviewShow show) => _ProfileLibraryPoster(
                  posterKey: 'profile-library-show-${show.id}',
                  title: show.title,
                  posterUrl: show.posterUrl,
                  icon: Icons.tv_rounded,
                ),
              )
              .toList(growable: false),
        ),

        const SizedBox(height: AppSpacing.xl),

        _ProfileLibraryGroup(
          groupKey: 'profile-library-movies',
          title: 'Movies',
          isEmpty: preview.movies.isEmpty,
          emptyMessage: 'No Movies in your Library yet.',
          onSeeAll: () {
            context.pushNamed(
              AppRoute.libraryCollection.name,
              queryParameters: const <String, String>{'tab': 'movies'},
            );
          },
          children: preview.movies
              .map(
                (LibraryPreviewMovie movie) => _ProfileLibraryPoster(
                  posterKey: 'profile-library-movie-${movie.id}',
                  title: movie.title,
                  posterUrl: movie.posterUrl,
                  icon: Icons.movie_rounded,
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _ProfileLibraryGroup extends StatelessWidget {
  const _ProfileLibraryGroup({
    required this.groupKey,
    required this.title,
    required this.isEmpty,
    required this.emptyMessage,
    required this.children,
    required this.onSeeAll,
  });

  final String groupKey;
  final String title;
  final bool isEmpty;
  final String emptyMessage;
  final List<Widget> children;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey<String>(groupKey),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                key: ValueKey<String>('$groupKey-title'),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),

            TextButton(
              key: ValueKey<String>('$groupKey-see-all'),
              onPressed: onSeeAll,
              child: const Text('See All'),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        if (isEmpty)
          _ProfileLibraryEmpty(
            emptyKey: '$groupKey-empty',
            message: emptyMessage,
          )
        else ...<Widget>[
          SizedBox(
            key: ValueKey<String>('$groupKey-list'),
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: children.length,
              separatorBuilder: (BuildContext context, int index) {
                return const SizedBox(width: AppSpacing.sm);
              },
              itemBuilder: (BuildContext context, int index) {
                return children[index];
              },
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: ValueKey<String>('$groupKey-see-all-footer'),
              onPressed: onSeeAll,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: const Text('See All'),
            ),
          ),
        ],
      ],
    );
  }
}

class _ProfileLibraryPoster extends StatelessWidget {
  const _ProfileLibraryPoster({
    required this.posterKey,
    required this.title,
    required this.posterUrl,
    required this.icon,
  });

  final String posterKey;
  final String title;
  final String? posterUrl;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey<String>(posterKey),
      width: 108,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 2 / 3,
            child: ClipRRect(
              borderRadius: AppRadius.borderLarge,
              child: _ProfileLibraryPosterImage(
                posterUrl: posterUrl,
                icon: icon,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ProfileLibraryPosterImage extends StatelessWidget {
  const _ProfileLibraryPosterImage({
    required this.posterUrl,
    required this.icon,
  });

  final String? posterUrl;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final String? url = posterUrl?.trim();

    if (url == null || url.isEmpty) {
      return _ProfileLibraryPosterPlaceholder(icon: icon);
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
            return _ProfileLibraryPosterPlaceholder(icon: icon);
          },
    );
  }
}

class _ProfileLibraryPosterPlaceholder extends StatelessWidget {
  const _ProfileLibraryPosterPlaceholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceHigh,
      alignment: Alignment.center,
      child: Icon(icon, size: 28, color: AppColors.textSecondary),
    );
  }
}

class _ProfileLibraryEmpty extends StatelessWidget {
  const _ProfileLibraryEmpty({required this.emptyKey, required this.message});

  final String emptyKey;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey<String>(emptyKey),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _ProfileLibraryLoading extends StatelessWidget {
  const _ProfileLibraryLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('profile-library-loading'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _ProfileLibraryLoadingGroup(),

        const SizedBox(height: AppSpacing.xl),

        const _ProfileLibraryLoadingGroup(),
      ],
    );
  }
}

class _ProfileLibraryLoadingGroup extends StatelessWidget {
  const _ProfileLibraryLoadingGroup();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 72,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: AppRadius.borderLarge,
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 4,
            separatorBuilder: (BuildContext context, int index) {
              return const SizedBox(width: AppSpacing.sm);
            },
            itemBuilder: (BuildContext context, int index) {
              return Container(
                width: 108,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: AppRadius.borderLarge,
                  border: Border.all(color: AppColors.outlineVariant),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProfileHistorySection extends StatelessWidget {
  const _ProfileHistorySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('profile-history'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'History',
          key: const ValueKey<String>('profile-history-title'),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: AppSpacing.md),

        BlocBuilder<HistoryPreviewCubit, HistoryPreviewState>(
          builder: (BuildContext context, HistoryPreviewState state) {
            return switch (state) {
              HistoryPreviewInitial() ||
              HistoryPreviewLoading() => const _ProfileHistoryLoading(),

              HistoryPreviewSuccess(:final preview) => _ProfileHistoryContent(
                preview: preview,
              ),

              HistoryPreviewFailure(:final error) => SectionFailureCard(
                failureKey: 'profile-history-failure',
                error: error,
                onRetry: context.read<HistoryPreviewCubit>().retry,
              ),
            };
          },
        ),
      ],
    );
  }
}

class _ProfileHistoryContent extends StatelessWidget {
  const _ProfileHistoryContent({required this.preview});

  final HistoryPreview preview;

  @override
  Widget build(BuildContext context) {
    if (preview.isEmpty) {
      return const _ProfileHistoryEmpty();
    }

    return Column(
      key: const ValueKey<String>('profile-history-content'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (preview.episodes.isNotEmpty)
          _ProfileHistoryGroup(
            groupKey: 'profile-history-episodes',
            title: 'Episodes',
            children: preview.episodes
                .map(
                  (HistoryEpisodeItem item) =>
                      _ProfileEpisodeHistoryRow(item: item),
                )
                .toList(growable: false),
          ),

        if (preview.episodes.isNotEmpty && preview.movies.isNotEmpty)
          const SizedBox(height: AppSpacing.xl),

        if (preview.movies.isNotEmpty)
          _ProfileHistoryGroup(
            groupKey: 'profile-history-movies',
            title: 'Movies',
            children: preview.movies
                .map(
                  (HistoryMovieItem item) =>
                      _ProfileMovieHistoryRow(item: item),
                )
                .toList(growable: false),
          ),
      ],
    );
  }
}

class _ProfileHistoryGroup extends StatelessWidget {
  const _ProfileHistoryGroup({
    required this.groupKey,
    required this.title,
    required this.children,
  });

  final String groupKey;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey<String>(groupKey),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          title,
          key: ValueKey<String>('$groupKey-title'),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),

        const SizedBox(height: AppSpacing.sm),

        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: AppRadius.borderLarge,
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            children: <Widget>[
              for (int index = 0; index < children.length; index++) ...<Widget>[
                children[index],

                if (index < children.length - 1)
                  Divider(height: 1, color: AppColors.outlineVariant),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileEpisodeHistoryRow extends StatelessWidget {
  const _ProfileEpisodeHistoryRow({required this.item});

  final HistoryEpisodeItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey<String>('profile-history-episode-${item.eventId}'),
      borderRadius: AppRadius.borderLarge,
      onTap: () {
        context.pushNamed(
          AppRoute.episodeDetails.name,
          pathParameters: <String, String>{'episodeId': item.episode.id},
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: <Widget>[
            _ProfileHistoryArtwork(
              imageUrl: item.episode.stillUrl ?? item.posterUrl,
              icon: Icons.tv_outlined,
              isPoster: false,
            ),

            const SizedBox(width: AppSpacing.md),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.showTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  Text(
                    '${item.episode.code} · ${item.episode.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  Text(
                    _formatProfileHistoryDate(item.watchedAt),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _ProfileMovieHistoryRow extends StatelessWidget {
  const _ProfileMovieHistoryRow({required this.item});

  final HistoryMovieItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey<String>('profile-history-movie-${item.eventId}'),
      borderRadius: AppRadius.borderLarge,
      onTap: () {
        context.pushNamed(
          AppRoute.movieDetails.name,
          pathParameters: <String, String>{
            'movieId': item.movieTmdbId.toString(),
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: <Widget>[
            _ProfileHistoryArtwork(
              imageUrl: item.posterUrl,
              icon: Icons.movie_outlined,
              isPoster: true,
            ),

            const SizedBox(width: AppSpacing.md),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.movieTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  Text(
                    _formatProfileHistoryDate(item.watchedAt),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.sm),

            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _ProfileHistoryArtwork extends StatelessWidget {
  const _ProfileHistoryArtwork({
    required this.imageUrl,
    required this.icon,
    required this.isPoster,
  });

  final String? imageUrl;
  final IconData icon;
  final bool isPoster;

  @override
  Widget build(BuildContext context) {
    final String? normalizedUrl = imageUrl?.trim();

    final double width = isPoster ? 42 : 72;
    final double height = isPoster ? 63 : 46;

    return ClipRRect(
      borderRadius: AppRadius.borderMedium,
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: normalizedUrl == null || normalizedUrl.isEmpty
              ? Icon(icon, size: 24, color: AppColors.textMuted)
              : Image.network(
                  normalizedUrl,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (
                        BuildContext context,
                        Object error,
                        StackTrace? stackTrace,
                      ) {
                        return Icon(icon, size: 24, color: AppColors.textMuted);
                      },
                ),
        ),
      ),
    );
  }
}

class _ProfileHistoryEmpty extends StatelessWidget {
  const _ProfileHistoryEmpty();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('profile-history-empty'),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Text(
        'Your viewing History is empty.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _ProfileHistoryLoading extends StatelessWidget {
  const _ProfileHistoryLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('profile-history-loading'),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: const Column(
        children: <Widget>[
          _ProfileHistoryLoadingRow(),
          SizedBox(height: AppSpacing.sm),
          _ProfileHistoryLoadingRow(),
          SizedBox(height: AppSpacing.sm),
          _ProfileHistoryLoadingRow(),
        ],
      ),
    );
  }
}

class _ProfileHistoryLoadingRow extends StatelessWidget {
  const _ProfileHistoryLoadingRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 72,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.borderMedium,
          ),
        ),

        const SizedBox(width: AppSpacing.md),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 140,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.borderMedium,
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              Container(
                width: 100,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.borderMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileServerGate extends StatelessWidget {
  const _ProfileServerGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      buildWhen: (ProfileState previous, ProfileState current) {
        final bool previousIsAdmin = switch (previous) {
          ProfileSuccess(:final user) => user.isAdmin,
          _ => false,
        };

        final bool currentIsAdmin = switch (current) {
          ProfileSuccess(:final user) => user.isAdmin,
          _ => false,
        };

        return previousIsAdmin != currentIsAdmin;
      },
      builder: (BuildContext context, ProfileState state) {
        final bool isAdmin = switch (state) {
          ProfileSuccess(:final user) => user.isAdmin,
          _ => false,
        };

        if (!isAdmin) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SizedBox(height: AppSpacing.section),

            BlocProvider<ServerHealthCubit>(
              create: (BuildContext context) {
                return ServerHealthCubit(
                  repository: context.read<ServerRepository>(),
                )..load();
              },
              child: const _ProfileServerSection(),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileServerSection extends StatelessWidget {
  const _ProfileServerSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('profile-server'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Server',
          key: const ValueKey<String>('profile-server-title'),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: AppSpacing.md),

        BlocBuilder<ServerHealthCubit, ServerHealthState>(
          builder: (BuildContext context, ServerHealthState state) {
            return switch (state) {
              ServerHealthInitial() ||
              ServerHealthLoading() => const _ProfileServerLoading(),

              ServerHealthSuccess(:final health) => _ProfileServerHealthSummary(
                health: health,
              ),

              ServerHealthFailure(:final error) => SectionFailureCard(
                failureKey: 'profile-server-failure',
                error: error,
                onRetry: context.read<ServerHealthCubit>().retry,
              ),
            };
          },
        ),
      ],
    );
  }
}

class _ProfileServerHealthSummary extends StatelessWidget {
  const _ProfileServerHealthSummary({required this.health});

  final ServerHealth health;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('profile-server-health'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _ProfileServerOverallHealthCard(health: health),

        const SizedBox(height: AppSpacing.sm),

        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool useFourColumns = constraints.maxWidth >= 720;

            return GridView.count(
              key: const ValueKey<String>('profile-server-health-grid'),
              crossAxisCount: useFourColumns ? 4 : 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: useFourColumns ? 1.2 : 1.3,
              children: <Widget>[
                _ProfileServerMetricCard(
                  cardKey: 'profile-server-checked-at',
                  icon: Icons.update_rounded,
                  value: _formatServerCheckedAt(health.checkedAt),
                  label: 'Checked at',
                ),
                _ProfileServerMetricCard(
                  cardKey: 'profile-server-uptime',
                  icon: Icons.timer_outlined,
                  value: _formatServerUptime(health.uptimeSeconds),
                  label: 'Uptime',
                ),
                _ProfileServerMetricCard(
                  cardKey: 'profile-server-database',
                  icon: Icons.storage_rounded,
                  value: _serverComponentStatusLabel(health.database.status),
                  label: 'Database',
                  detail: _formatServerLatency(health.database.latencyMs),
                ),
                _ProfileServerMetricCard(
                  cardKey: 'profile-server-tmdb',
                  icon: Icons.cloud_outlined,
                  value: _serverComponentStatusLabel(health.tmdb.status),
                  label: 'TMDB',
                  detail: _serverTmdbDetail(health.tmdb),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.section),

        Text(
          'Database status',
          key: const ValueKey<String>('profile-server-database-title'),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: AppSpacing.md),

        _ProfileServerDatabaseStatus(database: health.database),

        const SizedBox(height: AppSpacing.section),

        _ProfileServerSubsectionTitle(
          title: 'Environment',
          titleKey: 'profile-server-environment-title',
        ),

        const SizedBox(height: AppSpacing.md),

        _ProfileServerEnvironmentStatus(environment: health.environment),

        const SizedBox(height: AppSpacing.section),

        _ProfileServerSubsectionTitle(
          title: 'Storage',
          titleKey: 'profile-server-storage-title',
        ),

        const SizedBox(height: AppSpacing.md),

        _ProfileServerStorageStatus(storage: health.storage),

        const SizedBox(height: AppSpacing.section),

        _ProfileServerSubsectionTitle(
          title: 'Runtime',
          titleKey: 'profile-server-runtime-title',
        ),

        const SizedBox(height: AppSpacing.md),

        _ProfileServerRuntimeStatus(health: health),

        const SizedBox(height: AppSpacing.section),

        _ProfileServerSubsectionTitle(
          title: 'Providers',
          titleKey: 'profile-server-providers-title',
        ),

        const SizedBox(height: AppSpacing.md),

        _ProfileServerProvidersStatus(tmdb: health.tmdb),
      ],
    );
  }
}

class _ProfileServerOverallHealthCard extends StatelessWidget {
  const _ProfileServerOverallHealthCard({required this.health});

  final ServerHealth health;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('profile-server-overall-health'),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            health.isHealthy
                ? Icons.check_circle_outline_rounded
                : Icons.warning_amber_rounded,
            color: AppColors.textSecondary,
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Health status',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  _serverHealthStatusLabel(health.status),
                  key: const ValueKey<String>('profile-server-health-status'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
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

class _ProfileServerMetricCard extends StatelessWidget {
  const _ProfileServerMetricCard({
    required this.cardKey,
    required this.icon,
    required this.value,
    required this.label,
    this.detail,
  });

  final String cardKey;
  final IconData icon;
  final String value;
  final String label;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey<String>(cardKey),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 22, color: AppColors.textSecondary),

          const SizedBox(height: AppSpacing.sm),

          Text(
            value,
            key: ValueKey<String>('$cardKey-value'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: AppSpacing.xs),

          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),

          if (detail case final String detail) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),

            Text(
              detail,
              key: ValueKey<String>('$cardKey-detail'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileServerSubsectionTitle extends StatelessWidget {
  const _ProfileServerSubsectionTitle({
    required this.title,
    required this.titleKey,
  });

  final String title;
  final String titleKey;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      key: ValueKey<String>(titleKey),
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _ProfileServerEnvironmentStatus extends StatelessWidget {
  const _ProfileServerEnvironmentStatus({required this.environment});

  final ServerEnvironment environment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool useFourColumns = constraints.maxWidth >= 720;

        return GridView.count(
          key: const ValueKey<String>('profile-server-environment-status'),
          crossAxisCount: useFourColumns ? 4 : 2,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: useFourColumns ? 1.2 : 1.3,
          children: <Widget>[
            _ProfileServerMetricCard(
              cardKey: 'profile-server-environment-name',
              icon: Icons.layers_outlined,
              value: environment.environment,
              label: 'Environment',
            ),
            _ProfileServerMetricCard(
              cardKey: 'profile-server-environment-debug',
              icon: Icons.bug_report_outlined,
              value: environment.debug ? 'Enabled' : 'Disabled',
              label: 'Debug',
            ),
            _ProfileServerMetricCard(
              cardKey: 'profile-server-environment-api',
              icon: Icons.lan_outlined,
              value: '${environment.apiHost}:${environment.apiPort}',
              label: 'API',
            ),
            _ProfileServerMetricCard(
              cardKey: 'profile-server-environment-language',
              icon: Icons.language_outlined,
              value: environment.defaultLanguage,
              label: 'Default language',
              detail: environment.supportedLanguages.join(', '),
            ),
            _ProfileServerMetricCard(
              cardKey: 'profile-server-environment-refresh',
              icon: Icons.sync_outlined,
              value: '${environment.metadataRefreshDays}d',
              label: 'Metadata refresh',
            ),
          ],
        );
      },
    );
  }
}

class _ProfileServerStorageStatus extends StatelessWidget {
  const _ProfileServerStorageStatus({required this.storage});

  final ServerStorage storage;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('profile-server-storage-status'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool useFourColumns = constraints.maxWidth >= 720;

            return GridView.count(
              key: const ValueKey<String>('profile-server-storage-grid'),
              crossAxisCount: useFourColumns ? 4 : 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: useFourColumns ? 1.2 : 1.3,
              children: <Widget>[
                _ProfileServerMetricCard(
                  cardKey: 'profile-server-storage-directory',
                  icon: Icons.folder_outlined,
                  value: storage.dataDirectory,
                  label: 'Data directory',
                ),
                _ProfileServerMetricCard(
                  cardKey: 'profile-server-storage-writable',
                  icon: Icons.edit_outlined,
                  value: storage.writable ? 'Writable' : 'Read only',
                  label: 'Access',
                ),
                _ProfileServerMetricCard(
                  cardKey: 'profile-server-storage-total',
                  icon: Icons.sd_storage_outlined,
                  value: _formatBytes(storage.totalSpaceBytes),
                  label: 'Total space',
                ),
                _ProfileServerMetricCard(
                  cardKey: 'profile-server-storage-used',
                  icon: Icons.pie_chart_outline_rounded,
                  value: _formatBytes(storage.usedSpaceBytes),
                  label: 'Used space',
                  detail: _formatPercentage(storage.usagePercentage),
                ),
                _ProfileServerMetricCard(
                  cardKey: 'profile-server-storage-free',
                  icon: Icons.space_bar_rounded,
                  value: _formatBytes(storage.freeSpaceBytes),
                  label: 'Free space',
                ),
              ],
            );
          },
        ),

        const SizedBox(height: AppSpacing.md),

        _ProfileServerImageCacheStatus(cache: storage.imageCache),
      ],
    );
  }
}

class _ProfileServerImageCacheStatus extends StatelessWidget {
  const _ProfileServerImageCacheStatus({required this.cache});

  final ServerImageCache cache;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('profile-server-image-cache'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Image cache',
          key: const ValueKey<String>('profile-server-image-cache-title'),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),

        const SizedBox(height: AppSpacing.sm),

        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool useFourColumns = constraints.maxWidth >= 720;

            return GridView.count(
              key: const ValueKey<String>('profile-server-image-cache-grid'),
              crossAxisCount: useFourColumns ? 4 : 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: useFourColumns ? 1.2 : 1.3,
              children: <Widget>[
                _ProfileServerMetricCard(
                  cardKey: 'profile-server-image-cache-total-size',
                  icon: Icons.photo_library_outlined,
                  value: _formatBytes(cache.totalSizeBytes),
                  label: 'Cache size',
                ),
                _ProfileServerMetricCard(
                  cardKey: 'profile-server-image-cache-total-files',
                  icon: Icons.insert_drive_file_outlined,
                  value: cache.totalFiles.toString(),
                  label: 'Files',
                ),
                _ProfileServerCacheCategoryCard(
                  cardKey: 'profile-server-image-cache-shows',
                  label: 'Shows',
                  category: cache.breakdown.shows,
                ),
                _ProfileServerCacheCategoryCard(
                  cardKey: 'profile-server-image-cache-seasons',
                  label: 'Seasons',
                  category: cache.breakdown.seasons,
                ),
                _ProfileServerCacheCategoryCard(
                  cardKey: 'profile-server-image-cache-episodes',
                  label: 'Episodes',
                  category: cache.breakdown.episodes,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ProfileServerCacheCategoryCard extends StatelessWidget {
  const _ProfileServerCacheCategoryCard({
    required this.cardKey,
    required this.label,
    required this.category,
  });

  final String cardKey;
  final String label;
  final ServerImageCacheCategory category;

  @override
  Widget build(BuildContext context) {
    return _ProfileServerMetricCard(
      cardKey: cardKey,
      icon: Icons.image_outlined,
      value: _formatBytes(category.sizeBytes),
      label: label,
      detail: '${category.files} files',
    );
  }
}

class _ProfileServerRuntimeStatus extends StatelessWidget {
  const _ProfileServerRuntimeStatus({required this.health});

  final ServerHealth health;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool useFourColumns = constraints.maxWidth >= 720;

        return GridView.count(
          key: const ValueKey<String>('profile-server-runtime-status'),
          crossAxisCount: useFourColumns ? 4 : 2,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: useFourColumns ? 1.2 : 1.3,
          children: <Widget>[
            _ProfileServerMetricCard(
              cardKey: 'profile-server-runtime-python',
              icon: Icons.code_rounded,
              value: health.runtime.pythonVersion,
              label: 'Python',
            ),
            _ProfileServerMetricCard(
              cardKey: 'profile-server-runtime-platform',
              icon: Icons.computer_outlined,
              value: health.runtime.platform,
              label: 'Platform',
            ),
            _ProfileServerMetricCard(
              cardKey: 'profile-server-runtime-uptime',
              icon: Icons.timer_outlined,
              value: _formatServerUptime(health.uptimeSeconds),
              label: 'Process uptime',
            ),
            _ProfileServerMetricCard(
              cardKey: 'profile-server-runtime-started-at',
              icon: Icons.play_circle_outline_rounded,
              value: _formatServerCheckedAt(health.runtime.startedAt),
              label: 'Started at',
            ),
            _ProfileServerMetricCard(
              cardKey: 'profile-server-runtime-current-time',
              icon: Icons.schedule_rounded,
              value: _formatServerCheckedAt(health.checkedAt),
              label: 'Server current time',
            ),
          ],
        );
      },
    );
  }
}

class _ProfileServerProvidersStatus extends StatelessWidget {
  const _ProfileServerProvidersStatus({required this.tmdb});

  final ServerTmdbHealth tmdb;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool useFourColumns = constraints.maxWidth >= 720;

        return GridView.count(
          key: const ValueKey<String>('profile-server-providers-status'),
          crossAxisCount: useFourColumns ? 4 : 2,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: useFourColumns ? 1.2 : 1.3,
          children: <Widget>[
            _ProfileServerMetricCard(
              cardKey: 'profile-server-provider-tmdb-configured',
              icon: Icons.settings_outlined,
              value: tmdb.configured ? 'Configured' : 'Not configured',
              label: 'TMDB configuration',
            ),
            _ProfileServerMetricCard(
              cardKey: 'profile-server-provider-tmdb-reachable',
              icon: Icons.cloud_done_outlined,
              value: tmdb.isHealthy ? 'Reachable' : 'Unavailable',
              label: 'TMDB connectivity',
            ),
            _ProfileServerMetricCard(
              cardKey: 'profile-server-provider-tmdb-latency',
              icon: Icons.speed_rounded,
              value: _formatServerLatency(tmdb.latencyMs) ?? 'Unavailable',
              label: 'TMDB latency',
            ),
          ],
        );
      },
    );
  }
}

class _ProfileServerDatabaseStatus extends StatelessWidget {
  const _ProfileServerDatabaseStatus({required this.database});

  final ServerDatabaseHealth database;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool useFourColumns = constraints.maxWidth >= 720;

        return Column(
          key: const ValueKey<String>('profile-server-database-status'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            GridView.count(
              key: const ValueKey<String>(
                'profile-server-database-status-grid',
              ),
              crossAxisCount: useFourColumns ? 4 : 2,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: useFourColumns ? 1.2 : 1.3,
              children: <Widget>[
                _ProfileServerMetricCard(
                  cardKey: 'profile-server-database-engine',
                  icon: Icons.dns_rounded,
                  value: _formatDatabaseEngine(database.engine),
                  label: 'Engine',
                ),
                _ProfileServerMetricCard(
                  cardKey: 'profile-server-database-size',
                  icon: Icons.data_usage_rounded,
                  value: _formatBytes(database.sizeBytes),
                  label: 'Database size',
                ),
                _ProfileServerMetricCard(
                  cardKey: 'profile-server-database-wal-size',
                  icon: Icons.article_outlined,
                  value: _formatBytes(database.walSizeBytes),
                  label: 'WAL size',
                ),
                _ProfileServerMetricCard(
                  cardKey: 'profile-server-database-connectivity',
                  icon: Icons.link_rounded,
                  value: _serverComponentStatusLabel(database.status),
                  label: 'Connectivity',
                  detail: _formatServerLatency(database.latencyMs),
                ),
                _ProfileServerMetricCard(
                  cardKey: 'profile-server-database-integrity',
                  icon: Icons.verified_outlined,
                  value: _serverDatabaseCheckStatusLabel(
                    database.integrityCheck,
                  ),
                  label: 'Integrity check',
                ),
                _ProfileServerMetricCard(
                  cardKey: 'profile-server-database-foreign-keys',
                  icon: Icons.account_tree_outlined,
                  value: _serverDatabaseCheckStatusLabel(
                    database.foreignKeyCheck,
                  ),
                  label: 'Foreign key check',
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),

            _ProfileServerMigrationCard(migration: database.migration),
          ],
        );
      },
    );
  }
}

class _ProfileServerMigrationCard extends StatelessWidget {
  const _ProfileServerMigrationCard({required this.migration});

  final ServerDatabaseMigration migration;

  @override
  Widget build(BuildContext context) {
    final String revision = migration.revision ?? 'Unavailable';
    final String? message = migration.message;

    return Container(
      key: const ValueKey<String>('profile-server-database-migration'),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.schema_outlined,
            size: 22,
            color: AppColors.textSecondary,
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  revision,
                  key: const ValueKey<String>(
                    'profile-server-database-migration-revision',
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  'Migration revision',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                if (message != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.xs),

                  Text(
                    message,
                    key: const ValueKey<String>(
                      'profile-server-database-migration-message',
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileServerLoading extends StatelessWidget {
  const _ProfileServerLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('profile-server-loading'),
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: AppRadius.borderLarge,
        border: Border.all(color: AppColors.outlineVariant),
      ),
    );
  }
}

String _serverHealthStatusLabel(ServerHealthStatus status) {
  return switch (status) {
    ServerHealthStatus.healthy => 'Healthy',
    ServerHealthStatus.degraded => 'Degraded',
    ServerHealthStatus.unavailable => 'Unavailable',
  };
}

String _serverComponentStatusLabel(ServerComponentStatus status) {
  return switch (status) {
    ServerComponentStatus.healthy => 'Healthy',
    ServerComponentStatus.unavailable => 'Unavailable',
  };
}

String _formatServerCheckedAt(DateTime value) {
  final DateTime local = value.toLocal();

  final String day = local.day.toString().padLeft(2, '0');
  final String month = local.month.toString().padLeft(2, '0');
  final String year = local.year.toString().padLeft(4, '0');

  final String hour = local.hour.toString().padLeft(2, '0');
  final String minute = local.minute.toString().padLeft(2, '0');

  return '$day/$month/$year · $hour:$minute';
}

String _formatServerUptime(int seconds) {
  final Duration duration = Duration(seconds: seconds);

  final int days = duration.inDays;
  final int hours = duration.inHours.remainder(24);
  final int minutes = duration.inMinutes.remainder(60);

  if (days > 0) {
    return hours > 0 ? '${days}d ${hours}h' : '${days}d';
  }

  if (hours > 0) {
    return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
  }

  if (minutes > 0) {
    return '${minutes}m';
  }

  return '${duration.inSeconds}s';
}

String? _formatServerLatency(double? latencyMs) {
  if (latencyMs == null) {
    return null;
  }

  final String formatted = latencyMs == latencyMs.roundToDouble()
      ? latencyMs.toStringAsFixed(0)
      : latencyMs.toStringAsFixed(1);

  return '$formatted ms';
}

String _serverTmdbDetail(ServerTmdbHealth tmdb) {
  if (!tmdb.configured) {
    return 'Not configured';
  }

  return _formatServerLatency(tmdb.latencyMs) ?? 'Configured';
}

String _formatProfileHistoryDate(DateTime value) {
  final DateTime local = value.toLocal();

  final String day = local.day.toString().padLeft(2, '0');
  final String month = local.month.toString().padLeft(2, '0');
  final String year = local.year.toString().padLeft(4, '0');

  final String hour = local.hour.toString().padLeft(2, '0');
  final String minute = local.minute.toString().padLeft(2, '0');

  return '$day/$month/$year · $hour:$minute';
}

String _serverDatabaseCheckStatusLabel(ServerDatabaseCheckStatus status) {
  return switch (status) {
    ServerDatabaseCheckStatus.ok => 'OK',
    ServerDatabaseCheckStatus.failed => 'Failed',
    ServerDatabaseCheckStatus.unavailable => 'Unavailable',
  };
}

String _formatDatabaseEngine(String engine) {
  return switch (engine.toLowerCase()) {
    'sqlite' => 'SQLite',
    _ => engine,
  };
}

String _formatBytes(int? bytes) {
  if (bytes == null) {
    return 'Unavailable';
  }

  const int kilobyte = 1024;
  const int megabyte = kilobyte * 1024;
  const int gigabyte = megabyte * 1024;

  if (bytes >= gigabyte) {
    return '${(bytes / gigabyte).toStringAsFixed(1)} GB';
  }

  if (bytes >= megabyte) {
    return '${(bytes / megabyte).toStringAsFixed(1)} MB';
  }

  if (bytes >= kilobyte) {
    return '${(bytes / kilobyte).toStringAsFixed(1)} KB';
  }

  return '$bytes B';
}

String _formatPercentage(double? value) {
  if (value == null) {
    return 'Unavailable';
  }

  final String formatted = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);

  return '$formatted%';
}
