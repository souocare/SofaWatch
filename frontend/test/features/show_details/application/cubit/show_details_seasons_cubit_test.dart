import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_season_operation.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_season_state.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_seasons_cubit.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_episode.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_local_season.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_season_progress.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_seasons_bootstrap.dart';
import 'package:sofawatch/features/show_details/domain/repositories/show_details_seasons_repository.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_episode_progress.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_episode_operation.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_episode_watch_event.dart';

void main() {
  group('ShowDetailsSeasonsCubit', () {
    test('starts with no Season state', () async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository();

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      expect(cubit.state, isEmpty);

      await cubit.close();
    });

    test('loads progress for all Seasons without loading Episodes', () async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository();

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.loadInitialProgress();

      expect(repository.resolveLocalSeasonsCalls, 1);
      expect(repository.getSeasonsProgressCalls, 1);

      expect(repository.getEpisodesCalls, 0);
      expect(repository.syncEpisodesCalls, 0);
      expect(repository.getSeasonProgressCalls, 0);

      expect(repository.requestedShowTmdbIds, <int>[95396]);

      expect(repository.requestedProgressShowIds, <String>['show-uuid']);

      final ShowDetailsSeasonState? firstSeason = cubit.state[1];
      final ShowDetailsSeasonState? secondSeason = cubit.state[2];

      expect(firstSeason, isNotNull);
      expect(secondSeason, isNotNull);

      expect(firstSeason!.isExpanded, isFalse);
      expect(firstSeason.isLoading, isFalse);
      expect(firstSeason.hasLoadedEpisodes, isFalse);
      expect(firstSeason.isLoaded, isFalse);
      expect(firstSeason.episodes, isEmpty);

      expect(
        firstSeason.progress,
        const ShowDetailsSeasonProgress(
          seasonId: 'season-1-uuid',
          watchedEpisodes: 1,
          totalEpisodes: 2,
          progressPercentage: 50,
          airedEpisodes: 2,
          watchedAiredEpisodes: 1,
          airedProgressPercentage: 50,
          caughtUp: false,
        ),
      );

      expect(secondSeason!.isExpanded, isFalse);
      expect(secondSeason.hasLoadedEpisodes, isFalse);
      expect(secondSeason.isLoaded, isFalse);
      expect(secondSeason.episodes, isEmpty);

      expect(
        secondSeason.progress,
        const ShowDetailsSeasonProgress(
          seasonId: 'season-2-uuid',
          watchedEpisodes: 1,
          totalEpisodes: 1,
          progressPercentage: 100,
          airedEpisodes: 1,
          watchedAiredEpisodes: 1,
          airedProgressPercentage: 100,
          caughtUp: true,
        ),
      );

      await cubit.close();
    });

    test(
      'progress loaded at startup does not mark Episodes as loaded',
      () async {
        final _FakeShowDetailsSeasonsRepository repository =
            _FakeShowDetailsSeasonsRepository();

        final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
          repository: repository,
          showTmdbId: 95396,
        );

        await cubit.loadInitialProgress();

        expect(cubit.state[1]?.progress, isNotNull);
        expect(cubit.state[1]?.hasLoadedEpisodes, isFalse);
        expect(cubit.state[1]?.isLoaded, isFalse);

        await cubit.toggleSeason(1);

        expect(repository.getEpisodesCalls, 1);

        expect(cubit.state[1]?.isExpanded, isTrue);
        expect(cubit.state[1]?.hasLoadedEpisodes, isTrue);
        expect(cubit.state[1]?.isLoaded, isTrue);

        expect(cubit.state[1]?.episodes, <ShowDetailsEpisode>[
          _episodeOne,
          _episodeTwo,
        ]);

        await cubit.close();
      },
    );

    test(
      'reuses resolved local Seasons after loading initial progress',
      () async {
        final _FakeShowDetailsSeasonsRepository repository =
            _FakeShowDetailsSeasonsRepository();

        final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
          repository: repository,
          showTmdbId: 95396,
        );

        await cubit.loadInitialProgress();

        expect(repository.resolveLocalSeasonsCalls, 1);

        await cubit.toggleSeason(1);

        expect(repository.resolveLocalSeasonsCalls, 1);

        await cubit.toggleSeason(2);

        expect(repository.resolveLocalSeasonsCalls, 1);

        await cubit.close();
      },
    );

    test(
      'preserves initial progress while a Season starts loading Episodes',
      () async {
        final _FakeShowDetailsSeasonsRepository repository =
            _FakeShowDetailsSeasonsRepository();

        final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
          repository: repository,
          showTmdbId: 95396,
        );

        await cubit.loadInitialProgress();

        final ShowDetailsSeasonProgress? initialProgress =
            cubit.state[1]?.progress;

        expect(initialProgress, isNotNull);

        await cubit.toggleSeason(1);

        expect(cubit.state[1]?.progress, initialProgress);

        expect(cubit.state[1]?.episodes, <ShowDetailsEpisode>[
          _episodeOne,
          _episodeTwo,
        ]);

        await cubit.close();
      },
    );

    test('ignores initial progress failure without blocking Seasons', () async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository(failBatchProgress: true);

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.loadInitialProgress();

      expect(repository.resolveLocalSeasonsCalls, 1);
      expect(repository.getSeasonsProgressCalls, 1);

      expect(cubit.state, isEmpty);

      await cubit.toggleSeason(1);

      expect(cubit.state[1]?.hasError, isFalse);
      expect(cubit.state[1]?.isExpanded, isTrue);

      expect(cubit.state[1]?.episodes, <ShowDetailsEpisode>[
        _episodeOne,
        _episodeTwo,
      ]);

      await cubit.close();
    });

    test(
      'ignores progress entries that do not belong to resolved Seasons',
      () async {
        final _FakeShowDetailsSeasonsRepository repository =
            _FakeShowDetailsSeasonsRepository(
              batchProgress: const <ShowDetailsSeasonProgress>[
                ShowDetailsSeasonProgress(
                  seasonId: 'unknown-season-uuid',
                  watchedEpisodes: 2,
                  totalEpisodes: 2,
                  progressPercentage: 100,
                  airedEpisodes: 2,
                  watchedAiredEpisodes: 2,
                  airedProgressPercentage: 100,
                  caughtUp: true,
                ),
              ],
            );

        final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
          repository: repository,
          showTmdbId: 95396,
        );

        await cubit.loadInitialProgress();

        expect(cubit.state, isEmpty);

        await cubit.close();
      },
    );

    test('expands and loads a Season with Episodes and progress', () async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository();

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.toggleSeason(1);

      final ShowDetailsSeasonState? seasonState = cubit.state[1];

      expect(seasonState, isNotNull);
      expect(seasonState!.isExpanded, isTrue);
      expect(seasonState.isLoading, isFalse);
      expect(seasonState.hasError, isFalse);
      expect(seasonState.hasLoadedEpisodes, isTrue);

      expect(seasonState.episodes, <ShowDetailsEpisode>[
        _episodeOne,
        _episodeTwo,
      ]);

      expect(
        seasonState.progress,
        const ShowDetailsSeasonProgress(
          seasonId: 'season-1-uuid',
          watchedEpisodes: 1,
          totalEpisodes: 2,
          progressPercentage: 50,
          airedEpisodes: 2,
          watchedAiredEpisodes: 1,
          airedProgressPercentage: 50,
          caughtUp: false,
        ),
      );

      expect(repository.resolveLocalSeasonsCalls, 1);
      expect(repository.getEpisodesCalls, 1);
      expect(repository.syncEpisodesCalls, 0);
      expect(repository.getSeasonProgressCalls, 1);

      expect(repository.requestedShowTmdbIds, <int>[95396]);

      expect(repository.requestedSeasonIds, <String>['season-1-uuid']);

      expect(repository.requestedSyncSeasonIds, isEmpty);

      expect(repository.requestedProgressSeasonIds, <String>['season-1-uuid']);

      await cubit.close();
    });

    test(
      'uses local Episodes without synchronizing when they already exist',
      () async {
        final _FakeShowDetailsSeasonsRepository repository =
            _FakeShowDetailsSeasonsRepository();

        final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
          repository: repository,
          showTmdbId: 95396,
        );

        await cubit.toggleSeason(1);

        expect(cubit.state[1]?.episodes, <ShowDetailsEpisode>[
          _episodeOne,
          _episodeTwo,
        ]);

        expect(repository.getEpisodesCalls, 1);
        expect(repository.syncEpisodesCalls, 0);

        expect(repository.requestedSeasonIds, <String>['season-1-uuid']);

        expect(repository.requestedSyncSeasonIds, isEmpty);

        await cubit.close();
      },
    );

    test('synchronizes Episodes when the local Season is empty', () async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository(
            emptyLocalSeasonIds: <String>{'season-1-uuid'},
          );

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.toggleSeason(1);

      expect(repository.getEpisodesCalls, 1);
      expect(repository.syncEpisodesCalls, 1);
      expect(repository.getSeasonProgressCalls, 1);

      expect(repository.requestedSyncSeasonIds, <String>['season-1-uuid']);

      expect(cubit.state[1]?.episodes, <ShowDetailsEpisode>[
        _episodeOne,
        _episodeTwo,
      ]);

      expect(
        cubit.state[1]?.progress,
        const ShowDetailsSeasonProgress(
          seasonId: 'season-1-uuid',
          watchedEpisodes: 1,
          totalEpisodes: 2,
          progressPercentage: 50,
          airedEpisodes: 2,
          watchedAiredEpisodes: 1,
          airedProgressPercentage: 50,
          caughtUp: false,
        ),
      );

      await cubit.close();
    });

    test('collapses an expanded Season without another request', () async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository();

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.toggleSeason(1);

      expect(cubit.state[1]?.isExpanded, isTrue);

      await cubit.toggleSeason(1);

      expect(cubit.state[1]?.isExpanded, isFalse);

      expect(repository.resolveLocalSeasonsCalls, 1);
      expect(repository.getEpisodesCalls, 1);
      expect(repository.syncEpisodesCalls, 0);
      expect(repository.getSeasonProgressCalls, 1);

      await cubit.close();
    });

    test(
      're-expands an already loaded Season without reloading Episodes or progress',
      () async {
        final _FakeShowDetailsSeasonsRepository repository =
            _FakeShowDetailsSeasonsRepository();

        final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
          repository: repository,
          showTmdbId: 95396,
        );

        await cubit.toggleSeason(1);
        await cubit.toggleSeason(1);
        await cubit.toggleSeason(1);

        expect(cubit.state[1]?.isExpanded, isTrue);

        expect(cubit.state[1]?.episodes, <ShowDetailsEpisode>[
          _episodeOne,
          _episodeTwo,
        ]);

        expect(cubit.state[1]?.progress?.airedProgressPercentage, 50);

        expect(repository.resolveLocalSeasonsCalls, 1);
        expect(repository.getEpisodesCalls, 1);
        expect(repository.syncEpisodesCalls, 0);
        expect(repository.getSeasonProgressCalls, 1);

        await cubit.close();
      },
    );

    test('resolves local Seasons only once across multiple Seasons', () async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository();

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.toggleSeason(1);
      await cubit.toggleSeason(2);

      expect(repository.resolveLocalSeasonsCalls, 1);
      expect(repository.getEpisodesCalls, 2);
      expect(repository.syncEpisodesCalls, 0);
      expect(repository.getSeasonProgressCalls, 2);

      expect(repository.requestedSeasonIds, <String>[
        'season-1-uuid',
        'season-2-uuid',
      ]);

      expect(repository.requestedProgressSeasonIds, <String>[
        'season-1-uuid',
        'season-2-uuid',
      ]);

      expect(cubit.state[1]?.isExpanded, isTrue);

      expect(cubit.state[2]?.isExpanded, isTrue);

      expect(cubit.state[2]?.progress?.caughtUp, isTrue);

      await cubit.close();
    });

    test('keeps independent state for each Season', () async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository();

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.toggleSeason(1);
      await cubit.toggleSeason(2);
      await cubit.toggleSeason(1);

      expect(cubit.state[1]?.isExpanded, isFalse);

      expect(cubit.state[2]?.isExpanded, isTrue);

      expect(cubit.state[1]?.episodes, isNotEmpty);

      expect(cubit.state[2]?.episodes, isNotEmpty);

      expect(cubit.state[1]?.progress, isNotNull);

      expect(cubit.state[2]?.progress, isNotNull);

      await cubit.close();
    });

    test(
      'stores Episode loading failure only for the affected Season',
      () async {
        final _FakeShowDetailsSeasonsRepository repository =
            _FakeShowDetailsSeasonsRepository(failingSeasonId: 'season-2-uuid');

        final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
          repository: repository,
          showTmdbId: 95396,
        );

        await cubit.toggleSeason(1);
        await cubit.toggleSeason(2);

        expect(cubit.state[1]?.hasError, isFalse);

        expect(cubit.state[1]?.episodes, isNotEmpty);

        expect(cubit.state[2]?.isExpanded, isTrue);

        expect(cubit.state[2]?.isLoading, isFalse);

        expect(cubit.state[2]?.hasError, isTrue);

        expect(cubit.state[2]?.error?.type, AppExceptionType.connection);

        await cubit.close();
      },
    );

    test('stores Episode sync failure only for the affected Season', () async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository(
            emptyLocalSeasonIds: <String>{'season-2-uuid'},
            failingSyncSeasonId: 'season-2-uuid',
          );

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.toggleSeason(1);
      await cubit.toggleSeason(2);

      expect(cubit.state[1]?.hasError, isFalse);

      expect(cubit.state[2]?.isExpanded, isTrue);

      expect(cubit.state[2]?.isLoading, isFalse);

      expect(cubit.state[2]?.hasError, isTrue);

      expect(cubit.state[2]?.error?.type, AppExceptionType.connection);

      expect(repository.syncEpisodesCalls, 1);

      await cubit.close();
    });

    test(
      'stores progress loading failure only for the affected Season',
      () async {
        final _FakeShowDetailsSeasonsRepository repository =
            _FakeShowDetailsSeasonsRepository(
              failingProgressSeasonId: 'season-2-uuid',
            );

        final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
          repository: repository,
          showTmdbId: 95396,
        );

        await cubit.toggleSeason(1);
        await cubit.toggleSeason(2);

        expect(cubit.state[1]?.hasError, isFalse);

        expect(cubit.state[2]?.isExpanded, isTrue);

        expect(cubit.state[2]?.isLoading, isFalse);

        expect(cubit.state[2]?.hasError, isTrue);

        expect(cubit.state[2]?.error?.type, AppExceptionType.connection);

        await cubit.close();
      },
    );

    test('retry reloads only the failed Season', () async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository(failingSeasonId: 'season-2-uuid');

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.toggleSeason(2);

      expect(cubit.state[2]?.hasError, isTrue);

      repository.failingSeasonId = null;

      await cubit.retrySeason(2);

      expect(cubit.state[2]?.hasError, isFalse);

      expect(cubit.state[2]?.episodes, <ShowDetailsEpisode>[_episodeThree]);

      expect(
        cubit.state[2]?.progress,
        const ShowDetailsSeasonProgress(
          seasonId: 'season-2-uuid',
          watchedEpisodes: 1,
          totalEpisodes: 1,
          progressPercentage: 100,
          airedEpisodes: 1,
          watchedAiredEpisodes: 1,
          airedProgressPercentage: 100,
          caughtUp: true,
        ),
      );

      expect(repository.resolveLocalSeasonsCalls, 1);

      expect(repository.getEpisodesCalls, 2);

      expect(repository.syncEpisodesCalls, 0);

      await cubit.close();
    });

    test('retry reloads a failed initial Episode sync', () async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository(
            emptyLocalSeasonIds: <String>{'season-2-uuid'},
            failingSyncSeasonId: 'season-2-uuid',
          );

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.toggleSeason(2);

      expect(cubit.state[2]?.hasError, isTrue);

      repository.failingSyncSeasonId = null;

      await cubit.retrySeason(2);

      expect(cubit.state[2]?.hasError, isFalse);

      expect(cubit.state[2]?.episodes, <ShowDetailsEpisode>[_episodeThree]);

      expect(repository.getEpisodesCalls, 2);

      expect(repository.syncEpisodesCalls, 2);

      await cubit.close();
    });

    test('retry reloads progress after a progress failure', () async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository(
            failingProgressSeasonId: 'season-2-uuid',
          );

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.toggleSeason(2);

      expect(cubit.state[2]?.hasError, isTrue);

      repository.failingProgressSeasonId = null;

      await cubit.retrySeason(2);

      expect(cubit.state[2]?.hasError, isFalse);

      expect(cubit.state[2]?.progress?.caughtUp, isTrue);

      expect(repository.getSeasonProgressCalls, 2);

      await cubit.close();
    });

    test('fails when local Season cannot be resolved', () async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository(
            localSeasons: const <ShowDetailsLocalSeason>[
              ShowDetailsLocalSeason(
                id: 'season-1-uuid',
                tmdbId: 134792,
                seasonNumber: 1,
              ),
            ],
          );

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.toggleSeason(99);

      expect(cubit.state[99]?.isExpanded, isTrue);

      expect(cubit.state[99]?.hasError, isTrue);

      expect(cubit.state[99]?.episodes, isEmpty);

      expect(cubit.state[99]?.progress, isNull);

      expect(repository.getEpisodesCalls, 0);

      expect(repository.syncEpisodesCalls, 0);

      expect(repository.getSeasonProgressCalls, 0);

      await cubit.close();
    });

    test(
      'loading one Season preserves the state and progress of other Seasons',
      () async {
        final _ControlledShowDetailsSeasonsRepository repository =
            _ControlledShowDetailsSeasonsRepository();

        final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
          repository: repository,
          showTmdbId: 95396,
        );

        await cubit.loadInitialProgress();

        expect(cubit.state[1]?.progress, isNotNull);
        expect(cubit.state[2]?.progress, isNotNull);

        final Future<void> loadSeasonOne = cubit.toggleSeason(1);

        await repository.seasonOneEpisodesRequested.future;

        expect(cubit.state[1]?.isExpanded, isTrue);
        expect(cubit.state[1]?.isLoading, isTrue);

        expect(cubit.state[2]?.isExpanded, isFalse);
        expect(cubit.state[2]?.isLoading, isFalse);

        expect(
          cubit.state[2]?.progress,
          const ShowDetailsSeasonProgress(
            seasonId: 'season-2-uuid',
            watchedEpisodes: 1,
            totalEpisodes: 1,
            progressPercentage: 100,
            airedEpisodes: 1,
            watchedAiredEpisodes: 1,
            airedProgressPercentage: 100,
            caughtUp: true,
          ),
        );

        repository.completeSeasonOneEpisodes();

        await loadSeasonOne;

        expect(cubit.state[1]?.isLoading, isFalse);
        expect(cubit.state[1]?.hasLoadedEpisodes, isTrue);

        expect(cubit.state[2]?.isLoading, isFalse);
        expect(cubit.state[2]?.progress?.caughtUp, isTrue);

        await cubit.close();
      },
    );

    test('different Seasons can load independently', () async {
      final _ControlledShowDetailsSeasonsRepository repository =
          _ControlledShowDetailsSeasonsRepository();

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.loadInitialProgress();

      final Future<void> loadSeasonOne = cubit.toggleSeason(1);

      await repository.seasonOneEpisodesRequested.future;

      final Future<void> loadSeasonTwo = cubit.toggleSeason(2);

      await repository.seasonTwoEpisodesRequested.future;

      expect(cubit.state[1]?.isExpanded, isTrue);
      expect(cubit.state[1]?.isLoading, isTrue);

      expect(cubit.state[2]?.isExpanded, isTrue);
      expect(cubit.state[2]?.isLoading, isTrue);

      repository.completeSeasonOneEpisodes();

      await loadSeasonOne;

      expect(cubit.state[1]?.isLoading, isFalse);
      expect(cubit.state[1]?.hasLoadedEpisodes, isTrue);

      expect(cubit.state[2]?.isLoading, isTrue);
      expect(cubit.state[2]?.hasLoadedEpisodes, isFalse);

      repository.completeSeasonTwoEpisodes();

      await loadSeasonTwo;

      expect(cubit.state[1]?.isLoading, isFalse);
      expect(cubit.state[1]?.hasLoadedEpisodes, isTrue);

      expect(cubit.state[2]?.isLoading, isFalse);
      expect(cubit.state[2]?.hasLoadedEpisodes, isTrue);

      await cubit.close();
    });

    test(
      'handles a Show with many Seasons without loading Episodes eagerly',
      () async {
        final List<ShowDetailsLocalSeason> seasons =
            List<ShowDetailsLocalSeason>.generate(30, (int index) {
              final int seasonNumber = index + 1;

              return ShowDetailsLocalSeason(
                id: 'season-$seasonNumber-uuid',
                tmdbId: 100000 + seasonNumber,
                seasonNumber: seasonNumber,
              );
            }, growable: false);

        final List<ShowDetailsSeasonProgress> progressItems = seasons
            .map((ShowDetailsLocalSeason season) {
              return ShowDetailsSeasonProgress(
                seasonId: season.id,
                watchedEpisodes: 0,
                totalEpisodes: 10,
                progressPercentage: 0,
                airedEpisodes: 10,
                watchedAiredEpisodes: 0,
                airedProgressPercentage: 0,
                caughtUp: false,
              );
            })
            .toList(growable: false);

        final _ManySeasonsRepository repository = _ManySeasonsRepository(
          seasons: seasons,
          progressItems: progressItems,
        );

        final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
          repository: repository,
          showTmdbId: 37854,
        );

        await cubit.loadInitialProgress();

        expect(cubit.state, hasLength(30));

        for (int seasonNumber = 1; seasonNumber <= 30; seasonNumber++) {
          final ShowDetailsSeasonState? seasonState = cubit.state[seasonNumber];

          expect(seasonState, isNotNull);
          expect(seasonState!.progress, isNotNull);
          expect(seasonState.isExpanded, isFalse);
          expect(seasonState.isLoading, isFalse);
          expect(seasonState.hasLoadedEpisodes, isFalse);
          expect(seasonState.episodes, isEmpty);
        }

        expect(repository.getEpisodesCalls, 0);
        expect(repository.syncEpisodesCalls, 0);

        await cubit.toggleSeason(18);

        expect(repository.getEpisodesCalls, 1);
        expect(repository.requestedEpisodeSeasonIds, <String>[
          'season-18-uuid',
        ]);

        expect(cubit.state[18]?.isExpanded, isTrue);
        expect(cubit.state[18]?.hasLoadedEpisodes, isTrue);
        expect(cubit.state[18]?.episodes, hasLength(2));

        for (int seasonNumber = 1; seasonNumber <= 30; seasonNumber++) {
          if (seasonNumber == 18) {
            continue;
          }

          expect(cubit.state[seasonNumber]?.isExpanded, isFalse);
          expect(cubit.state[seasonNumber]?.isLoading, isFalse);
          expect(cubit.state[seasonNumber]?.hasLoadedEpisodes, isFalse);
          expect(cubit.state[seasonNumber]?.episodes, isEmpty);
          expect(cubit.state[seasonNumber]?.progress, isNotNull);
        }

        await cubit.close();
      },
    );

    test('loads Episode progress when a Season is expanded', () async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository();

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.toggleSeason(1);

      final ShowDetailsSeasonState seasonState = cubit.state[1]!;

      expect(seasonState.isLoaded, isTrue);

      expect(seasonState.episodeProgressById.keys, <String>['episode-1-uuid']);

      final ShowDetailsEpisodeProgress? progress =
          seasonState.episodeProgressById['episode-1-uuid'];

      expect(progress, isNotNull);
      expect(progress!.isWatched, isTrue);

      expect(progress.watchedAt, DateTime.utc(2026, 8, 10, 21, 30));

      expect(
        seasonState.episodeProgressById.containsKey('episode-2-uuid'),
        isFalse,
      );

      await cubit.close();
    });
    test('marks an Episode as watched and refreshes Season progress', () async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository();

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.toggleSeason(1);

      expect(
        cubit.state[1]!.episodeProgressById.containsKey('episode-2-uuid'),
        isFalse,
      );

      await cubit.markEpisodeWatched(
        seasonNumber: 1,
        episodeId: 'episode-2-uuid',
      );

      final ShowDetailsSeasonState seasonState = cubit.state[1]!;

      final ShowDetailsEpisodeProgress progress =
          seasonState.episodeProgressById['episode-2-uuid']!;

      expect(progress.isWatched, isTrue);
      expect(progress.watchedAt, DateTime.utc(2026, 8, 11));

      expect(
        seasonState.operationForEpisode('episode-2-uuid').status,
        ShowDetailsEpisodeOperationStatus.idle,
      );

      expect(repository.requestedProgressSeasonIds.last, 'season-1-uuid');

      await cubit.close();
    });

    test('marks a watched Episode as unwatched', () async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository();

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.toggleSeason(1);

      expect(
        cubit.state[1]!.episodeProgressById['episode-1-uuid']!.isWatched,
        isTrue,
      );

      await cubit.markEpisodeUnwatched(
        seasonNumber: 1,
        episodeId: 'episode-1-uuid',
      );

      final ShowDetailsEpisodeProgress progress =
          cubit.state[1]!.episodeProgressById['episode-1-uuid']!;

      expect(progress.isWatched, isFalse);
      expect(progress.watchedAt, isNull);

      expect(
        cubit.state[1]!.operationForEpisode('episode-1-uuid').status,
        ShowDetailsEpisodeOperationStatus.idle,
      );

      await cubit.close();
    });
    test('updates only the affected Episode while marking watched', () async {
      final _ControlledEpisodeUpdateRepository repository =
          _ControlledEpisodeUpdateRepository();

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.toggleSeason(1);

      final Future<void> updateFuture = cubit.markEpisodeWatched(
        seasonNumber: 1,
        episodeId: 'episode-2-uuid',
      );

      await Future<void>.delayed(Duration.zero);

      final ShowDetailsSeasonState updatingState = cubit.state[1]!;

      expect(
        updatingState.operationForEpisode('episode-2-uuid').isUpdating,
        isTrue,
      );

      expect(
        updatingState.operationForEpisode('episode-1-uuid').isUpdating,
        isFalse,
      );

      expect(
        updatingState.episodeProgressById['episode-1-uuid']!.isWatched,
        isTrue,
      );

      repository.completeWatched(episodeId: 'episode-2-uuid');

      await updateFuture;

      expect(
        cubit.state[1]!.operationForEpisode('episode-2-uuid').isUpdating,
        isFalse,
      );

      expect(
        cubit.state[1]!.episodeProgressById['episode-2-uuid']!.isWatched,
        isTrue,
      );

      await cubit.close();
    });
    test(
      'preserves Episode state when marking watched fails and Retry succeeds',
      () async {
        final _RetryEpisodeUpdateRepository repository =
            _RetryEpisodeUpdateRepository();

        final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
          repository: repository,
          showTmdbId: 95396,
        );

        await cubit.toggleSeason(1);

        expect(
          cubit.state[1]!.episodeProgressById.containsKey('episode-2-uuid'),
          isFalse,
        );

        await cubit.markEpisodeWatched(
          seasonNumber: 1,
          episodeId: 'episode-2-uuid',
        );

        final ShowDetailsSeasonState failedState = cubit.state[1]!;

        expect(
          failedState.episodeProgressById.containsKey('episode-2-uuid'),
          isFalse,
        );

        final ShowDetailsEpisodeOperation failedOperation = failedState
            .operationForEpisode('episode-2-uuid');

        expect(failedOperation.hasFailed, isTrue);
        expect(failedOperation.targetWatched, isTrue);
        expect(
          failedOperation.intent,
          ShowDetailsEpisodeOperationIntent.setWatchedState,
        );
        expect(failedOperation.error, isA<AppException>());
        expect(repository.markWatchedCalls, 1);

        await cubit.retryEpisodeUpdate(
          seasonNumber: 1,
          episodeId: 'episode-2-uuid',
        );

        final ShowDetailsSeasonState retriedState = cubit.state[1]!;

        expect(repository.markWatchedCalls, 2);

        expect(
          retriedState.episodeProgressById['episode-2-uuid']!.isWatched,
          isTrue,
        );

        expect(
          retriedState.operationForEpisode('episode-2-uuid').status,
          ShowDetailsEpisodeOperationStatus.idle,
        );

        await cubit.close();
      },
    );
    test(
      'preserves watched Episode when marking unwatched fails and Retry succeeds',
      () async {
        final _RetryEpisodeUpdateRepository repository =
            _RetryEpisodeUpdateRepository();

        final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
          repository: repository,
          showTmdbId: 95396,
        );

        await cubit.toggleSeason(1);

        expect(
          cubit.state[1]!.episodeProgressById['episode-1-uuid']!.isWatched,
          isTrue,
        );

        await cubit.markEpisodeUnwatched(
          seasonNumber: 1,
          episodeId: 'episode-1-uuid',
        );

        final ShowDetailsSeasonState failedState = cubit.state[1]!;

        expect(
          failedState.episodeProgressById['episode-1-uuid']!.isWatched,
          isTrue,
        );

        final ShowDetailsEpisodeOperation failedOperation = failedState
            .operationForEpisode('episode-1-uuid');

        expect(failedOperation.hasFailed, isTrue);
        expect(failedOperation.targetWatched, isFalse);
        expect(
          failedOperation.intent,
          ShowDetailsEpisodeOperationIntent.setWatchedState,
        );
        expect(repository.markUnwatchedCalls, 1);

        await cubit.retryEpisodeUpdate(
          seasonNumber: 1,
          episodeId: 'episode-1-uuid',
        );

        final ShowDetailsSeasonState retriedState = cubit.state[1]!;

        expect(repository.markUnwatchedCalls, 2);

        expect(
          retriedState.episodeProgressById['episode-1-uuid']!.isWatched,
          isFalse,
        );

        expect(
          retriedState.operationForEpisode('episode-1-uuid').status,
          ShowDetailsEpisodeOperationStatus.idle,
        );

        await cubit.close();
      },
    );
    test('Retry does nothing when Episode operation has not failed', () async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository();

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.toggleSeason(1);

      await cubit.retryEpisodeUpdate(
        seasonNumber: 1,
        episodeId: 'episode-2-uuid',
      );

      expect(
        cubit.state[1]!.operationForEpisode('episode-2-uuid').status,
        ShowDetailsEpisodeOperationStatus.idle,
      );

      await cubit.close();
    });
    test(
      'rewatches an already watched Episode and updates watchedAt',
      () async {
        final _FakeShowDetailsSeasonsRepository repository =
            _FakeShowDetailsSeasonsRepository();

        final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
          repository: repository,
          showTmdbId: 95396,
        );

        await cubit.toggleSeason(1);

        final ShowDetailsEpisodeProgress originalProgress =
            cubit.state[1]!.episodeProgressById['episode-1-uuid']!;

        expect(originalProgress.isWatched, isTrue);
        expect(originalProgress.watchedAt, DateTime.utc(2026, 8, 10, 21, 30));

        await cubit.rewatchEpisode(
          seasonNumber: 1,
          episodeId: 'episode-1-uuid',
        );

        final ShowDetailsSeasonState seasonState = cubit.state[1]!;

        final ShowDetailsEpisodeProgress rewatchedProgress =
            seasonState.episodeProgressById['episode-1-uuid']!;

        expect(rewatchedProgress.isWatched, isTrue);

        expect(rewatchedProgress.watchedAt, DateTime.utc(2026, 8, 11));

        expect(rewatchedProgress.watchedAt, isNot(originalProgress.watchedAt));

        expect(
          seasonState.operationForEpisode('episode-1-uuid').status,
          ShowDetailsEpisodeOperationStatus.idle,
        );

        await cubit.close();
      },
    );
    test(
      'preserves watched Episode when rewatch fails and Retry succeeds',
      () async {
        final _RetryEpisodeUpdateRepository repository =
            _RetryEpisodeUpdateRepository();

        final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
          repository: repository,
          showTmdbId: 95396,
        );

        await cubit.toggleSeason(1);

        final ShowDetailsEpisodeProgress originalProgress =
            cubit.state[1]!.episodeProgressById['episode-1-uuid']!;

        expect(originalProgress.isWatched, isTrue);

        final DateTime? originalWatchedAt = originalProgress.watchedAt;

        await cubit.rewatchEpisode(
          seasonNumber: 1,
          episodeId: 'episode-1-uuid',
        );

        final ShowDetailsSeasonState failedState = cubit.state[1]!;

        /*
     * A failed rewatch must not destroy the existing watched state
     * or its previous viewing date.
     */
        expect(
          failedState.episodeProgressById['episode-1-uuid']!.isWatched,
          isTrue,
        );

        expect(
          failedState.episodeProgressById['episode-1-uuid']!.watchedAt,
          originalWatchedAt,
        );

        final ShowDetailsEpisodeOperation failedOperation = failedState
            .operationForEpisode('episode-1-uuid');

        expect(failedOperation.hasFailed, isTrue);

        expect(
          failedOperation.intent,
          ShowDetailsEpisodeOperationIntent.rewatch,
        );

        expect(failedOperation.targetWatched, isTrue);

        expect(failedOperation.error, isA<AppException>());

        expect(repository.markWatchedCalls, 1);

        await cubit.retryEpisodeUpdate(
          seasonNumber: 1,
          episodeId: 'episode-1-uuid',
        );

        final ShowDetailsSeasonState retriedState = cubit.state[1]!;

        expect(repository.markWatchedCalls, 2);

        final ShowDetailsEpisodeProgress retriedProgress =
            retriedState.episodeProgressById['episode-1-uuid']!;

        expect(retriedProgress.isWatched, isTrue);

        expect(retriedProgress.watchedAt, DateTime.utc(2026, 8, 11));

        expect(retriedProgress.watchedAt, isNot(originalWatchedAt));

        expect(
          retriedState.operationForEpisode('episode-1-uuid').status,
          ShowDetailsEpisodeOperationStatus.idle,
        );

        await cubit.close();
      },
    );
    test(
      'removes latest viewing and keeps Episode watched when history remains',
      () async {
        final _WatchEventRemovalRepository repository =
            _WatchEventRemovalRepository();

        final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
          repository: repository,
          showTmdbId: 95396,
        );

        await cubit.toggleSeason(1);

        expect(
          cubit.state[1]!.episodeProgressById['episode-1-uuid']!.watchCount,
          2,
        );

        await cubit.removeLatestEpisodeViewing(
          seasonNumber: 1,
          episodeId: 'episode-1-uuid',
        );

        final ShowDetailsEpisodeProgress progress =
            cubit.state[1]!.episodeProgressById['episode-1-uuid']!;

        expect(repository.deleteLatestCalls, 1);
        expect(repository.events, hasLength(1));

        expect(progress.isWatched, isTrue);
        expect(progress.watchCount, 1);
        expect(progress.watchedAt, DateTime.utc(2026, 7, 20, 20));

        expect(
          cubit.state[1]!.operationForEpisode('episode-1-uuid').status,
          ShowDetailsEpisodeOperationStatus.idle,
        );

        await cubit.close();
      },
    );
    test('removes all viewings and marks Episode unwatched', () async {
      final _WatchEventRemovalRepository repository =
          _WatchEventRemovalRepository();

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.toggleSeason(1);

      await cubit.removeAllEpisodeViewings(
        seasonNumber: 1,
        episodeId: 'episode-1-uuid',
      );

      final ShowDetailsEpisodeProgress progress =
          cubit.state[1]!.episodeProgressById['episode-1-uuid']!;

      expect(repository.deleteAllCalls, 1);
      expect(repository.events, isEmpty);

      expect(progress.isWatched, isFalse);
      expect(progress.watchCount, 0);
      expect(progress.watchedAt, isNull);

      expect(
        cubit.state[1]!.operationForEpisode('episode-1-uuid').status,
        ShowDetailsEpisodeOperationStatus.idle,
      );

      await cubit.close();
    });
    test('retries latest viewing removal using the same event', () async {
      final _WatchEventRemovalRepository repository =
          _WatchEventRemovalRepository(failDeleteLatestOnce: true);

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.toggleSeason(1);

      await cubit.removeLatestEpisodeViewing(
        seasonNumber: 1,
        episodeId: 'episode-1-uuid',
      );

      final ShowDetailsEpisodeOperation failedOperation = cubit.state[1]!
          .operationForEpisode('episode-1-uuid');

      expect(failedOperation.hasFailed, isTrue);
      expect(
        failedOperation.intent,
        ShowDetailsEpisodeOperationIntent.removeLatestViewing,
      );
      expect(failedOperation.eventId, 'watch-event-latest');
      expect(repository.deleteLatestCalls, 1);

      await cubit.retryEpisodeUpdate(
        seasonNumber: 1,
        episodeId: 'episode-1-uuid',
      );

      expect(repository.deleteLatestCalls, 2);
      expect(repository.events, hasLength(1));
      expect(repository.events.single.id, 'watch-event-previous');

      expect(
        cubit.state[1]!.operationForEpisode('episode-1-uuid').status,
        ShowDetailsEpisodeOperationStatus.idle,
      );

      await cubit.close();
    });
    test('marks all aired Episodes in a Season as watched', () async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository();

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.loadInitialProgress();

      expect(cubit.state[1]?.progress?.caughtUp, isFalse);

      await cubit.markSeasonWatched(seasonNumber: 1);

      expect(repository.markSeasonWatchedCalls, 1);

      expect(repository.requestedMarkSeasonWatchedIds, <String>[
        'season-1-uuid',
      ]);

      final ShowDetailsSeasonState seasonState = cubit.state[1]!;

      expect(seasonState.progress?.watchedAiredEpisodes, 2);
      expect(seasonState.progress?.airedEpisodes, 2);
      expect(seasonState.progress?.airedProgressPercentage, 100);
      expect(seasonState.progress?.caughtUp, isTrue);

      expect(seasonState.operation, const ShowDetailsSeasonOperation.idle());

      await cubit.close();
    });
    test('does not mark Season watched when it is already caught up', () async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository();

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.loadInitialProgress();

      expect(cubit.state[2]?.progress?.caughtUp, isTrue);

      await cubit.markSeasonWatched(seasonNumber: 2);

      expect(repository.markSeasonWatchedCalls, 0);

      expect(
        cubit.state[2]?.operation,
        const ShowDetailsSeasonOperation.idle(),
      );

      await cubit.close();
    });
    test('preserves Season data when marking Season watched fails', () async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository(failMarkSeasonWatched: true);

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.loadInitialProgress();

      final ShowDetailsSeasonProgress originalProgress =
          cubit.state[1]!.progress!;

      await cubit.markSeasonWatched(seasonNumber: 1);

      final ShowDetailsSeasonState state = cubit.state[1]!;

      expect(state.progress, originalProgress);

      expect(state.operation.hasFailed, isTrue);

      expect(state.operation.error?.type, AppExceptionType.connection);

      expect(repository.markSeasonWatchedCalls, 1);

      await cubit.close();
    });
    test('retries marking Season watched after failure', () async {
      final _FakeShowDetailsSeasonsRepository repository =
          _FakeShowDetailsSeasonsRepository(failMarkSeasonWatched: true);

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      await cubit.loadInitialProgress();

      await cubit.markSeasonWatched(seasonNumber: 1);

      expect(cubit.state[1]?.operation.hasFailed, isTrue);

      repository.failMarkSeasonWatched = false;

      await cubit.retryMarkSeasonWatched(seasonNumber: 1);

      expect(repository.markSeasonWatchedCalls, 2);

      expect(cubit.state[1]?.progress?.caughtUp, isTrue);

      expect(
        cubit.state[1]?.operation,
        const ShowDetailsSeasonOperation.idle(),
      );

      await cubit.close();
    });
    test(
      'refreshes Episode progress after marking an expanded Season watched',
      () async {
        final _FakeShowDetailsSeasonsRepository repository =
            _FakeShowDetailsSeasonsRepository();

        final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
          repository: repository,
          showTmdbId: 95396,
        );

        await cubit.loadInitialProgress();

        await cubit.toggleSeason(1);

        final ShowDetailsSeasonState before = cubit.state[1]!;

        expect(before.hasLoadedEpisodes, isTrue);
        expect(before.episodes, isNotEmpty);

        await cubit.markSeasonWatched(seasonNumber: 1);

        final ShowDetailsSeasonState after = cubit.state[1]!;

        expect(after.progress?.caughtUp, isTrue);

        expect(after.episodeProgressById, isNotEmpty);

        expect(after.episodeProgressById['episode-1-uuid']?.isWatched, isTrue);

        await cubit.close();
      },
    );
  });
}

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

const List<ShowDetailsSeasonProgress> _defaultBatchProgress =
    <ShowDetailsSeasonProgress>[
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
    ];

final class _FakeShowDetailsSeasonsRepository
    implements ShowDetailsSeasonsRepository {
  _FakeShowDetailsSeasonsRepository({
    this.localShowId = 'show-uuid',
    this.localSeasons = const <ShowDetailsLocalSeason>[
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
    this.batchProgress = _defaultBatchProgress,
    this.emptyLocalSeasonIds = const <String>{},
    this.failingSeasonId,
    this.failingSyncSeasonId,
    this.failingProgressSeasonId,
    this.failBatchProgress = false,
    this.failMarkSeasonWatched = false,
  });

  final String localShowId;

  final List<ShowDetailsLocalSeason> localSeasons;

  final List<ShowDetailsSeasonProgress> batchProgress;

  final Set<String> emptyLocalSeasonIds;

  String? failingSeasonId;
  String? failingSyncSeasonId;
  String? failingProgressSeasonId;

  bool failBatchProgress;

  bool failMarkSeasonWatched;

  int markSeasonWatchedCalls = 0;

  final List<String> requestedMarkSeasonWatchedIds = <String>[];

  int resolveLocalSeasonsCalls = 0;
  int getSeasonsProgressCalls = 0;
  int getEpisodesCalls = 0;
  int syncEpisodesCalls = 0;
  int getSeasonProgressCalls = 0;

  final List<int> requestedShowTmdbIds = <int>[];

  final List<String> requestedProgressShowIds = <String>[];

  final List<String> requestedSeasonIds = <String>[];

  final List<String> requestedSyncSeasonIds = <String>[];

  final List<String> requestedProgressSeasonIds = <String>[];
  bool seasonMarkedWatched = false;

  @override
  Future<ShowDetailsSeasonsBootstrap> resolveLocalSeasons({
    required int showTmdbId,
  }) async {
    resolveLocalSeasonsCalls++;

    requestedShowTmdbIds.add(showTmdbId);

    return ShowDetailsSeasonsBootstrap(
      showId: localShowId,
      seasons: localSeasons,
    );
  }

  @override
  Future<List<ShowDetailsSeasonProgress>> getSeasonsProgress({
    required String showId,
  }) async {
    getSeasonsProgressCalls++;

    requestedProgressShowIds.add(showId);

    if (failBatchProgress) {
      throw const AppException.connection();
    }

    return batchProgress;
  }

  @override
  Future<List<ShowDetailsEpisode>> getEpisodes({
    required String seasonId,
  }) async {
    getEpisodesCalls++;

    requestedSeasonIds.add(seasonId);

    if (seasonId == failingSeasonId) {
      throw const AppException.connection();
    }

    if (emptyLocalSeasonIds.contains(seasonId)) {
      return const <ShowDetailsEpisode>[];
    }

    return switch (seasonId) {
      'season-1-uuid' => const <ShowDetailsEpisode>[_episodeOne, _episodeTwo],
      'season-2-uuid' => const <ShowDetailsEpisode>[_episodeThree],
      _ => const <ShowDetailsEpisode>[],
    };
  }

  @override
  Future<List<ShowDetailsEpisode>> syncEpisodes({
    required String seasonId,
  }) async {
    syncEpisodesCalls++;

    requestedSyncSeasonIds.add(seasonId);

    if (seasonId == failingSyncSeasonId) {
      throw const AppException.connection();
    }

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
    getSeasonProgressCalls++;

    requestedProgressSeasonIds.add(seasonId);

    if (seasonId == failingProgressSeasonId) {
      throw const AppException.connection();
    }

    return switch (seasonId) {
      'season-1-uuid' => const ShowDetailsSeasonProgress(
        seasonId: 'season-1-uuid',
        watchedEpisodes: 1,
        totalEpisodes: 2,
        progressPercentage: 50,
        airedEpisodes: 2,
        watchedAiredEpisodes: 1,
        airedProgressPercentage: 50,
        caughtUp: false,
      ),
      'season-2-uuid' => const ShowDetailsSeasonProgress(
        seasonId: 'season-2-uuid',
        watchedEpisodes: 1,
        totalEpisodes: 1,
        progressPercentage: 100,
        airedEpisodes: 1,
        watchedAiredEpisodes: 1,
        airedProgressPercentage: 100,
        caughtUp: true,
      ),
      _ => ShowDetailsSeasonProgress(
        seasonId: seasonId,
        watchedEpisodes: 0,
        totalEpisodes: 0,
        progressPercentage: 0,
        airedEpisodes: 0,
        watchedAiredEpisodes: 0,
        airedProgressPercentage: 0,
        caughtUp: false,
      ),
    };
  }

  @override
  Future<List<ShowDetailsEpisodeProgress>> getEpisodeProgress({
    required String seasonId,
  }) async {
    if (seasonId == 'season-1-uuid' && seasonMarkedWatched) {
      return <ShowDetailsEpisodeProgress>[
        ShowDetailsEpisodeProgress(
          id: 'progress-1-uuid',
          episodeId: 'episode-1-uuid',
          isWatched: true,
          watchCount: 1,
          watchedAt: DateTime.utc(2026, 8, 16),
        ),
        ShowDetailsEpisodeProgress(
          id: 'progress-2-uuid',
          episodeId: 'episode-2-uuid',
          isWatched: true,
          watchCount: 1,
          watchedAt: DateTime.utc(2026, 8, 16),
        ),
      ];
    }
    return switch (seasonId) {
      'season-1-uuid' => <ShowDetailsEpisodeProgress>[
        ShowDetailsEpisodeProgress(
          id: 'progress-1-uuid',
          episodeId: 'episode-1-uuid',
          isWatched: true,
          watchCount: 1,
          watchedAt: DateTime.utc(2026, 8, 10, 21, 30),
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
      watchCount: 1,
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
      watchCount: 0,
    );
  }

  @override
  Future<List<ShowDetailsEpisodeWatchEvent>> getEpisodeWatchEvents({
    required String episodeId,
  }) async {
    return const <ShowDetailsEpisodeWatchEvent>[];
  }

  @override
  Future<void> deleteEpisodeWatchEvent({
    required String episodeId,
    required String eventId,
  }) async {}

  @override
  Future<void> deleteAllEpisodeWatchEvents({required String episodeId}) async {}

  @override
  Future<ShowDetailsSeasonProgress> markSeasonWatched({
    required String seasonId,
  }) async {
    markSeasonWatchedCalls++;

    requestedMarkSeasonWatchedIds.add(seasonId);

    if (failMarkSeasonWatched) {
      throw const AppException.connection();
    }
    seasonMarkedWatched = true;

    return ShowDetailsSeasonProgress(
      seasonId: seasonId,
      watchedEpisodes: 2,
      totalEpisodes: 2,
      progressPercentage: 100,
      airedEpisodes: 2,
      watchedAiredEpisodes: 2,
      airedProgressPercentage: 100,
      caughtUp: true,
    );
  }
}

final class _ControlledShowDetailsSeasonsRepository
    implements ShowDetailsSeasonsRepository {
  final Completer<void> seasonOneEpisodesRequested = Completer<void>();
  final Completer<void> seasonTwoEpisodesRequested = Completer<void>();

  final Completer<List<ShowDetailsEpisode>> _seasonOneEpisodes =
      Completer<List<ShowDetailsEpisode>>();

  final Completer<List<ShowDetailsEpisode>> _seasonTwoEpisodes =
      Completer<List<ShowDetailsEpisode>>();

  void completeSeasonOneEpisodes() {
    if (!_seasonOneEpisodes.isCompleted) {
      _seasonOneEpisodes.complete(const <ShowDetailsEpisode>[
        _episodeOne,
        _episodeTwo,
      ]);
    }
  }

  void completeSeasonTwoEpisodes() {
    if (!_seasonTwoEpisodes.isCompleted) {
      _seasonTwoEpisodes.complete(const <ShowDetailsEpisode>[_episodeThree]);
    }
  }

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
    return const <ShowDetailsSeasonProgress>[
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
    ];
  }

  @override
  Future<List<ShowDetailsEpisode>> getEpisodes({required String seasonId}) {
    switch (seasonId) {
      case 'season-1-uuid':
        if (!seasonOneEpisodesRequested.isCompleted) {
          seasonOneEpisodesRequested.complete();
        }

        return _seasonOneEpisodes.future;

      case 'season-2-uuid':
        if (!seasonTwoEpisodesRequested.isCompleted) {
          seasonTwoEpisodesRequested.complete();
        }

        return _seasonTwoEpisodes.future;

      default:
        return Future<List<ShowDetailsEpisode>>.value(
          const <ShowDetailsEpisode>[],
        );
    }
  }

  @override
  Future<List<ShowDetailsEpisode>> syncEpisodes({
    required String seasonId,
  }) async {
    return const <ShowDetailsEpisode>[];
  }

  @override
  Future<List<ShowDetailsEpisodeWatchEvent>> getEpisodeWatchEvents({
    required String episodeId,
  }) async {
    return const <ShowDetailsEpisodeWatchEvent>[];
  }

  @override
  Future<void> deleteEpisodeWatchEvent({
    required String episodeId,
    required String eventId,
  }) async {}

  @override
  Future<ShowDetailsSeasonProgress> getSeasonProgress({
    required String seasonId,
  }) async {
    return switch (seasonId) {
      'season-1-uuid' => const ShowDetailsSeasonProgress(
        seasonId: 'season-1-uuid',
        watchedEpisodes: 1,
        totalEpisodes: 2,
        progressPercentage: 50,
        airedEpisodes: 2,
        watchedAiredEpisodes: 1,
        airedProgressPercentage: 50,
        caughtUp: false,
      ),
      'season-2-uuid' => const ShowDetailsSeasonProgress(
        seasonId: 'season-2-uuid',
        watchedEpisodes: 1,
        totalEpisodes: 1,
        progressPercentage: 100,
        airedEpisodes: 1,
        watchedAiredEpisodes: 1,
        airedProgressPercentage: 100,
        caughtUp: true,
      ),
      _ => ShowDetailsSeasonProgress(
        seasonId: seasonId,
        watchedEpisodes: 0,
        totalEpisodes: 0,
        progressPercentage: 0,
        airedEpisodes: 0,
        watchedAiredEpisodes: 0,
        airedProgressPercentage: 0,
        caughtUp: false,
      ),
    };
  }

  @override
  Future<List<ShowDetailsEpisodeProgress>> getEpisodeProgress({
    required String seasonId,
  }) async {
    return const <ShowDetailsEpisodeProgress>[];
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
      watchCount: 1,
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
      watchCount: 0,
    );
  }

  @override
  Future<void> deleteAllEpisodeWatchEvents({required String episodeId}) async {}

  @override
  Future<ShowDetailsSeasonProgress> markSeasonWatched({
    required String seasonId,
  }) {
    throw UnsupportedError(
      'markSeasonWatched is not used by this test repository.',
    );
  }
}

final class _ManySeasonsRepository implements ShowDetailsSeasonsRepository {
  _ManySeasonsRepository({required this.seasons, required this.progressItems});

  final List<ShowDetailsLocalSeason> seasons;
  final List<ShowDetailsSeasonProgress> progressItems;

  int getEpisodesCalls = 0;
  int syncEpisodesCalls = 0;

  final List<String> requestedEpisodeSeasonIds = <String>[];

  @override
  Future<ShowDetailsSeasonsBootstrap> resolveLocalSeasons({
    required int showTmdbId,
  }) async {
    return ShowDetailsSeasonsBootstrap(
      showId: 'many-seasons-show-uuid',
      seasons: seasons,
    );
  }

  @override
  Future<List<ShowDetailsSeasonProgress>> getSeasonsProgress({
    required String showId,
  }) async {
    return progressItems;
  }

  @override
  Future<List<ShowDetailsEpisodeWatchEvent>> getEpisodeWatchEvents({
    required String episodeId,
  }) async {
    return const <ShowDetailsEpisodeWatchEvent>[];
  }

  @override
  Future<void> deleteEpisodeWatchEvent({
    required String episodeId,
    required String eventId,
  }) async {}

  @override
  Future<void> deleteAllEpisodeWatchEvents({required String episodeId}) async {}

  @override
  Future<List<ShowDetailsEpisode>> getEpisodes({
    required String seasonId,
  }) async {
    getEpisodesCalls++;

    requestedEpisodeSeasonIds.add(seasonId);

    return const <ShowDetailsEpisode>[
      ShowDetailsEpisode(
        id: 'episode-1-uuid',
        tmdbId: 900001,
        episodeNumber: 1,
        title: 'Episode 1',
        runtime: 24,
        voteAverage: 8,
        voteCount: 10,
      ),
      ShowDetailsEpisode(
        id: 'episode-2-uuid',
        tmdbId: 900002,
        episodeNumber: 2,
        title: 'Episode 2',
        runtime: 24,
        voteAverage: 8,
        voteCount: 10,
      ),
    ];
  }

  @override
  Future<List<ShowDetailsEpisode>> syncEpisodes({
    required String seasonId,
  }) async {
    syncEpisodesCalls++;

    return const <ShowDetailsEpisode>[];
  }

  @override
  Future<ShowDetailsSeasonProgress> getSeasonProgress({
    required String seasonId,
  }) async {
    return progressItems.firstWhere((ShowDetailsSeasonProgress progress) {
      return progress.seasonId == seasonId;
    });
  }

  @override
  Future<List<ShowDetailsEpisodeProgress>> getEpisodeProgress({
    required String seasonId,
  }) async {
    return const <ShowDetailsEpisodeProgress>[];
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
      watchCount: 1,
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
      watchCount: 0,
    );
  }

  @override
  Future<ShowDetailsSeasonProgress> markSeasonWatched({
    required String seasonId,
  }) {
    throw UnsupportedError(
      'markSeasonWatched is not used by this test repository.',
    );
  }
}

final class _ControlledEpisodeUpdateRepository
    extends _FakeShowDetailsSeasonsRepository {
  final Completer<ShowDetailsEpisodeProgress> _updateCompleter =
      Completer<ShowDetailsEpisodeProgress>();

  void completeWatched({required String episodeId}) {
    _updateCompleter.complete(
      ShowDetailsEpisodeProgress(
        id: 'progress-$episodeId',
        episodeId: episodeId,
        isWatched: true,
        watchCount: 1,
        watchedAt: DateTime.utc(2026, 8, 11),
      ),
    );
  }

  @override
  Future<ShowDetailsEpisodeProgress> markEpisodeWatched({
    required String episodeId,
    DateTime? watchedAt,
  }) {
    return _updateCompleter.future;
  }
}

final class _RetryEpisodeUpdateRepository
    extends _FakeShowDetailsSeasonsRepository {
  int markWatchedCalls = 0;
  int markUnwatchedCalls = 0;

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
      watchCount: 1,
      watchedAt: DateTime.utc(2026, 8, 11),
    );
  }

  @override
  Future<ShowDetailsEpisodeProgress> markEpisodeUnwatched({
    required String episodeId,
  }) async {
    markUnwatchedCalls++;

    if (markUnwatchedCalls == 1) {
      throw const AppException.connection();
    }

    return ShowDetailsEpisodeProgress(
      id: 'progress-$episodeId',
      episodeId: episodeId,
      isWatched: false,
      watchCount: 0,
    );
  }
}

final class _WatchEventRemovalRepository
    implements ShowDetailsSeasonsRepository {
  _WatchEventRemovalRepository({this.failDeleteLatestOnce = false});

  bool failDeleteLatestOnce;

  int deleteLatestCalls = 0;
  int deleteAllCalls = 0;

  final List<ShowDetailsEpisodeWatchEvent> events =
      <ShowDetailsEpisodeWatchEvent>[
        ShowDetailsEpisodeWatchEvent(
          id: 'watch-event-latest',
          episodeId: 'episode-1-uuid',
          watchedAt: DateTime.utc(2026, 8, 14, 21, 30),
        ),
        ShowDetailsEpisodeWatchEvent(
          id: 'watch-event-previous',
          episodeId: 'episode-1-uuid',
          watchedAt: DateTime.utc(2026, 7, 20, 20),
        ),
      ];

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
      ],
    );
  }

  @override
  Future<List<ShowDetailsSeasonProgress>> getSeasonsProgress({
    required String showId,
  }) async {
    return <ShowDetailsSeasonProgress>[_seasonProgress()];
  }

  @override
  Future<List<ShowDetailsEpisode>> getEpisodes({
    required String seasonId,
  }) async {
    return const <ShowDetailsEpisode>[_episodeOne];
  }

  @override
  Future<List<ShowDetailsEpisode>> syncEpisodes({
    required String seasonId,
  }) async {
    return const <ShowDetailsEpisode>[_episodeOne];
  }

  @override
  Future<ShowDetailsSeasonProgress> getSeasonProgress({
    required String seasonId,
  }) async {
    return _seasonProgress();
  }

  @override
  Future<List<ShowDetailsEpisodeProgress>> getEpisodeProgress({
    required String seasonId,
  }) async {
    if (events.isEmpty) {
      return <ShowDetailsEpisodeProgress>[
        const ShowDetailsEpisodeProgress(
          id: 'progress-1-uuid',
          episodeId: 'episode-1-uuid',
          isWatched: false,
          watchCount: 0,
        ),
      ];
    }

    return <ShowDetailsEpisodeProgress>[
      ShowDetailsEpisodeProgress(
        id: 'progress-1-uuid',
        episodeId: 'episode-1-uuid',
        isWatched: true,
        watchCount: events.length,
        watchedAt: events.first.watchedAt,
      ),
    ];
  }

  @override
  Future<ShowDetailsEpisodeProgress> markEpisodeWatched({
    required String episodeId,
    DateTime? watchedAt,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ShowDetailsEpisodeProgress> markEpisodeUnwatched({
    required String episodeId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<ShowDetailsEpisodeWatchEvent>> getEpisodeWatchEvents({
    required String episodeId,
  }) async {
    return List<ShowDetailsEpisodeWatchEvent>.unmodifiable(events);
  }

  @override
  Future<ShowDetailsSeasonProgress> markSeasonWatched({
    required String seasonId,
  }) {
    throw UnsupportedError(
      'markSeasonWatched is not used by this test repository.',
    );
  }

  @override
  Future<void> deleteEpisodeWatchEvent({
    required String episodeId,
    required String eventId,
  }) async {
    deleteLatestCalls++;

    if (failDeleteLatestOnce) {
      failDeleteLatestOnce = false;
      throw const AppException.connection();
    }

    events.removeWhere(
      (ShowDetailsEpisodeWatchEvent event) => event.id == eventId,
    );
  }

  @override
  Future<void> deleteAllEpisodeWatchEvents({required String episodeId}) async {
    deleteAllCalls++;
    events.clear();
  }

  ShowDetailsSeasonProgress _seasonProgress() {
    final int watched = events.isEmpty ? 0 : 1;

    return ShowDetailsSeasonProgress(
      seasonId: 'season-1-uuid',
      watchedEpisodes: watched,
      totalEpisodes: 1,
      progressPercentage: watched * 100,
      airedEpisodes: 1,
      watchedAiredEpisodes: watched,
      airedProgressPercentage: watched * 100,
      caughtUp: watched == 1,
    );
  }
}
