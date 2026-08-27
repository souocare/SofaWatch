import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/show_details/application/cubit/show_details_seasons_cubit.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_episode.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_episode_progress.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details_episode_watch_event.dart';
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

      expect(find.text('1 of 2 aired episodes'), findsOneWidget);

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

      expect(find.text('1 of 1 aired episodes'), findsOneWidget);

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

      expect(find.text('10 episodes'), findsOneWidget);

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

      expect(find.text('1 of 2 aired episodes'), findsOneWidget);

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
    testWidgets('uses compact Episode layout on mobile', (
      WidgetTester tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final _EpisodeStillRepository repository = _EpisodeStillRepository();

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      addTearDown(cubit.close);

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

      expect(find.byType(Image), findsNothing);

      expect(find.textContaining('E01'), findsOneWidget);

      expect(find.textContaining('S01E01'), findsNothing);

      expect(
        find.text('This overview must not appear in the Season list.'),
        findsNothing,
      );

      expect(tester.takeException(), isNull);
    });
    testWidgets('uses expanded Episode layout on desktop', (
      WidgetTester tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1280, 900);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final _EpisodeStillRepository repository = _EpisodeStillRepository();

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      addTearDown(cubit.close);

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

      expect(find.byType(Image), findsOneWidget);

      expect(find.textContaining('S01E01'), findsOneWidget);

      expect(
        find.text('This overview must not appear in the Season list.'),
        findsNothing,
      );

      expect(tester.takeException(), isNull);
    });
    testWidgets('shows Episode watch count when Episode has viewing history', (
      WidgetTester tester,
    ) async {
      final _WatchHistoryShowDetailsSeasonsRepository repository =
          _WatchHistoryShowDetailsSeasonsRepository();

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

      await tester.tap(find.text('Season 1'));

      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>(
            'show-details-episode-watch-history-episode-1-uuid',
          ),
        ),
        findsOneWidget,
      );

      expect(find.text('2×'), findsOneWidget);

      await cubit.close();
    });
    testWidgets('opens Episode Watch History and displays every viewing', (
      WidgetTester tester,
    ) async {
      final _WatchHistoryShowDetailsSeasonsRepository repository =
          _WatchHistoryShowDetailsSeasonsRepository();

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

      await tester.tap(find.text('Season 1'));

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey<String>(
            'show-details-episode-watch-history-episode-1-uuid',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Watch history'), findsOneWidget);

      expect(find.text('Good News About Hell'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('episode-watch-event-watch-event-2')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('episode-watch-event-watch-event-1')),
        findsOneWidget,
      );

      expect(repository.getWatchEventsCalls, 1);

      await cubit.close();
    });
    testWidgets('cancelling Watch History deletion preserves viewing', (
      WidgetTester tester,
    ) async {
      final _WatchHistoryShowDetailsSeasonsRepository repository =
          _WatchHistoryShowDetailsSeasonsRepository();

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

      await tester.tap(find.text('Season 1'));

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey<String>(
            'show-details-episode-watch-history-episode-1-uuid',
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey<String>('delete-episode-watch-event-watch-event-2'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Delete viewing?'), findsOneWidget);

      expect(
        find.text('This viewing will be removed from the episode history.'),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('cancel-delete-episode-watch-event')),
      );

      await tester.pumpAndSettle();

      expect(repository.deleteWatchEventCalls, 0);

      expect(repository.events, hasLength(2));

      expect(
        find.byKey(const ValueKey<String>('episode-watch-event-watch-event-2')),
        findsOneWidget,
      );

      await cubit.close();
    });
    testWidgets('deletes a confirmed Episode viewing and refreshes history', (
      WidgetTester tester,
    ) async {
      final _WatchHistoryShowDetailsSeasonsRepository repository =
          _WatchHistoryShowDetailsSeasonsRepository();

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

      await tester.tap(find.text('Season 1'));

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey<String>(
            'show-details-episode-watch-history-episode-1-uuid',
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey<String>('delete-episode-watch-event-watch-event-2'),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey<String>('confirm-delete-episode-watch-event'),
        ),
      );

      await tester.pumpAndSettle();

      expect(repository.deleteWatchEventCalls, 1);

      expect(repository.deletedEpisodeId, 'episode-1-uuid');

      expect(repository.deletedEventId, 'watch-event-2');

      expect(repository.events, hasLength(1));

      expect(
        find.byKey(const ValueKey<String>('episode-watch-event-watch-event-2')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('episode-watch-event-watch-event-1')),
        findsOneWidget,
      );

      await cubit.close();
    });
    testWidgets('updates Episode watch count after deleting a viewing', (
      WidgetTester tester,
    ) async {
      final _WatchHistoryShowDetailsSeasonsRepository repository =
          _WatchHistoryShowDetailsSeasonsRepository();

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

      await tester.tap(find.text('Season 1'));

      await tester.pumpAndSettle();

      expect(find.text('2×'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey<String>(
            'show-details-episode-watch-history-episode-1-uuid',
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey<String>('delete-episode-watch-event-watch-event-2'),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey<String>('confirm-delete-episode-watch-event'),
        ),
      );

      await tester.pumpAndSettle();

      Navigator.of(tester.element(find.text('Watch history'))).pop();

      await tester.pumpAndSettle();

      expect(find.text('2×'), findsNothing);

      expect(
        find.byKey(
          const ValueKey<String>(
            'show-details-episode-watch-history-episode-1-uuid',
          ),
        ),
        findsOneWidget,
      );

      await cubit.close();
    });
    testWidgets('shows Unwatch choices when Episode has multiple viewings', (
      WidgetTester tester,
    ) async {
      final _WatchHistoryShowDetailsSeasonsRepository repository =
          _WatchHistoryShowDetailsSeasonsRepository();

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      addTearDown(cubit.close);

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          seasons: const <ShowDetailsSeason>[_seasonOne],
        ),
      );

      await tester.tap(find.text('Season 1'));
      await tester.pumpAndSettle();

      expect(find.text('2×'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey<String>('show-details-episode-watched-episode-1-uuid'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mark as not watched?'), findsOneWidget);

      expect(
        find.byKey(
          const ValueKey<String>('show-details-unwatch-remove-latest'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('show-details-unwatch-remove-all')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('show-details-unwatch-cancel')),
        findsOneWidget,
      );

      expect(repository.deleteWatchEventCalls, 0);
      expect(repository.deleteAllWatchEventsCalls, 0);
    });
    testWidgets(
      'cancelling multiple-viewing Unwatch preserves Episode history',
      (WidgetTester tester) async {
        final _WatchHistoryShowDetailsSeasonsRepository repository =
            _WatchHistoryShowDetailsSeasonsRepository();

        final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
          repository: repository,
          showTmdbId: 95396,
        );

        addTearDown(cubit.close);

        await tester.pumpWidget(
          _buildTestApp(
            cubit: cubit,
            seasons: const <ShowDetailsSeason>[_seasonOne],
          ),
        );

        await tester.tap(find.text('Season 1'));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(
            const ValueKey<String>(
              'show-details-episode-watched-episode-1-uuid',
            ),
          ),
        );

        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey<String>('show-details-unwatch-cancel')),
        );

        await tester.pumpAndSettle();

        expect(repository.events, hasLength(2));
        expect(repository.deleteWatchEventCalls, 0);
        expect(repository.deleteAllWatchEventsCalls, 0);

        expect(find.text('2×'), findsOneWidget);
      },
    );
    testWidgets(
      'removes latest viewing from Unwatch choices and keeps Episode watched',
      (WidgetTester tester) async {
        final _WatchHistoryShowDetailsSeasonsRepository repository =
            _WatchHistoryShowDetailsSeasonsRepository();

        final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
          repository: repository,
          showTmdbId: 95396,
        );

        addTearDown(cubit.close);

        await tester.pumpWidget(
          _buildTestApp(
            cubit: cubit,
            seasons: const <ShowDetailsSeason>[_seasonOne],
          ),
        );

        await tester.tap(find.text('Season 1'));
        await tester.pumpAndSettle();

        expect(find.text('2×'), findsOneWidget);

        await tester.tap(
          find.byKey(
            const ValueKey<String>(
              'show-details-episode-watched-episode-1-uuid',
            ),
          ),
        );

        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(
            const ValueKey<String>('show-details-unwatch-remove-latest'),
          ),
        );

        await tester.pumpAndSettle();

        expect(repository.deleteWatchEventCalls, 1);
        expect(repository.deleteAllWatchEventsCalls, 0);

        expect(repository.deletedEpisodeId, 'episode-1-uuid');
        expect(repository.deletedEventId, 'watch-event-2');

        expect(repository.events, hasLength(1));
        expect(repository.events.single.id, 'watch-event-1');

        final ShowDetailsEpisodeProgress progress =
            cubit.state[1]!.episodeProgressById['episode-1-uuid']!;

        expect(progress.isWatched, isTrue);
        expect(progress.watchCount, 1);
        expect(progress.watchedAt, DateTime.utc(2026, 8, 10, 20));

        expect(find.text('2×'), findsNothing);

        expect(
          find.byKey(
            const ValueKey<String>(
              'show-details-episode-watched-episode-1-uuid',
            ),
          ),
          findsOneWidget,
        );
      },
    );
    testWidgets('removes all Episode viewings from Unwatch choices', (
      WidgetTester tester,
    ) async {
      final _WatchHistoryShowDetailsSeasonsRepository repository =
          _WatchHistoryShowDetailsSeasonsRepository();

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      addTearDown(cubit.close);

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          seasons: const <ShowDetailsSeason>[_seasonOne],
        ),
      );

      await tester.tap(find.text('Season 1'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey<String>('show-details-episode-watched-episode-1-uuid'),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('show-details-unwatch-remove-all')),
      );

      await tester.pumpAndSettle();

      expect(repository.deleteAllWatchEventsCalls, 1);
      expect(repository.deleteWatchEventCalls, 0);
      expect(repository.events, isEmpty);

      final ShowDetailsEpisodeProgress? progress =
          cubit.state[1]!.episodeProgressById['episode-1-uuid'];

      if (progress != null) {
        expect(progress.isWatched, isFalse);
        expect(progress.watchCount, 0);
        expect(progress.watchedAt, isNull);
      }

      expect(find.text('2×'), findsNothing);

      expect(
        find.byKey(
          const ValueKey<String>('show-details-episode-rewatch-episode-1-uuid'),
        ),
        findsNothing,
      );
    });
    testWidgets('Unwatch removes the only viewing without showing choices', (
      WidgetTester tester,
    ) async {
      final _WatchHistoryShowDetailsSeasonsRepository repository =
          _WatchHistoryShowDetailsSeasonsRepository(
            events: <ShowDetailsEpisodeWatchEvent>[
              ShowDetailsEpisodeWatchEvent(
                id: 'watch-event-1',
                episodeId: 'episode-1-uuid',
                watchedAt: DateTime.utc(2026, 8, 10, 20),
              ),
            ],
          );

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      addTearDown(cubit.close);

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          seasons: const <ShowDetailsSeason>[_seasonOne],
        ),
      );

      await tester.tap(find.text('Season 1'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey<String>('show-details-episode-watched-episode-1-uuid'),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mark as not watched?'), findsNothing);

      expect(repository.deleteAllWatchEventsCalls, 1);
      expect(repository.deleteWatchEventCalls, 0);
      expect(repository.events, isEmpty);

      expect(
        find.byKey(
          const ValueKey<String>('show-details-episode-rewatch-episode-1-uuid'),
        ),
        findsNothing,
      );
    });
    testWidgets('shows Watch History error without breaking Season contents', (
      WidgetTester tester,
    ) async {
      final _WatchHistoryShowDetailsSeasonsRepository repository =
          _WatchHistoryShowDetailsSeasonsRepository(failLoadingEvents: true);

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

      await tester.tap(find.text('Season 1'));

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey<String>(
            'show-details-episode-watch-history-episode-1-uuid',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Could not load viewing history.'), findsOneWidget);

      expect(find.text('Watch history'), findsOneWidget);

      Navigator.of(tester.element(find.text('Watch history'))).pop();

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('show-details-season-episodes-1')),
        findsOneWidget,
      );

      await cubit.close();
    });
    testWidgets(
      'shows Mark Season Watched action for an incomplete aired Season',
      (WidgetTester tester) async {
        final _SeasonWatchedRepository repository = _SeasonWatchedRepository();

        final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
          repository: repository,
          showTmdbId: 95396,
        );

        addTearDown(cubit.close);

        await cubit.loadInitialProgress();

        await tester.pumpWidget(
          _buildTestApp(
            cubit: cubit,
            seasons: const <ShowDetailsSeason>[_seasonOne],
          ),
        );

        await tester.pump();

        final Finder action = find.byKey(
          const ValueKey<String>('show-details-season-mark-watched-1'),
        );

        expect(action, findsOneWidget);

        final IconButton button = tester.widget<IconButton>(action);

        expect(button.onPressed, isNotNull);

        expect(
          find.byTooltip('Mark aired episodes as watched'),
          findsOneWidget,
        );
      },
    );

    testWidgets('does not show Mark Season Watched when Season is caught up', (
      WidgetTester tester,
    ) async {
      final _SeasonWatchedRepository repository = _SeasonWatchedRepository();

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      addTearDown(cubit.close);

      await cubit.loadInitialProgress();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          seasons: const <ShowDetailsSeason>[_seasonTwo],
        ),
      );

      await tester.pump();

      expect(
        find.byKey(
          const ValueKey<String>('show-details-season-mark-watched-2'),
        ),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('show-details-season-caught-up-2')),
        findsOneWidget,
      );
    });

    testWidgets('marks Season watched and updates its progress', (
      WidgetTester tester,
    ) async {
      final _SeasonWatchedRepository repository = _SeasonWatchedRepository();

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      addTearDown(cubit.close);

      await cubit.loadInitialProgress();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          seasons: const <ShowDetailsSeason>[_seasonOne],
        ),
      );

      await tester.pump();

      expect(find.text('1 of 2 aired episodes'), findsOneWidget);

      await tester.tap(
        find.byKey(
          const ValueKey<String>('show-details-season-mark-watched-1'),
        ),
      );

      await tester.pumpAndSettle();

      expect(repository.markSeasonWatchedCalls, 1);
      expect(repository.markedSeasonIds, <String>['season-1-uuid']);

      expect(find.text('2 of 2 aired episodes'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('show-details-season-caught-up-1')),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('show-details-season-mark-watched-1'),
        ),
        findsNothing,
      );

      final LinearProgressIndicator indicator = tester
          .widget<LinearProgressIndicator>(
            find.byKey(
              const ValueKey<String>('show-details-season-progress-1'),
            ),
          );

      expect(indicator.value, 1);
    });

    testWidgets('shows progress and disables Season action while updating', (
      WidgetTester tester,
    ) async {
      final _PendingSeasonWatchedRepository repository =
          _PendingSeasonWatchedRepository();

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      addTearDown(cubit.close);

      await cubit.loadInitialProgress();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          seasons: const <ShowDetailsSeason>[_seasonOne],
        ),
      );

      await tester.pump();

      final Finder action = find.byKey(
        const ValueKey<String>('show-details-season-mark-watched-1'),
      );

      await tester.tap(action);
      await tester.pump();

      expect(repository.markSeasonWatchedCalls, 1);

      expect(
        find.byKey(
          const ValueKey<String>('show-details-season-mark-watched-progress-1'),
        ),
        findsOneWidget,
      );

      final IconButton button = tester.widget<IconButton>(action);

      expect(
        button.onPressed,
        isNull,
        reason: 'Season mutation must not be triggerable twice.',
      );

      repository.complete();

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('show-details-season-caught-up-1')),
        findsOneWidget,
      );
    });

    testWidgets('shows Retry when Mark Season Watched fails', (
      WidgetTester tester,
    ) async {
      final _FailingSeasonWatchedRepository repository =
          _FailingSeasonWatchedRepository();

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      addTearDown(cubit.close);

      await cubit.loadInitialProgress();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          seasons: const <ShowDetailsSeason>[_seasonOne],
        ),
      );

      await tester.pump();

      await tester.tap(
        find.byKey(
          const ValueKey<String>('show-details-season-mark-watched-1'),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(repository.markSeasonWatchedCalls, 1);

      expect(
        find.byKey(
          const ValueKey<String>('show-details-season-mark-watched-failure-1'),
        ),
        findsOneWidget,
      );

      expect(
        find.text('Could not mark this season as watched.'),
        findsOneWidget,
      );

      expect(find.text('Retry'), findsOneWidget);

      // Failed mutation must preserve the previous progress.
      expect(find.text('1 of 2 aired episodes'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('show-details-season-caught-up-1')),
        findsNothing,
      );
    });

    testWidgets('Retry repeats failed Mark Season Watched operation', (
      WidgetTester tester,
    ) async {
      final _RetrySeasonWatchedRepository repository =
          _RetrySeasonWatchedRepository();

      final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
        repository: repository,
        showTmdbId: 95396,
      );

      addTearDown(cubit.close);

      await cubit.loadInitialProgress();

      await tester.pumpWidget(
        _buildTestApp(
          cubit: cubit,
          seasons: const <ShowDetailsSeason>[_seasonOne],
        ),
      );

      await tester.pump();

      await tester.tap(
        find.byKey(
          const ValueKey<String>('show-details-season-mark-watched-1'),
        ),
      );

      await tester.pumpAndSettle();

      expect(repository.markSeasonWatchedCalls, 1);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));

      await tester.pumpAndSettle();

      expect(repository.markSeasonWatchedCalls, 2);

      expect(find.text('2 of 2 aired episodes'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('show-details-season-caught-up-1')),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('show-details-season-mark-watched-1'),
        ),
        findsNothing,
      );
    });

    testWidgets(
      'refreshes visible Episode states after marking expanded Season watched',
      (WidgetTester tester) async {
        final _ExpandedSeasonWatchedRepository repository =
            _ExpandedSeasonWatchedRepository();

        final ShowDetailsSeasonsCubit cubit = ShowDetailsSeasonsCubit(
          repository: repository,
          showTmdbId: 95396,
        );

        addTearDown(cubit.close);

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

        final IconButton episodeTwoBefore = tester.widget<IconButton>(
          find.byKey(
            const ValueKey<String>(
              'show-details-episode-watched-episode-2-uuid',
            ),
          ),
        );

        expect(
          (episodeTwoBefore.icon as Icon).icon,
          Icons.radio_button_unchecked_rounded,
        );

        await tester.tap(
          find.byKey(
            const ValueKey<String>('show-details-season-mark-watched-1'),
          ),
        );

        await tester.pumpAndSettle();

        expect(repository.markSeasonWatchedCalls, 1);
        expect(repository.getEpisodeProgressAfterMutationCalls, 1);

        final IconButton episodeOneAfter = tester.widget<IconButton>(
          find.byKey(
            const ValueKey<String>(
              'show-details-episode-watched-episode-1-uuid',
            ),
          ),
        );

        final IconButton episodeTwoAfter = tester.widget<IconButton>(
          find.byKey(
            const ValueKey<String>(
              'show-details-episode-watched-episode-2-uuid',
            ),
          ),
        );

        expect((episodeOneAfter.icon as Icon).icon, Icons.check_circle_rounded);

        expect((episodeTwoAfter.icon as Icon).icon, Icons.check_circle_rounded);

        expect(episodeOneAfter.tooltip, 'Mark as not watched');
        expect(episodeTwoAfter.tooltip, 'Mark as not watched');

        expect(
          find.byKey(const ValueKey<String>('show-details-season-caught-up-1')),
          findsOneWidget,
        );
      },
    );
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
          watchCount: 1,
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
  Future<List<ShowDetailsEpisodeWatchEvent>> getEpisodeWatchEvents({
    required String episodeId,
  }) async {
    return const <ShowDetailsEpisodeWatchEvent>[];
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
  }) async {}

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

  @override
  Future<void> deleteAllEpisodeWatchEvents({required String episodeId}) async {}
}

final class _SeasonWatchedRepository extends _FakeShowDetailsSeasonsRepository {
  int markSeasonWatchedCalls = 0;

  final List<String> markedSeasonIds = <String>[];

  @override
  Future<ShowDetailsSeasonProgress> markSeasonWatched({
    required String seasonId,
  }) async {
    markSeasonWatchedCalls++;
    markedSeasonIds.add(seasonId);

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

final class _PendingSeasonWatchedRepository
    extends _FakeShowDetailsSeasonsRepository {
  final Completer<ShowDetailsSeasonProgress> _completer =
      Completer<ShowDetailsSeasonProgress>();

  int markSeasonWatchedCalls = 0;

  @override
  Future<ShowDetailsSeasonProgress> markSeasonWatched({
    required String seasonId,
  }) {
    markSeasonWatchedCalls++;

    return _completer.future;
  }

  void complete() {
    if (_completer.isCompleted) {
      return;
    }

    _completer.complete(
      const ShowDetailsSeasonProgress(
        seasonId: 'season-1-uuid',
        watchedEpisodes: 2,
        totalEpisodes: 2,
        progressPercentage: 100,
        airedEpisodes: 2,
        watchedAiredEpisodes: 2,
        airedProgressPercentage: 100,
        caughtUp: true,
      ),
    );
  }
}

final class _FailingSeasonWatchedRepository
    extends _FakeShowDetailsSeasonsRepository {
  int markSeasonWatchedCalls = 0;

  @override
  Future<ShowDetailsSeasonProgress> markSeasonWatched({
    required String seasonId,
  }) async {
    markSeasonWatchedCalls++;

    throw const AppException.connection();
  }
}

final class _RetrySeasonWatchedRepository
    extends _FakeShowDetailsSeasonsRepository {
  int markSeasonWatchedCalls = 0;

  @override
  Future<ShowDetailsSeasonProgress> markSeasonWatched({
    required String seasonId,
  }) async {
    markSeasonWatchedCalls++;

    if (markSeasonWatchedCalls == 1) {
      throw const AppException.connection();
    }

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

final class _ExpandedSeasonWatchedRepository
    extends _FakeShowDetailsSeasonsRepository {
  bool _seasonWasMarkedWatched = false;

  int markSeasonWatchedCalls = 0;
  int getEpisodeProgressAfterMutationCalls = 0;

  @override
  Future<ShowDetailsSeasonProgress> markSeasonWatched({
    required String seasonId,
  }) async {
    markSeasonWatchedCalls++;
    _seasonWasMarkedWatched = true;

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

  @override
  Future<List<ShowDetailsEpisodeProgress>> getEpisodeProgress({
    required String seasonId,
  }) async {
    if (!_seasonWasMarkedWatched) {
      return super.getEpisodeProgress(seasonId: seasonId);
    }

    getEpisodeProgressAfterMutationCalls++;

    return <ShowDetailsEpisodeProgress>[
      ShowDetailsEpisodeProgress(
        id: 'progress-1-uuid',
        episodeId: 'episode-1-uuid',
        isWatched: true,
        watchCount: 1,
        watchedAt: DateTime.utc(2026, 8, 10, 12),
      ),
      ShowDetailsEpisodeProgress(
        id: 'progress-2-uuid',
        episodeId: 'episode-2-uuid',
        isWatched: true,
        watchCount: 1,
        watchedAt: DateTime.utc(2026, 8, 16, 12),
      ),
    ];
  }
}

final class _WatchHistoryShowDetailsSeasonsRepository
    extends _FakeShowDetailsSeasonsRepository {
  _WatchHistoryShowDetailsSeasonsRepository({
    List<ShowDetailsEpisodeWatchEvent>? events,
    this.failLoadingEvents = false,
  }) : events = List<ShowDetailsEpisodeWatchEvent>.of(
         events ??
             <ShowDetailsEpisodeWatchEvent>[
               ShowDetailsEpisodeWatchEvent(
                 id: 'watch-event-2',
                 episodeId: 'episode-1-uuid',
                 watchedAt: DateTime.utc(2026, 8, 14, 21, 30),
               ),
               ShowDetailsEpisodeWatchEvent(
                 id: 'watch-event-1',
                 episodeId: 'episode-1-uuid',
                 watchedAt: DateTime.utc(2026, 8, 10, 20, 0),
               ),
             ],
       );

  final List<ShowDetailsEpisodeWatchEvent> events;

  final bool failLoadingEvents;

  int getWatchEventsCalls = 0;
  int deleteWatchEventCalls = 0;
  int deleteAllWatchEventsCalls = 0;

  String? deletedEpisodeId;
  String? deletedEventId;

  @override
  Future<List<ShowDetailsEpisodeProgress>> getEpisodeProgress({
    required String seasonId,
  }) async {
    if (seasonId != 'season-1-uuid') {
      return const <ShowDetailsEpisodeProgress>[];
    }

    final List<ShowDetailsEpisodeWatchEvent> episodeEvents = events
        .where(
          (ShowDetailsEpisodeWatchEvent event) =>
              event.episodeId == 'episode-1-uuid',
        )
        .toList(growable: false);

    if (episodeEvents.isEmpty) {
      return const <ShowDetailsEpisodeProgress>[];
    }

    final ShowDetailsEpisodeWatchEvent latest = episodeEvents.reduce((
      ShowDetailsEpisodeWatchEvent current,
      ShowDetailsEpisodeWatchEvent candidate,
    ) {
      return candidate.watchedAt.isAfter(current.watchedAt)
          ? candidate
          : current;
    });

    return <ShowDetailsEpisodeProgress>[
      ShowDetailsEpisodeProgress(
        id: 'progress-1-uuid',
        episodeId: 'episode-1-uuid',
        isWatched: true,
        watchCount: episodeEvents.length,
        watchedAt: latest.watchedAt,
      ),
    ];
  }

  @override
  Future<List<ShowDetailsEpisodeWatchEvent>> getEpisodeWatchEvents({
    required String episodeId,
  }) async {
    getWatchEventsCalls++;

    if (failLoadingEvents) {
      throw const AppException.connection();
    }

    return events
        .where(
          (ShowDetailsEpisodeWatchEvent event) => event.episodeId == episodeId,
        )
        .toList(growable: false);
  }

  @override
  Future<void> deleteEpisodeWatchEvent({
    required String episodeId,
    required String eventId,
  }) async {
    deleteWatchEventCalls++;

    deletedEpisodeId = episodeId;
    deletedEventId = eventId;

    events.removeWhere(
      (ShowDetailsEpisodeWatchEvent event) =>
          event.id == eventId && event.episodeId == episodeId,
    );
  }

  @override
  Future<void> deleteAllEpisodeWatchEvents({required String episodeId}) async {
    deleteAllWatchEventsCalls++;

    events.removeWhere(
      (ShowDetailsEpisodeWatchEvent event) => event.episodeId == episodeId,
    );
  }

  @override
  Future<ShowDetailsSeasonProgress> getSeasonProgress({
    required String seasonId,
  }) async {
    if (seasonId != 'season-1-uuid') {
      return super.getSeasonProgress(seasonId: seasonId);
    }

    final bool watched = events.any(
      (ShowDetailsEpisodeWatchEvent event) =>
          event.episodeId == 'episode-1-uuid',
    );

    return ShowDetailsSeasonProgress(
      seasonId: 'season-1-uuid',
      watchedEpisodes: watched ? 1 : 0,
      totalEpisodes: 2,
      progressPercentage: watched ? 50 : 0,
      airedEpisodes: 2,
      watchedAiredEpisodes: watched ? 1 : 0,
      airedProgressPercentage: watched ? 50 : 0,
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
      watchCount: 1,
      watchedAt: DateTime.utc(2026, 8, 11),
    );
  }
}

final ShowDetailsEpisode _episodeWithStill = ShowDetailsEpisode(
  id: 'episode-with-still-uuid',
  tmdbId: 900001,
  episodeNumber: 1,
  title: 'A Very Important Episode',
  overview: 'This overview must not appear in the Season list.',
  airDate: DateTime(2026, 8, 10),
  runtime: 52,
  stillUrl: 'https://example.com/episode.jpg',
  voteAverage: 8.5,
  voteCount: 100,
);

final class _EpisodeStillRepository extends _FakeShowDetailsSeasonsRepository {
  @override
  Future<List<ShowDetailsEpisode>> getEpisodes({
    required String seasonId,
  }) async {
    if (seasonId == 'season-1-uuid') {
      return <ShowDetailsEpisode>[_episodeWithStill];
    }

    return super.getEpisodes(seasonId: seasonId);
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
}
