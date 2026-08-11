import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_season_state.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_seasons_cubit.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_episode.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_local_season.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_season.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_season_progress.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_seasons_bootstrap.dart';
import 'package:sofawatch/features/show_details/domain/repositories/show_details_seasons_repository.dart';
import 'package:sofawatch/features/show_details/presentation/widgets/show_details_seasons_section.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_episode_progress.dart';
import 'package:sofawatch/core/errors/app_exception.dart';

void main() {
  group('ShowDetailsSeasonsSection', () {
    testWidgets('shows progress before the Season is expanded', (
      WidgetTester tester,
    ) async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository();

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.loadInitialProgress();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          seasons: const <ShowDetailsSeason>[_seasonOne],
        ),
      );

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('show-details-season-progress-1')),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('show-details-season-progress-label-1'),
        ),
        findsOneWidget,
      );

      expect(find.text('1 / 2 aired episodes'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('show-details-season-episodes-1')),
        findsNothing,
      );

      await cubit.close();
    });

    testWidgets('uses aired progress percentage in the progress bar', (
      WidgetTester tester,
    ) async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository();

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.loadInitialProgress();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          seasons: const <ShowDetailsSeason>[_seasonOne],
        ),
      );

      await tester.pump();

      final LinearProgressIndicator indicator = tester.widget(
        find.byKey(const ValueKey<String>('show-details-season-progress-1')),
      );

      expect(indicator.value, 0.5);

      await cubit.close();
    });

    testWidgets('shows caught up icon before the Season is expanded', (
      WidgetTester tester,
    ) async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository();

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.loadInitialProgress();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          seasons: const <ShowDetailsSeason>[_seasonTwo],
        ),
      );

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('show-details-season-caught-up-2')),
        findsOneWidget,
      );

      expect(find.text('1 / 1 aired episodes'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('show-details-season-episodes-2')),
        findsNothing,
      );

      await cubit.close();
    });

    testWidgets('does not show a progress bar when no Episodes have aired', (
      WidgetTester tester,
    ) async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository(
            progressItems: const <ShowDetailsSeasonProgress>[
              ShowDetailsSeasonProgress(
                seasonId: 'season-1-uuid',
                watchedEpisodes: 0,
                totalEpisodes: 10,
                progressPercentage: 0,
                airedEpisodes: 0,
                watchedAiredEpisodes: 0,
                airedProgressPercentage: 0,
                caughtUp: false,
              ),
            ],
          );

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.loadInitialProgress();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          seasons: const <ShowDetailsSeason>[_seasonWithTenEpisodes],
        ),
      );

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('show-details-season-progress-1')),
        findsNothing,
      );

      expect(find.text('10 Episodes'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('keeps progress visible after expanding the Season', (
      WidgetTester tester,
    ) async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository();

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.loadInitialProgress();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          seasons: const <ShowDetailsSeason>[_seasonOne],
        ),
      );

      await tester.pump();

      await tester.tap(
        find.byKey(const ValueKey<String>('show-details-season-toggle-1')),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('show-details-season-progress-1')),
        findsOneWidget,
      );

      expect(find.text('1 / 2 aired episodes'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('show-details-season-episodes-1')),
        findsOneWidget,
      );

      await cubit.close();
    });
    testWidgets('shows watched state and watched date for Episodes', (
      WidgetTester tester,
    ) async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository();

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<ShowDetailsSeasonsCubit>.value(
              value: cubit,
              child: const ShowDetailsSeasonsSection(
                seasons: <ShowDetailsSeason>[
                  ShowDetailsSeason(
                    tmdbId: 134792,
                    seasonNumber: 1,
                    title: 'Season 1',
                    episodeCount: 2,
                    voteAverage: 8.0,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('show-details-season-toggle-1')),
      );

      await tester.pumpAndSettle();

      final IconButton watchedButton = tester.widget<IconButton>(
        find.byKey(
          const ValueKey<String>('show-details-episode-watched-episode-1-uuid'),
        ),
      );

      expect(watchedButton.tooltip, 'Mark as not watched');

      final Icon watchedIcon = watchedButton.icon as Icon;
      expect(watchedIcon.icon, Icons.check_circle_rounded);

      expect(
        find.byKey(
          const ValueKey<String>(
            'show-details-episode-watched-date-episode-1-uuid',
          ),
        ),
        findsOneWidget,
      );

      final IconButton unwatchedButton = tester.widget<IconButton>(
        find.byKey(
          const ValueKey<String>('show-details-episode-watched-episode-2-uuid'),
        ),
      );

      expect(unwatchedButton.tooltip, 'Mark as watched');

      final Icon unwatchedIcon = unwatchedButton.icon as Icon;
      expect(unwatchedIcon.icon, Icons.radio_button_unchecked_rounded);

      expect(
        find.byKey(
          const ValueKey<String>(
            'show-details-episode-watched-date-episode-2-uuid',
          ),
        ),
        findsNothing,
      );

      await cubit.close();
    });
    testWidgets('shows Retry when updating Episode watched state fails', (
      WidgetTester tester,
    ) async {
      final _RetryEpisodeUpdateRepository repository =
          _RetryEpisodeUpdateRepository();

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          seasons: const <ShowDetailsSeason>[_seasonOne],
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('show-details-season-toggle-1')),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey<String>('show-details-episode-watched-episode-2-uuid'),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(repository.markWatchedCalls, 1);

      expect(
        find.byKey(
          const ValueKey<String>(
            'show-details-episode-update-failure-episode-2-uuid',
          ),
        ),
        findsOneWidget,
      );

      expect(
        find.text('Could not update this episode. Please try again.'),
        findsOneWidget,
      );

      expect(find.text('Retry'), findsOneWidget);

      // The failed request must not falsely mark the Episode as watched.
      final IconButton failedButton = tester.widget<IconButton>(
        find.byKey(
          const ValueKey<String>('show-details-episode-watched-episode-2-uuid'),
        ),
      );

      expect(
        (failedButton.icon as Icon).icon,
        Icons.radio_button_unchecked_rounded,
      );

      await cubit.close();
    });
    testWidgets('Retry repeats failed Episode watched update', (
      WidgetTester tester,
    ) async {
      final _RetryEpisodeUpdateRepository repository =
          _RetryEpisodeUpdateRepository();

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          seasons: const <ShowDetailsSeason>[_seasonOne],
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('show-details-season-toggle-1')),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey<String>('show-details-episode-watched-episode-2-uuid'),
        ),
      );

      await tester.pumpAndSettle();

      expect(repository.markWatchedCalls, 1);

      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));

      await tester.pumpAndSettle();

      expect(repository.markWatchedCalls, 2);

      final IconButton watchedButton = tester.widget<IconButton>(
        find.byKey(
          const ValueKey<String>('show-details-episode-watched-episode-2-uuid'),
        ),
      );

      expect((watchedButton.icon as Icon).icon, Icons.check_circle_rounded);

      expect(watchedButton.tooltip, 'Mark as not watched');

      expect(
        find.byKey(
          const ValueKey<String>(
            'show-details-episode-watched-date-episode-2-uuid',
          ),
        ),
        findsOneWidget,
      );

      await cubit.close();
    });
    testWidgets(
      'disables watched action for an Episode that has not aired yet',
      (WidgetTester tester) async {
        final _UpcomingEpisodeRepository repository =
            _UpcomingEpisodeRepository();

        final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
          repository: repository,
          showTmdbId: 95396,
        );

        await tester.pumpWidget(
          _buildTestApp(
            cubit: cubit,
            seasons: const <ShowDetailsSeason>[_seasonOne],
          ),
        );

        await tester.tap(
          find.byKey(const ValueKey<String>('show-details-season-toggle-1')),
        );

        await tester.pumpAndSettle();

        final IconButton button = tester.widget<IconButton>(
          find.byKey(
            const ValueKey<String>(
              'show-details-episode-watched-episode-upcoming-uuid',
            ),
          ),
        );

        expect(button.onPressed, isNull);
        expect(button.tooltip, 'Not released yet');

        expect((button.icon as Icon).icon, Icons.schedule_rounded);

        expect(find.textContaining('Upcoming'), findsOneWidget);

        await cubit.close();
      },
    );
    testWidgets('shows Watched again for a watched Episode and rewatches it', (
      WidgetTester tester,
    ) async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository();

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          seasons: const <ShowDetailsSeason>[_seasonOne],
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('show-details-season-toggle-1')),
      );

      await tester.pumpAndSettle();

      final ShowDetailsEpisodeProgress initialProgress =
          cubit.state[1]!.episodeProgressById['episode-1-uuid']!;

      expect(initialProgress.isWatched, isTrue);

      expect(initialProgress.watchedAt, DateTime.utc(2026, 8, 10, 12));

      final Finder rewatchFinder = find.byKey(
        const ValueKey<String>('show-details-episode-rewatch-episode-1-uuid'),
      );

      expect(rewatchFinder, findsOneWidget);

      final IconButton rewatchButton = tester.widget<IconButton>(rewatchFinder);

      expect(rewatchButton.onPressed, isNotNull);
      expect(rewatchButton.tooltip, 'Watched again');

      expect((rewatchButton.icon as Icon).icon, Icons.replay_rounded);

      /*
     * An unwatched Episode must not expose the rewatch action.
     */
      expect(
        find.byKey(
          const ValueKey<String>('show-details-episode-rewatch-episode-2-uuid'),
        ),
        findsNothing,
      );

      await tester.tap(rewatchFinder);

      await tester.pumpAndSettle();

      final ShowDetailsEpisodeProgress rewatchedProgress =
          cubit.state[1]!.episodeProgressById['episode-1-uuid']!;

      expect(rewatchedProgress.isWatched, isTrue);

      expect(rewatchedProgress.watchedAt, DateTime.utc(2026, 8, 11));

      expect(rewatchedProgress.watchedAt, isNot(initialProgress.watchedAt));

      /*
     * Rewatch must not make the Episode unwatched or remove its actions.
     */
      expect(
        find.byKey(
          const ValueKey<String>('show-details-episode-watched-episode-1-uuid'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('show-details-episode-rewatch-episode-1-uuid'),
        ),
        findsOneWidget,
      );

      await cubit.close();
    });
  });
}

Widget _buildTestApp({
  required ShowDetailsSeasonsCubit cubit,
  required List<ShowDetailsSeason> seasons,
}) {
  return MaterialApp(
    home: Scaffold(
      body: BlocProvider<ShowDetailsSeasonsCubit>.value(
        value: cubit,
        child: ShowDetailsSeasonsSection(seasons: seasons),
      ),
    ),
  );
}

const ShowDetailsSeason _seasonOne = ShowDetailsSeason(
  tmdbId: 134792,
  seasonNumber: 1,
  title: 'Season 1',
  episodeCount: 2,
  voteAverage: 8.4,
);

const ShowDetailsSeason _seasonTwo = ShowDetailsSeason(
  tmdbId: 368201,
  seasonNumber: 2,
  title: 'Season 2',
  episodeCount: 1,
  voteAverage: 8.7,
);

const ShowDetailsSeason _seasonWithTenEpisodes = ShowDetailsSeason(
  tmdbId: 134792,
  seasonNumber: 1,
  title: 'Season 1',
  episodeCount: 10,
  voteAverage: 8.4,
);

const ShowDetailsEpisode _episodeOne = ShowDetailsEpisode(
  id: 'episode-1-uuid',
  tmdbId: 1947647,
  episodeNumber: 1,
  title: 'Good News About Hell',
  overview: 'Episode one.',
  runtime: 57,
  voteAverage: 8.1,
  voteCount: 42,
);

const ShowDetailsEpisode _episodeTwo = ShowDetailsEpisode(
  id: 'episode-2-uuid',
  tmdbId: 1947648,
  episodeNumber: 2,
  title: 'Half Loop',
  overview: 'Episode two.',
  runtime: 54,
  voteAverage: 8.2,
  voteCount: 38,
);

const ShowDetailsEpisode _episodeThree = ShowDetailsEpisode(
  id: 'episode-3-uuid',
  tmdbId: 3000001,
  episodeNumber: 1,
  title: 'Season Two Premiere',
  overview: 'Season two begins.',
  runtime: 55,
  voteAverage: 8.5,
  voteCount: 25,
);

final ShowDetailsEpisode _upcomingEpisode = ShowDetailsEpisode(
  id: 'episode-upcoming-uuid',
  tmdbId: 9999999,
  episodeNumber: 3,
  title: 'Future Episode',
  airDate: DateTime(2099, 1, 1),
  runtime: 55,
  voteAverage: 0,
  voteCount: 0,
);

final class _UpcomingEpisodeRepository
    extends _FakeShowDetailsSeasonsRepository {
  @override
  Future<List<ShowDetailsEpisode>> getEpisodes({
    required String seasonId,
  }) async {
    if (seasonId == 'season-1-uuid') {
      return <ShowDetailsEpisode>[_episodeOne, _upcomingEpisode];
    }

    return super.getEpisodes(seasonId: seasonId);
  }
}

final class _FakeShowDetailsSeasonsRepository
    implements ShowDetailsSeasonsRepository {
  _FakeShowDetailsSeasonsRepository({
    this.progressItems = const <ShowDetailsSeasonProgress>[
      ShowDetailsSeasonProgress(
        seasonId: 'season-1-uuid',
        watchedEpisodes: 1,
        totalEpisodes: 2,
        progressPercentage: 50,
        airedEpisodes: 2,
        watchedAiredEpisodes: 1,
        airedProgressPercentage: 50,
        caughtUp: false,
      ),
      ShowDetailsSeasonProgress(
        seasonId: 'season-2-uuid',
        watchedEpisodes: 1,
        totalEpisodes: 1,
        progressPercentage: 100,
        airedEpisodes: 1,
        watchedAiredEpisodes: 1,
        airedProgressPercentage: 100,
        caughtUp: true,
      ),
    ],
  });

  final List<ShowDetailsSeasonProgress> progressItems;

  @override
  Future<ShowDetailsSeasonsBootstrap> resolveLocalSeasons({
    required int showTmdbId,
  }) async {
    return const ShowDetailsSeasonsBootstrap(
      showId: 'show-uuid',
      seasons: <ShowDetailsLocalSeason>[
        ShowDetailsLocalSeason(
          id: 'season-1-uuid',
          tmdbId: 134792,
          seasonNumber: 1,
        ),
        ShowDetailsLocalSeason(
          id: 'season-2-uuid',
          tmdbId: 368201,
          seasonNumber: 2,
        ),
      ],
    );
  }

  @override
  Future<List<ShowDetailsSeasonProgress>> getSeasonsProgress({
    required String showId,
  }) async {
    return progressItems;
  }

  @override
  Future<List<ShowDetailsEpisode>> getEpisodes({
    required String seasonId,
  }) async {
    return switch (seasonId) {
      'season-1-uuid' => const <ShowDetailsEpisode>[_episodeOne, _episodeTwo],
      'season-2-uuid' => const <ShowDetailsEpisode>[_episodeThree],
      _ => const <ShowDetailsEpisode>[],
    };
  }

  @override
  Future<List<ShowDetailsEpisodeProgress>> getEpisodeProgress({
    required String seasonId,
  }) async {
    return switch (seasonId) {
      'season-1-uuid' => <ShowDetailsEpisodeProgress>[
        ShowDetailsEpisodeProgress(
          id: 'progress-1-uuid',
          episodeId: 'episode-1-uuid',
          isWatched: true,
          watchedAt: DateTime.utc(2026, 8, 10, 12),
        ),
      ],
      _ => const <ShowDetailsEpisodeProgress>[],
    };
  }

  @override
  Future<ShowDetailsEpisodeProgress> markEpisodeWatched({
    required String episodeId,
    DateTime? watchedAt,
  }) async {
    return ShowDetailsEpisodeProgress(
      id: 'progress-$episodeId',
      episodeId: episodeId,
      isWatched: true,
      watchedAt: watchedAt ?? DateTime.utc(2026, 8, 11),
    );
  }

  @override
  Future<ShowDetailsEpisodeProgress> markEpisodeUnwatched({
    required String episodeId,
  }) async {
    return ShowDetailsEpisodeProgress(
      id: 'progress-$episodeId',
      episodeId: episodeId,
      isWatched: false,
    );
  }

  @override
  Future<List<ShowDetailsEpisode>> syncEpisodes({
    required String seasonId,
  }) async {
    return switch (seasonId) {
      'season-1-uuid' => const <ShowDetailsEpisode>[_episodeOne, _episodeTwo],
      'season-2-uuid' => const <ShowDetailsEpisode>[_episodeThree],
      _ => const <ShowDetailsEpisode>[],
    };
  }

  @override
  Future<ShowDetailsSeasonProgress> getSeasonProgress({
    required String seasonId,
  }) async {
    for (final ShowDetailsSeasonProgress progress in progressItems) {
      if (progress.seasonId == seasonId) {
        return progress;
      }
    }

    return ShowDetailsSeasonProgress(
      seasonId: seasonId,
      watchedEpisodes: 0,
      totalEpisodes: 0,
      progressPercentage: 0,
      airedEpisodes: 0,
      watchedAiredEpisodes: 0,
      airedProgressPercentage: 0,
      caughtUp: false,
    );
  }
}

final class _RetryEpisodeUpdateRepository
    extends _FakeShowDetailsSeasonsRepository {
  int markWatchedCalls = 0;

  @override
  Future<ShowDetailsEpisodeProgress> markEpisodeWatched({
    required String episodeId,
    DateTime? watchedAt,
  }) async {
    markWatchedCalls++;

    if (markWatchedCalls == 1) {
      throw const AppException.connection();
    }

    return ShowDetailsEpisodeProgress(
      id: 'progress-$episodeId',
      episodeId: episodeId,
      isWatched: true,
      watchedAt: DateTime.utc(2026, 8, 11),
    );
  }
}
