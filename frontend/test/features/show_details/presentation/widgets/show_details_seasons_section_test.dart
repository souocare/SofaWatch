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
