import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_season_state.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_seasons_cubit.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_episode.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_local_season.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_season_progress.dart';
import 'package:sofawatch/features/show_details/domain/repositories/show_details_seasons_repository.dart';

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
      expect(repository.getSeasonProgressCalls, 1);

      expect(repository.requestedShowTmdbIds, <int>[95396]);

      expect(repository.requestedSeasonIds, <String>['season-1-uuid']);

      expect(repository.requestedProgressSeasonIds, <String>['season-1-uuid']);

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
      expect(repository.getSeasonProgressCalls, 0);

      await cubit.close();
    });
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

final class _FakeShowDetailsSeasonsRepository
    implements ShowDetailsSeasonsRepository {
  _FakeShowDetailsSeasonsRepository({
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
    this.failingSeasonId,
    this.failingProgressSeasonId,
  });

  final List<ShowDetailsLocalSeason> localSeasons;

  String? failingSeasonId;
  String? failingProgressSeasonId;

  int resolveLocalSeasonsCalls = 0;
  int getEpisodesCalls = 0;
  int getSeasonProgressCalls = 0;

  final List<int> requestedShowTmdbIds = <int>[];
  final List<String> requestedSeasonIds = <String>[];
  final List<String> requestedProgressSeasonIds = <String>[];

  @override
  Future<List<ShowDetailsLocalSeason>> resolveLocalSeasons({
    required int showTmdbId,
  }) async {
    resolveLocalSeasonsCalls++;

    requestedShowTmdbIds.add(showTmdbId);

    return localSeasons;
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
}
