import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/shows/application/cubit/shows_cubit.dart';
import 'package:sofawatch/features/shows/domain/models/library_show.dart';
import 'package:sofawatch/features/shows/domain/models/stale_watching_show.dart';
import 'package:sofawatch/features/shows/domain/models/watch_history_item.dart';
import 'package:sofawatch/features/shows/domain/models/watch_history_page.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_episode.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_progress.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_show.dart';
import 'package:sofawatch/features/shows/domain/repositories/shows_repository.dart';
import 'package:sofawatch/features/shows/presentation/pages/shows_page.dart';
import 'package:sofawatch/features/shows/domain/models/stale_watching_episode.dart';
import 'package:sofawatch/features/shows/domain/models/watch_history_episode.dart';
import 'package:sofawatch/features/shows/domain/models/library_first_episode.dart';

void main() {
  group('ShowsPage', () {
    testWidgets('shows Watch List and Upcoming tabs', (
      WidgetTester tester,
    ) async {
      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(
          shows: <LibraryShow>[_show],
          watchNext: <WatchNextShow>[_watchNextShow],
        ),
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('shows-page-title')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('shows-tab-watch-list')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('shows-tab-upcoming')),
        findsOneWidget,
      );

      expect(find.text('Watch List'), findsOneWidget);

      expect(find.text('Upcoming'), findsOneWidget);
    });

    testWidgets('opens Watch List by default', (WidgetTester tester) async {
      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(
          shows: <LibraryShow>[_show],
          watchNext: <WatchNextShow>[_watchNextShow],
        ),
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pumpAndSettle();

      final TabBar tabBar = tester.widget<TabBar>(
        find.byKey(const ValueKey<String>('shows-tabs')),
      );

      expect(tabBar.controller?.index, 0);

      expect(
        find.byKey(const ValueKey<String>('shows-watch-list')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('shows-watch-next-section')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('shows-watch-next-95396')),
        findsOneWidget,
      );

      expect(find.text('Watch Next'), findsOneWidget);

      expect(find.text('Severance'), findsOneWidget);

      expect(find.text("Woe's Hollow"), findsOneWidget);

      expect(find.textContaining('S02E04'), findsOneWidget);

      expect(find.textContaining('52 min'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('shows-watch-next-progress-95396')),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('shows-watch-next-progress-label-95396'),
        ),
        findsOneWidget,
      );

      expect(find.text('7/10'), findsOneWidget);
      final LinearProgressIndicator progressIndicator = tester
          .widget<LinearProgressIndicator>(
            find.byKey(
              const ValueKey<String>('shows-watch-next-progress-95396'),
            ),
          );

      expect(progressIndicator.value, 0.7);
    });

    testWidgets('switches from Watch List to Upcoming', (
      WidgetTester tester,
    ) async {
      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(
          shows: <LibraryShow>[_show],
          watchNext: <WatchNextShow>[_watchNextShow],
        ),
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('shows-tab-upcoming')),
      );

      await tester.pumpAndSettle();

      final TabBar tabBar = tester.widget<TabBar>(
        find.byKey(const ValueKey<String>('shows-tabs')),
      );

      expect(tabBar.controller?.index, 1);

      expect(
        find.byKey(const ValueKey<String>('shows-upcoming-empty')),
        findsOneWidget,
      );

      expect(find.text('No upcoming episodes'), findsOneWidget);
    });

    testWidgets('switches back from Upcoming to Watch List', (
      WidgetTester tester,
    ) async {
      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(
          shows: <LibraryShow>[_show],
          watchNext: <WatchNextShow>[_watchNextShow],
        ),
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('shows-tab-upcoming')),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('shows-upcoming-empty')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('shows-tab-watch-list')),
      );

      await tester.pumpAndSettle();

      final TabBar tabBar = tester.widget<TabBar>(
        find.byKey(const ValueKey<String>('shows-tabs')),
      );

      expect(tabBar.controller?.index, 0);

      expect(
        find.byKey(const ValueKey<String>('shows-watch-list')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('shows-watch-next-95396')),
        findsOneWidget,
      );

      expect(find.text('Severance'), findsOneWidget);
    });

    testWidgets('shows Watch Next empty state when no Episode is available', (
      WidgetTester tester,
    ) async {
      final ShowsCubit cubit = ShowsCubit(
        repository: const _FakeShowsRepository(
          shows: <LibraryShow>[],
          watchNext: <WatchNextShow>[],
        ),
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('shows-watch-list')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('shows-watch-next-empty')),
        findsOneWidget,
      );

      expect(find.text('You are all caught up.'), findsOneWidget);
    });

    testWidgets('preserves selected tab while Details is pushed and popped', (
      WidgetTester tester,
    ) async {
      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(
          shows: <LibraryShow>[_show],
          watchNext: <WatchNextShow>[_watchNextShow],
        ),
      );

      addTearDown(cubit.close);

      await cubit.load();

      final GoRouter router = _buildRouter(cubit: cubit);

      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('shows-tab-upcoming')),
      );

      await tester.pumpAndSettle();

      TabBar tabBar = tester.widget<TabBar>(
        find.byKey(const ValueKey<String>('shows-tabs')),
      );

      expect(tabBar.controller?.index, 1);

      expect(
        find.byKey(const ValueKey<String>('shows-upcoming-empty')),
        findsOneWidget,
      );

      router.pushNamed(
        AppRoute.showDetails.name,
        pathParameters: <String, String>{'showId': '95396'},
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('fake-show-details')),
        findsOneWidget,
      );

      router.pop();

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('shows-page-title')),
        findsOneWidget,
      );

      tabBar = tester.widget<TabBar>(
        find.byKey(const ValueKey<String>('shows-tabs')),
      );

      expect(
        tabBar.controller?.index,
        1,
        reason: 'Returning from Details must preserve the selected Shows tab.',
      );

      expect(
        find.byKey(const ValueKey<String>('shows-upcoming-empty')),
        findsOneWidget,
      );
    });

    testWidgets('opens Show Details from Watch Next', (
      WidgetTester tester,
    ) async {
      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(
          shows: <LibraryShow>[_show],
          watchNext: <WatchNextShow>[_watchNextShow],
        ),
      );

      addTearDown(cubit.close);

      await cubit.load();

      final GoRouter router = _buildRouter(cubit: cubit);

      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('shows-watch-next-95396')),
      );

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('fake-show-details')),
        findsOneWidget,
      );

      expect(find.text('Show 95396'), findsOneWidget);
    });

    testWidgets('shows Watch Next failure without failing the whole page', (
      WidgetTester tester,
    ) async {
      final _WatchNextFailureRepository repository =
          _WatchNextFailureRepository(shows: <LibraryShow>[_show]);

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('shows-watch-list')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('shows-watch-next-failure')),
        findsOneWidget,
      );

      expect(find.text('Could not load Watch Next.'), findsOneWidget);

      expect(find.byKey(const ValueKey<String>('shows-failure')), findsNothing);
    });

    testWidgets('retries only Watch Next after partial failure', (
      WidgetTester tester,
    ) async {
      final _RetryWatchNextRepository repository = _RetryWatchNextRepository(
        shows: <LibraryShow>[_show],
      );

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pumpAndSettle();

      expect(repository.libraryCalls, 1);

      expect(repository.watchNextCalls, 1);

      expect(
        find.byKey(const ValueKey<String>('shows-watch-next-failure')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('shows-watch-next-retry')),
      );

      await tester.pumpAndSettle();

      expect(
        repository.libraryCalls,
        1,
        reason: 'Retrying Watch Next must not reload the complete Library.',
      );

      expect(repository.watchNextCalls, 2);

      expect(
        find.byKey(const ValueKey<String>('shows-watch-next-failure')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('shows-watch-next-95396')),
        findsOneWidget,
      );
    });

    testWidgets('shows loading state', (WidgetTester tester) async {
      final _PendingShowsRepository repository = _PendingShowsRepository();

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      addTearDown(cubit.close);

      final Future<void> loading = cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('shows-loading')),
        findsOneWidget,
      );

      repository.complete(<LibraryShow>[_show]);

      await loading;
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('shows-watch-list')),
        findsOneWidget,
      );
    });
    testWidgets('renders Haven\'t Watched in a While section', (
      WidgetTester tester,
    ) async {
      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(
          shows: <LibraryShow>[_show],
          staleWatching: <StaleWatchingShow>[_staleWatchingShow],
        ),
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('shows-stale-watching-section')),
        findsOneWidget,
      );

      expect(find.text("Haven't Watched in a While"), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('shows-stale-watching-100088')),
        findsOneWidget,
      );

      expect(find.text('The Last of Us'), findsOneWidget);

      expect(find.textContaining('S01E04'), findsOneWidget);

      expect(find.text('Please Hold to My Hand'), findsOneWidget);
    });

    testWidgets('does not duplicate stale Show in Watch Next', (
      WidgetTester tester,
    ) async {
      final StaleWatchingShow staleVersion = StaleWatchingShow(
        libraryEntryId: 'library-entry-uuid',
        libraryStatus: LibraryStatus.watching,
        showId: 'show-uuid',
        showTmdbId: 95396,
        showTitle: 'Severance',
        posterUrl: null,
        backdropUrl: null,
        lastWatched: StaleWatchingEpisode(
          id: 'episode-last',
          tmdbId: 1947647,
          seasonNumber: 2,
          episodeNumber: 3,
          title: 'Who Is Alive?',
          watchedAt: DateTime.utc(2026, 5, 1),
        ),
        nextEpisode: WatchNextEpisode(
          id: 'episode-next',
          tmdbId: 1947648,
          seasonNumber: 2,
          episodeNumber: 4,
          title: "Woe's Hollow",
          runtime: 52,
        ),
      );

      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(
          shows: <LibraryShow>[_show],
          watchNext: <WatchNextShow>[_watchNextShow],
          staleWatching: <StaleWatchingShow>[staleVersion],
        ),
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('shows-watch-next-95396')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('shows-stale-watching-95396')),
        findsOneWidget,
      );

      expect(find.text('Severance'), findsOneWidget);
    });

    testWidgets('opens Show Details from stale Watching', (
      WidgetTester tester,
    ) async {
      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(
          shows: <LibraryShow>[_show],
          staleWatching: <StaleWatchingShow>[_staleWatchingShow],
        ),
      );

      addTearDown(cubit.close);

      await cubit.load();

      final GoRouter router = _buildRouter(cubit: cubit);

      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      await tester.pumpAndSettle();

      final Finder staleCard = find.byKey(
        const ValueKey<String>('shows-stale-watching-100088'),
      );

      await tester.ensureVisible(staleCard);
      await tester.pumpAndSettle();

      await tester.tap(staleCard);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('fake-show-details')),
        findsOneWidget,
      );

      expect(find.text('Show 100088'), findsOneWidget);
    });
    testWidgets('shows stale Watching failure without breaking Watch Next', (
      WidgetTester tester,
    ) async {
      final ShowsCubit cubit = ShowsCubit(
        repository: _StaleWatchingFailureRepository(
          shows: <LibraryShow>[_show],
          watchNext: <WatchNextShow>[_watchNextShow],
        ),
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('shows-watch-next-95396')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('shows-stale-watching-failure')),
        findsOneWidget,
      );

      expect(find.byKey(const ValueKey<String>('shows-failure')), findsNothing);
    });
    testWidgets('retries only stale Watching after partial failure', (
      WidgetTester tester,
    ) async {
      final _RetryStaleWatchingRepository repository =
          _RetryStaleWatchingRepository(
            shows: <LibraryShow>[_show],
            watchNext: <WatchNextShow>[_watchNextShow],
          );

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pumpAndSettle();

      expect(repository.libraryCalls, 1);
      expect(repository.watchNextCalls, 1);
      expect(repository.staleWatchingCalls, 1);

      expect(
        find.byKey(const ValueKey<String>('shows-stale-watching-failure')),
        findsOneWidget,
      );

      final Finder retryButton = find.byKey(
        const ValueKey<String>('shows-stale-watching-retry'),
      );

      await tester.ensureVisible(retryButton);
      await tester.pumpAndSettle();

      await tester.tap(retryButton);
      await tester.pumpAndSettle();

      expect(repository.libraryCalls, 1);

      expect(repository.watchNextCalls, 1);

      expect(repository.staleWatchingCalls, 2);

      expect(
        find.byKey(const ValueKey<String>('shows-stale-watching-failure')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('shows-stale-watching-100088')),
        findsOneWidget,
      );
    });
    testWidgets('shows stale Watching empty state', (
      WidgetTester tester,
    ) async {
      final ShowsCubit cubit = ShowsCubit(
        repository: const _FakeShowsRepository(
          shows: <LibraryShow>[],
          watchNext: <WatchNextShow>[],
          staleWatching: <StaleWatchingShow>[],
        ),
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('shows-stale-watching-empty')),
        findsOneWidget,
      );

      expect(find.text('No forgotten shows right now.'), findsOneWidget);
    });
    testWidgets('renders Haven\'t Started planning Shows', (
      WidgetTester tester,
    ) async {
      final LibraryShow planningShow = LibraryShow(
        libraryEntryId: 'library-planning',
        showId: 'show-planning',
        tmdbId: 1396,
        title: 'Breaking Bad',
        originalTitle: 'Breaking Bad',
        firstAirDate: DateTime(2008, 1, 20),
        posterUrl: null,
        backdropUrl: null,
        status: LibraryStatus.planning,
        showStatus: 'Ended',
        voteAverage: 8.9,
        createdAt: DateTime.utc(2026, 8, 1),
        updatedAt: DateTime.utc(2026, 8, 10),
        firstAvailableEpisode: LibraryFirstEpisode(
          id: 'episode-first',
          tmdbId: 62085,
          seasonNumber: 1,
          episodeNumber: 1,
          title: 'Pilot',
          airDate: DateTime(2008, 1, 20),
          runtime: 58,
        ),
      );

      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(
          shows: <LibraryShow>[_show, planningShow],
          watchNext: <WatchNextShow>[_watchNextShow],
        ),
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pumpAndSettle();

      final Finder section = find.byKey(
        const ValueKey<String>('shows-havent-started-section'),
      );

      await tester.ensureVisible(section);
      await tester.pumpAndSettle();

      expect(section, findsOneWidget);

      expect(find.text("Haven't Started"), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('shows-havent-started-1396')),
        findsOneWidget,
      );

      expect(find.text('Breaking Bad'), findsOneWidget);

      expect(find.text('S01E01 • 58 min'), findsOneWidget);
      expect(find.text('Pilot'), findsOneWidget);

      expect(
        find.byKey(
          const ValueKey<String>('shows-havent-started-episode-code-1396'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('shows-havent-started-episode-title-1396'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('shows-havent-started-start-1396')),
        findsOneWidget,
      );

      expect(find.text('Start'), findsOneWidget);
    });

    testWidgets(
      'shows loading state while starting a Show and prevents duplicate starts',
      (WidgetTester tester) async {
        final LibraryShow planningShow = LibraryShow(
          libraryEntryId: 'library-planning',
          showId: 'show-planning',
          tmdbId: 1396,
          title: 'Breaking Bad',
          originalTitle: 'Breaking Bad',
          status: LibraryStatus.planning,
          showStatus: 'Ended',
          voteAverage: 8.9,
          createdAt: DateTime.utc(2026, 8, 1),
          updatedAt: DateTime.utc(2026, 8, 10),
          firstAvailableEpisode: LibraryFirstEpisode(
            id: 'episode-first',
            tmdbId: 62085,
            seasonNumber: 1,
            episodeNumber: 1,
            title: 'Pilot',
            airDate: DateTime(2008, 1, 20),
            runtime: 58,
          ),
        );

        final _PendingStartShowRepository repository =
            _PendingStartShowRepository(planningShow: planningShow);

        final ShowsCubit cubit = ShowsCubit(repository: repository);

        addTearDown(cubit.close);

        await cubit.load();

        await tester.pumpWidget(_buildTestApp(cubit: cubit));
        await tester.pumpAndSettle();

        final Finder startButton = find.byKey(
          const ValueKey<String>('shows-havent-started-start-1396'),
        );

        await tester.ensureVisible(startButton);
        await tester.pumpAndSettle();

        await tester.tap(startButton);
        await tester.pump();

        expect(repository.startShowCalls, 1);

        expect(find.text('Starting…'), findsOneWidget);

        expect(
          find.byKey(
            const ValueKey<String>('shows-havent-started-start-progress'),
          ),
          findsOneWidget,
        );

        final FilledButton button = tester.widget<FilledButton>(startButton);

        expect(button.onPressed, isNull);

        await tester.tap(startButton);
        await tester.pump();

        expect(
          repository.startShowCalls,
          1,
          reason: 'A pending Start operation must not be submitted twice.',
        );

        repository.completeStart();

        await tester.pumpAndSettle();
      },
    );

    testWidgets('moves a successfully started Show out of Haven\'t Started', (
      WidgetTester tester,
    ) async {
      final LibraryShow planningShow = LibraryShow(
        libraryEntryId: 'library-planning',
        showId: 'show-planning',
        tmdbId: 1396,
        title: 'Breaking Bad',
        originalTitle: 'Breaking Bad',
        status: LibraryStatus.planning,
        showStatus: 'Ended',
        voteAverage: 8.9,
        createdAt: DateTime.utc(2026, 8, 1),
        updatedAt: DateTime.utc(2026, 8, 10),
        firstAvailableEpisode: LibraryFirstEpisode(
          id: 'episode-first',
          tmdbId: 62085,
          seasonNumber: 1,
          episodeNumber: 1,
          title: 'Pilot',
          airDate: DateTime(2008, 1, 20),
          runtime: 58,
        ),
      );

      final _SuccessfulStartShowRepository repository =
          _SuccessfulStartShowRepository(planningShow: planningShow);

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      final Finder startButton = find.byKey(
        const ValueKey<String>('shows-havent-started-start-1396'),
      );

      await tester.ensureVisible(startButton);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('shows-havent-started-1396')),
        findsOneWidget,
      );

      await tester.tap(startButton);
      await tester.pumpAndSettle();

      expect(repository.startShowCalls, 1);
      expect(repository.startedShowIds, <String>['show-planning']);

      expect(
        find.byKey(const ValueKey<String>('shows-havent-started-1396')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('shows-havent-started-empty')),
        findsOneWidget,
      );
    });

    testWidgets('preserves Haven\'t Started Show when Start fails', (
      WidgetTester tester,
    ) async {
      final LibraryShow planningShow = LibraryShow(
        libraryEntryId: 'library-planning',
        showId: 'show-planning',
        tmdbId: 1396,
        title: 'Breaking Bad',
        originalTitle: 'Breaking Bad',
        status: LibraryStatus.planning,
        showStatus: 'Ended',
        voteAverage: 8.9,
        createdAt: DateTime.utc(2026, 8, 1),
        updatedAt: DateTime.utc(2026, 8, 10),
        firstAvailableEpisode: LibraryFirstEpisode(
          id: 'episode-first',
          tmdbId: 62085,
          seasonNumber: 1,
          episodeNumber: 1,
          title: 'Pilot',
          airDate: DateTime(2008, 1, 20),
          runtime: 58,
        ),
      );

      final _FailingStartShowRepository repository =
          _FailingStartShowRepository(planningShow: planningShow);

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      final Finder startButton = find.byKey(
        const ValueKey<String>('shows-havent-started-start-1396'),
      );

      await tester.ensureVisible(startButton);
      await tester.pumpAndSettle();

      await tester.tap(startButton);
      await tester.pumpAndSettle();

      expect(repository.startShowCalls, 1);

      expect(
        find.byKey(const ValueKey<String>('shows-havent-started-1396')),
        findsOneWidget,
      );

      expect(find.text('Start'), findsOneWidget);

      expect(find.text('Could not start this show.'), findsOneWidget);
    });

    testWidgets('shows Haven\'t Started empty state without planning Shows', (
      WidgetTester tester,
    ) async {
      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(
          shows: <LibraryShow>[_show],
          watchNext: <WatchNextShow>[_watchNextShow],
        ),
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pumpAndSettle();

      final Finder emptyState = find.byKey(
        const ValueKey<String>('shows-havent-started-empty'),
      );

      await tester.ensureVisible(emptyState);
      await tester.pumpAndSettle();

      expect(emptyState, findsOneWidget);

      expect(
        find.text('No unstarted shows in your Watchlist.'),
        findsOneWidget,
      );
    });

    testWidgets('Haven\'t Started excludes non-planning Shows', (
      WidgetTester tester,
    ) async {
      final LibraryShow planningShow = LibraryShow(
        libraryEntryId: 'library-planning',
        showId: 'show-planning',
        tmdbId: 1396,
        title: 'Breaking Bad',
        originalTitle: 'Breaking Bad',
        status: LibraryStatus.planning,
        showStatus: 'Ended',
        voteAverage: 8.9,
        createdAt: DateTime.utc(2026, 8, 1),
        updatedAt: DateTime.utc(2026, 8, 10),
      );

      final LibraryShow completedShow = LibraryShow(
        libraryEntryId: 'library-completed',
        showId: 'show-completed',
        tmdbId: 66732,
        title: 'Stranger Things',
        originalTitle: 'Stranger Things',
        status: LibraryStatus.completed,
        showStatus: 'Ended',
        voteAverage: 8.6,
        createdAt: DateTime.utc(2026, 8, 1),
        updatedAt: DateTime.utc(2026, 8, 10),
      );

      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(
          shows: <LibraryShow>[_show, planningShow, completedShow],
          watchNext: <WatchNextShow>[_watchNextShow],
        ),
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pumpAndSettle();

      final Finder section = find.byKey(
        const ValueKey<String>('shows-havent-started-section'),
      );

      await tester.ensureVisible(section);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('shows-havent-started-1396')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('shows-havent-started-95396')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('shows-havent-started-66732')),
        findsNothing,
      );
    });

    testWidgets('opens Show Details from Haven\'t Started', (
      WidgetTester tester,
    ) async {
      final LibraryShow planningShow = LibraryShow(
        libraryEntryId: 'library-planning',
        showId: 'show-planning',
        tmdbId: 1396,
        title: 'Breaking Bad',
        originalTitle: 'Breaking Bad',
        firstAirDate: DateTime(2008, 1, 20),
        posterUrl: null,
        backdropUrl: null,
        status: LibraryStatus.planning,
        showStatus: 'Ended',
        voteAverage: 8.9,
        createdAt: DateTime.utc(2026, 8, 1),
        updatedAt: DateTime.utc(2026, 8, 10),
      );

      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(
          shows: <LibraryShow>[_show, planningShow],
          watchNext: <WatchNextShow>[_watchNextShow],
        ),
      );

      addTearDown(cubit.close);

      await cubit.load();

      final GoRouter router = _buildRouter(cubit: cubit);

      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      await tester.pumpAndSettle();

      final Finder planningCard = find.byKey(
        const ValueKey<String>('shows-havent-started-1396'),
      );

      await tester.ensureVisible(planningCard);
      await tester.pumpAndSettle();

      await tester.tap(planningCard);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('fake-show-details')),
        findsOneWidget,
      );

      expect(find.text('Show 1396'), findsOneWidget);
    });
    testWidgets('loads Watch History when scrolling near the bottom', (
      WidgetTester tester,
    ) async {
      final _WatchHistoryTrackingRepository repository =
          _WatchHistoryTrackingRepository(
            shows: <LibraryShow>[_show],
            firstPage: WatchHistoryPage(
              items: <WatchHistoryItem>[
                _watchHistoryItem(
                  episodeId: 'history-1',
                  episodeNumber: 4,
                  title: "Woe's Hollow",
                ),
              ],
              nextCursor: null,
              hasMore: false,
            ),
          );

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      expect(repository.watchHistoryCalls, 0);

      await _scrollWatchListNearBottom(tester);

      expect(repository.watchHistoryCalls, 1);

      expect(
        find.byKey(const ValueKey<String>('shows-watch-history-history-1')),
        findsOneWidget,
      );

      expect(find.text("Woe's Hollow"), findsOneWidget);
      expect(find.textContaining('S02E04'), findsOneWidget);
    });

    testWidgets('loads more Watch History while preserving existing items', (
      WidgetTester tester,
    ) async {
      final _PaginatedWatchHistoryRepository repository =
          _PaginatedWatchHistoryRepository(shows: <LibraryShow>[_show]);

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      await _scrollWatchListNearBottom(tester);

      expect(repository.watchHistoryCalls, 1);

      expect(
        find.byKey(const ValueKey<String>('shows-watch-history-history-1')),
        findsOneWidget,
      );

      await _scrollWatchListNearBottom(tester);

      expect(repository.watchHistoryCalls, 2);

      expect(
        find.byKey(const ValueKey<String>('shows-watch-history-history-1')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('shows-watch-history-history-2')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('shows-watch-history-end')),
        findsOneWidget,
      );
    });

    testWidgets('shows Watch History empty state without retry loop', (
      WidgetTester tester,
    ) async {
      final _WatchHistoryTrackingRepository repository =
          _WatchHistoryTrackingRepository(
            shows: <LibraryShow>[_show],
            firstPage: const WatchHistoryPage(
              items: <WatchHistoryItem>[],
              nextCursor: null,
              hasMore: false,
            ),
          );

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      await _scrollWatchListNearBottom(tester);

      expect(repository.watchHistoryCalls, 1);

      expect(
        find.byKey(const ValueKey<String>('shows-watch-history-empty')),
        findsOneWidget,
      );

      await _scrollWatchListNearBottom(tester);

      expect(
        repository.watchHistoryCalls,
        1,
        reason: 'An empty loaded History must not be requested repeatedly.',
      );
    });

    testWidgets('retries initial Watch History failure', (
      WidgetTester tester,
    ) async {
      final _RetryWatchHistoryRepository repository =
          _RetryWatchHistoryRepository(shows: <LibraryShow>[_show]);

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      await _scrollWatchListNearBottom(tester);

      expect(repository.watchHistoryCalls, 1);

      expect(
        find.byKey(const ValueKey<String>('shows-watch-history-failure')),
        findsOneWidget,
      );

      final Finder retryButton = find.byKey(
        const ValueKey<String>('shows-watch-history-retry'),
      );

      await tester.ensureVisible(retryButton);
      await tester.pumpAndSettle();

      await tester.tap(retryButton);
      await tester.pumpAndSettle();

      expect(repository.watchHistoryCalls, 2);

      expect(
        find.byKey(const ValueKey<String>('shows-watch-history-failure')),
        findsNothing,
      );

      expect(
        find.byKey(const ValueKey<String>('shows-watch-history-history-1')),
        findsOneWidget,
      );
    });

    testWidgets('preserves Watch History and retries failed pagination', (
      WidgetTester tester,
    ) async {
      final _RetryWatchHistoryPaginationRepository repository =
          _RetryWatchHistoryPaginationRepository(shows: <LibraryShow>[_show]);

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      await _scrollWatchListNearBottom(tester);

      expect(repository.watchHistoryCalls, 1);

      expect(
        find.byKey(const ValueKey<String>('shows-watch-history-history-1')),
        findsOneWidget,
      );

      await _scrollWatchListNearBottom(tester);

      expect(repository.watchHistoryCalls, 2);

      expect(
        find.byKey(const ValueKey<String>('shows-watch-history-history-1')),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('shows-watch-history-load-more-failure'),
        ),
        findsOneWidget,
      );

      final Finder retryButton = find.byKey(
        const ValueKey<String>('shows-watch-history-load-more-retry'),
      );

      await tester.ensureVisible(retryButton);
      await tester.pumpAndSettle();

      await tester.tap(retryButton);
      await tester.pumpAndSettle();

      expect(repository.watchHistoryCalls, 3);

      expect(
        find.byKey(const ValueKey<String>('shows-watch-history-history-1')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('shows-watch-history-history-2')),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('shows-watch-history-load-more-failure'),
        ),
        findsNothing,
      );
    });
    testWidgets('marks Watch Next Episode as watched', (
      WidgetTester tester,
    ) async {
      final _MarkWatchNextRepository repository = _MarkWatchNextRepository(
        shows: <LibraryShow>[_show],
        watchNext: <WatchNextShow>[_watchNextShow],
      );

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      final Finder markWatchedButton = find.byKey(
        const ValueKey<String>('shows-watch-next-mark-watched-episode-uuid'),
      );

      expect(markWatchedButton, findsOneWidget);

      await tester.tap(markWatchedButton);
      await tester.pumpAndSettle();

      expect(repository.markEpisodeWatchedCalls, 1);
      expect(repository.markedEpisodeIds, <String>['episode-uuid']);

      expect(
        repository.watchNextCalls,
        2,
        reason: 'Watch Next must refresh after marking an Episode as watched.',
      );

      expect(
        repository.staleWatchingCalls,
        2,
        reason: 'Stale Watching may also change after watching an Episode.',
      );
    });
    testWidgets('shows loading only for the Watch Next Episode being updated', (
      WidgetTester tester,
    ) async {
      final _PendingMarkWatchNextRepository repository =
          _PendingMarkWatchNextRepository(
            shows: <LibraryShow>[_show],
            watchNext: <WatchNextShow>[_watchNextShow],
          );

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      final Finder markWatchedButton = find.byKey(
        const ValueKey<String>('shows-watch-next-mark-watched-episode-uuid'),
      );

      await tester.tap(markWatchedButton);
      await tester.pump();

      expect(repository.markEpisodeWatchedCalls, 1);

      expect(
        find.byKey(
          const ValueKey<String>(
            'shows-watch-next-mark-watched-loading-episode-uuid',
          ),
        ),
        findsOneWidget,
      );

      expect(markWatchedButton, findsNothing);

      expect(
        find.byKey(const ValueKey<String>('shows-watch-next-95396')),
        findsOneWidget,
        reason: 'The Watch Next card must remain visible during the mutation.',
      );

      repository.complete();

      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>(
            'shows-watch-next-mark-watched-loading-episode-uuid',
          ),
        ),
        findsNothing,
      );
    });
    testWidgets('shows safe error when marking Watch Next Episode fails', (
      WidgetTester tester,
    ) async {
      final _MarkWatchNextFailureRepository repository =
          _MarkWatchNextFailureRepository(
            shows: <LibraryShow>[_show],
            watchNext: <WatchNextShow>[_watchNextShow],
          );

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      final Finder markWatchedButton = find.byKey(
        const ValueKey<String>('shows-watch-next-mark-watched-episode-uuid'),
      );

      await tester.tap(markWatchedButton);
      await tester.pumpAndSettle();

      expect(repository.markEpisodeWatchedCalls, 1);

      expect(
        find.byKey(const ValueKey<String>('shows-watch-next-95396')),
        findsOneWidget,
        reason: 'A failed mutation must not remove the Watch Next card.',
      );

      expect(
        find.text('Could not mark the episode as watched.'),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('shows-watch-next-mark-watched-episode-uuid'),
        ),
        findsOneWidget,
        reason: 'The action must become available again after failure.',
      );
    });
    testWidgets(
      'disables Start when a Planning Show has no available Episode',
      (WidgetTester tester) async {
        final LibraryShow planningShow = LibraryShow(
          libraryEntryId: 'library-planning',
          showId: 'show-planning',
          tmdbId: 1396,
          title: 'Breaking Bad',
          originalTitle: 'Breaking Bad',
          status: LibraryStatus.planning,
          showStatus: 'Ended',
          voteAverage: 8.9,
          createdAt: DateTime.utc(2026, 8, 1),
          updatedAt: DateTime.utc(2026, 8, 10),
        );

        final ShowsCubit cubit = ShowsCubit(
          repository: _FakeShowsRepository(shows: <LibraryShow>[planningShow]),
        );

        addTearDown(cubit.close);

        await cubit.load();

        await tester.pumpWidget(_buildTestApp(cubit: cubit));
        await tester.pumpAndSettle();

        final Finder noEpisode = find.byKey(
          const ValueKey<String>('shows-havent-started-no-episode-1396'),
        );

        await tester.ensureVisible(noEpisode);
        await tester.pumpAndSettle();

        expect(noEpisode, findsOneWidget);
        expect(find.text('No episode available yet'), findsOneWidget);

        final Finder startButton = find.byKey(
          const ValueKey<String>('shows-havent-started-start-1396'),
        );

        final FilledButton button = tester.widget<FilledButton>(startButton);

        expect(button.onPressed, isNull);
      },
    );
  });
}

Future<void> _scrollWatchListNearBottom(WidgetTester tester) async {
  final Finder watchList = find.byKey(
    const ValueKey<String>('shows-watch-list'),
  );

  expect(watchList, findsOneWidget);

  await tester.drag(watchList, const Offset(0, -1000));

  await tester.pumpAndSettle();
}

Widget _buildTestApp({required ShowsCubit cubit}) {
  return MaterialApp(
    home: BlocProvider<ShowsCubit>.value(
      value: cubit,
      child: const ShowsPage(),
    ),
  );
}

GoRouter _buildRouter({required ShowsCubit cubit}) {
  return GoRouter(
    initialLocation: '/shows',
    routes: <RouteBase>[
      GoRoute(
        path: '/shows',
        builder: (BuildContext context, GoRouterState state) {
          return BlocProvider<ShowsCubit>.value(
            value: cubit,
            child: const ShowsPage(),
          );
        },
      ),
      GoRoute(
        name: AppRoute.showDetails.name,
        path: '/shows/:showId/details',
        builder: (BuildContext context, GoRouterState state) {
          final String showId = state.pathParameters['showId']!;

          return Scaffold(
            key: const ValueKey<String>('fake-show-details'),
            body: Center(child: Text('Show $showId')),
          );
        },
      ),
    ],
  );
}

final LibraryShow _show = LibraryShow(
  libraryEntryId: 'library-entry-uuid',
  showId: 'show-uuid',
  tmdbId: 95396,
  title: 'Severance',
  originalTitle: 'Severance',
  firstAirDate: DateTime(2022, 2, 18),
  posterUrl: null,
  backdropUrl: null,
  status: LibraryStatus.watching,
  showStatus: 'Returning Series',
  voteAverage: 8.4,
  createdAt: DateTime.utc(2026, 8, 1),
  updatedAt: DateTime.utc(2026, 8, 10),
);

final WatchNextShow _watchNextShow = WatchNextShow(
  libraryEntryId: 'library-entry-uuid',
  libraryStatus: LibraryStatus.watching,
  showId: 'show-uuid',
  showTmdbId: 95396,
  showTitle: 'Severance',
  posterUrl: null,
  backdropUrl: null,
  nextEpisode: WatchNextEpisode(
    id: 'episode-uuid',
    tmdbId: 1947648,
    seasonNumber: 2,
    episodeNumber: 4,
    title: "Woe's Hollow",
    airDate: DateTime(2026, 8, 10),
    runtime: 52,
    stillUrl: null,
  ),
  progress: const WatchNextProgress(
    watchedEpisodes: 7,
    airedEpisodes: 10,
    percentage: 70,
  ),
);

WatchHistoryItem _watchHistoryItem({
  required String episodeId,
  required int episodeNumber,
  required String title,
}) {
  return WatchHistoryItem(
    showId: 'show-uuid',
    eventId: 'watch-event-1',
    showTmdbId: 95396,
    showTitle: 'Severance',
    posterUrl: null,
    backdropUrl: null,
    episode: WatchHistoryEpisode(
      id: episodeId,
      tmdbId: 3000000 + episodeNumber,
      seasonNumber: 2,
      watchCount: 1,
      episodeNumber: episodeNumber,
      title: title,
      watchedAt: DateTime.utc(2026, 8, 13, 20),
      airDate: DateTime.utc(2026, 8, 10),
      runtime: 52,
      stillUrl: null,
    ),
  );
}

final StaleWatchingShow _staleWatchingShow = StaleWatchingShow(
  libraryEntryId: 'library-entry-stale',
  libraryStatus: LibraryStatus.watching,
  showId: 'show-stale',
  showTmdbId: 100088,
  showTitle: 'The Last of Us',
  posterUrl: null,
  backdropUrl: null,
  lastWatched: StaleWatchingEpisode(
    id: 'episode-last',
    tmdbId: 2001,
    seasonNumber: 1,
    episodeNumber: 3,
    title: 'Long, Long Time',
    watchedAt: DateTime.utc(2026, 5, 1, 20),
    airDate: DateTime(2023, 1, 29),
    runtime: 76,
    stillUrl: null,
  ),
  nextEpisode: WatchNextEpisode(
    id: 'episode-next',
    tmdbId: 2002,
    seasonNumber: 1,
    episodeNumber: 4,
    title: 'Please Hold to My Hand',
    airDate: DateTime(2023, 2, 5),
    runtime: 46,
    stillUrl: null,
  ),
);

final class _FakeShowsRepository implements ShowsRepository {
  const _FakeShowsRepository({
    required this.shows,
    this.watchNext = const <WatchNextShow>[],
    this.staleWatching = const <StaleWatchingShow>[],
  });

  final List<LibraryShow> shows;
  final List<WatchNextShow> watchNext;
  final List<StaleWatchingShow> staleWatching;

  @override
  Future<List<LibraryShow>> getLibraryShows() async {
    return shows;
  }

  @override
  Future<List<WatchNextShow>> getWatchNext() async {
    return watchNext;
  }

  @override
  Future<List<StaleWatchingShow>> getStaleWatching() async {
    return staleWatching;
  }

  @override
  Future<WatchHistoryPage> getWatchHistory({
    int limit = 30,
    String? cursor,
  }) async {
    return const WatchHistoryPage(
      items: <WatchHistoryItem>[],
      nextCursor: null,
      hasMore: false,
    );
  }

  @override
  Future<void> markEpisodeWatched({required String episodeId}) async {}

  @override
  Future<void> markEpisodeUnwatched({required String episodeId}) async {}

  @override
  Future<void> startShow({required String showId}) async {}
}

final class _PendingShowsRepository implements ShowsRepository {
  final Completer<List<LibraryShow>> _completer =
      Completer<List<LibraryShow>>();

  void complete(List<LibraryShow> shows) {
    _completer.complete(shows);
  }

  @override
  Future<List<LibraryShow>> getLibraryShows() {
    return _completer.future;
  }

  @override
  Future<List<WatchNextShow>> getWatchNext() async {
    return const <WatchNextShow>[];
  }

  @override
  Future<List<StaleWatchingShow>> getStaleWatching() async {
    return const <StaleWatchingShow>[];
  }

  @override
  Future<WatchHistoryPage> getWatchHistory({
    int limit = 30,
    String? cursor,
  }) async {
    return const WatchHistoryPage(
      items: <WatchHistoryItem>[],
      nextCursor: null,
      hasMore: false,
    );
  }

  @override
  Future<void> markEpisodeWatched({required String episodeId}) async {}

  @override
  Future<void> markEpisodeUnwatched({required String episodeId}) async {}

  @override
  Future<void> startShow({required String showId}) async {}
}

final class _WatchNextFailureRepository implements ShowsRepository {
  const _WatchNextFailureRepository({required this.shows});

  final List<LibraryShow> shows;

  @override
  Future<List<LibraryShow>> getLibraryShows() async {
    return shows;
  }

  @override
  Future<List<WatchNextShow>> getWatchNext() {
    throw const AppException.connection();
  }

  @override
  Future<List<StaleWatchingShow>> getStaleWatching() async {
    return const <StaleWatchingShow>[];
  }

  @override
  Future<WatchHistoryPage> getWatchHistory({
    int limit = 30,
    String? cursor,
  }) async {
    return const WatchHistoryPage(
      items: <WatchHistoryItem>[],
      nextCursor: null,
      hasMore: false,
    );
  }

  @override
  Future<void> markEpisodeWatched({required String episodeId}) async {}

  @override
  Future<void> markEpisodeUnwatched({required String episodeId}) async {}

  @override
  Future<void> startShow({required String showId}) async {}
}

final class _RetryWatchNextRepository implements ShowsRepository {
  _RetryWatchNextRepository({required this.shows});

  final List<LibraryShow> shows;

  int libraryCalls = 0;
  int watchNextCalls = 0;

  @override
  Future<List<LibraryShow>> getLibraryShows() async {
    libraryCalls++;

    return shows;
  }

  @override
  Future<List<WatchNextShow>> getWatchNext() async {
    watchNextCalls++;

    if (watchNextCalls == 1) {
      throw const AppException.connection();
    }

    return <WatchNextShow>[_watchNextShow];
  }

  @override
  Future<List<StaleWatchingShow>> getStaleWatching() async {
    return const <StaleWatchingShow>[];
  }

  @override
  Future<WatchHistoryPage> getWatchHistory({
    int limit = 30,
    String? cursor,
  }) async {
    return const WatchHistoryPage(
      items: <WatchHistoryItem>[],
      nextCursor: null,
      hasMore: false,
    );
  }

  @override
  Future<void> markEpisodeWatched({required String episodeId}) async {}

  @override
  Future<void> markEpisodeUnwatched({required String episodeId}) async {}

  @override
  Future<void> startShow({required String showId}) async {}
}

final class _StaleWatchingFailureRepository implements ShowsRepository {
  const _StaleWatchingFailureRepository({
    required this.shows,
    required this.watchNext,
  });

  final List<LibraryShow> shows;
  final List<WatchNextShow> watchNext;

  @override
  Future<List<LibraryShow>> getLibraryShows() async {
    return shows;
  }

  @override
  Future<List<WatchNextShow>> getWatchNext() async {
    return watchNext;
  }

  @override
  Future<List<StaleWatchingShow>> getStaleWatching() {
    throw const AppException.connection();
  }

  @override
  Future<WatchHistoryPage> getWatchHistory({
    int limit = 30,
    String? cursor,
  }) async {
    return const WatchHistoryPage(
      items: <WatchHistoryItem>[],
      nextCursor: null,
      hasMore: false,
    );
  }

  @override
  Future<void> markEpisodeWatched({required String episodeId}) async {}

  @override
  Future<void> markEpisodeUnwatched({required String episodeId}) async {}

  @override
  Future<void> startShow({required String showId}) async {}
}

final class _RetryStaleWatchingRepository implements ShowsRepository {
  _RetryStaleWatchingRepository({required this.shows, required this.watchNext});

  final List<LibraryShow> shows;
  final List<WatchNextShow> watchNext;

  int libraryCalls = 0;
  int watchNextCalls = 0;
  int staleWatchingCalls = 0;

  @override
  Future<List<LibraryShow>> getLibraryShows() async {
    libraryCalls++;

    return shows;
  }

  @override
  Future<List<WatchNextShow>> getWatchNext() async {
    watchNextCalls++;

    return watchNext;
  }

  @override
  Future<List<StaleWatchingShow>> getStaleWatching() async {
    staleWatchingCalls++;

    if (staleWatchingCalls == 1) {
      throw const AppException.connection();
    }

    return <StaleWatchingShow>[_staleWatchingShow];
  }

  @override
  Future<WatchHistoryPage> getWatchHistory({
    int limit = 30,
    String? cursor,
  }) async {
    return const WatchHistoryPage(
      items: <WatchHistoryItem>[],
      nextCursor: null,
      hasMore: false,
    );
  }

  @override
  Future<void> markEpisodeWatched({required String episodeId}) async {}

  @override
  Future<void> markEpisodeUnwatched({required String episodeId}) async {}

  @override
  Future<void> startShow({required String showId}) async {}
}

final class _WatchHistoryTrackingRepository implements ShowsRepository {
  _WatchHistoryTrackingRepository({
    required this.shows,
    required this.firstPage,
  });

  final List<LibraryShow> shows;
  final WatchHistoryPage firstPage;

  int watchHistoryCalls = 0;

  @override
  Future<List<LibraryShow>> getLibraryShows() async => shows;

  @override
  Future<List<WatchNextShow>> getWatchNext() async => const <WatchNextShow>[];

  @override
  Future<List<StaleWatchingShow>> getStaleWatching() async =>
      const <StaleWatchingShow>[];

  @override
  Future<WatchHistoryPage> getWatchHistory({
    int limit = 30,
    String? cursor,
  }) async {
    watchHistoryCalls++;

    return firstPage;
  }

  @override
  Future<void> markEpisodeWatched({required String episodeId}) async {}

  @override
  Future<void> markEpisodeUnwatched({required String episodeId}) async {}

  @override
  Future<void> startShow({required String showId}) async {}
}

final class _PaginatedWatchHistoryRepository implements ShowsRepository {
  _PaginatedWatchHistoryRepository({required this.shows});

  final List<LibraryShow> shows;

  int watchHistoryCalls = 0;

  @override
  Future<List<LibraryShow>> getLibraryShows() async => shows;

  @override
  Future<List<WatchNextShow>> getWatchNext() async => const <WatchNextShow>[];

  @override
  Future<List<StaleWatchingShow>> getStaleWatching() async =>
      const <StaleWatchingShow>[];

  @override
  Future<WatchHistoryPage> getWatchHistory({
    int limit = 30,
    String? cursor,
  }) async {
    watchHistoryCalls++;

    if (cursor == null) {
      return WatchHistoryPage(
        items: <WatchHistoryItem>[
          _watchHistoryItem(
            episodeId: 'history-1',
            episodeNumber: 4,
            title: "Woe's Hollow",
          ),
        ],
        nextCursor: 'cursor-1',
        hasMore: true,
      );
    }

    expect(cursor, 'cursor-1');

    return WatchHistoryPage(
      items: <WatchHistoryItem>[
        _watchHistoryItem(
          episodeId: 'history-2',
          episodeNumber: 3,
          title: 'Who Is Alive?',
        ),
      ],
      nextCursor: null,
      hasMore: false,
    );
  }

  @override
  Future<void> markEpisodeWatched({required String episodeId}) async {}

  @override
  Future<void> markEpisodeUnwatched({required String episodeId}) async {}

  @override
  Future<void> startShow({required String showId}) async {}
}

final class _RetryWatchHistoryRepository implements ShowsRepository {
  _RetryWatchHistoryRepository({required this.shows});

  final List<LibraryShow> shows;

  int watchHistoryCalls = 0;

  @override
  Future<List<LibraryShow>> getLibraryShows() async => shows;

  @override
  Future<List<WatchNextShow>> getWatchNext() async => const <WatchNextShow>[];

  @override
  Future<List<StaleWatchingShow>> getStaleWatching() async =>
      const <StaleWatchingShow>[];

  @override
  Future<WatchHistoryPage> getWatchHistory({
    int limit = 30,
    String? cursor,
  }) async {
    watchHistoryCalls++;

    if (watchHistoryCalls == 1) {
      throw const AppException.connection();
    }

    return WatchHistoryPage(
      items: <WatchHistoryItem>[
        _watchHistoryItem(
          episodeId: 'history-1',
          episodeNumber: 4,
          title: "Woe's Hollow",
        ),
      ],
      nextCursor: null,
      hasMore: false,
    );
  }

  @override
  Future<void> markEpisodeWatched({required String episodeId}) async {}

  @override
  Future<void> markEpisodeUnwatched({required String episodeId}) async {}

  @override
  Future<void> startShow({required String showId}) async {}
}

final class _RetryWatchHistoryPaginationRepository implements ShowsRepository {
  _RetryWatchHistoryPaginationRepository({required this.shows});

  final List<LibraryShow> shows;

  int watchHistoryCalls = 0;

  @override
  Future<List<LibraryShow>> getLibraryShows() async => shows;

  @override
  Future<List<WatchNextShow>> getWatchNext() async => const <WatchNextShow>[];

  @override
  Future<List<StaleWatchingShow>> getStaleWatching() async =>
      const <StaleWatchingShow>[];

  @override
  Future<WatchHistoryPage> getWatchHistory({
    int limit = 30,
    String? cursor,
  }) async {
    watchHistoryCalls++;

    if (cursor == null) {
      return WatchHistoryPage(
        items: <WatchHistoryItem>[
          _watchHistoryItem(
            episodeId: 'history-1',
            episodeNumber: 4,
            title: "Woe's Hollow",
          ),
        ],
        nextCursor: 'cursor-1',
        hasMore: true,
      );
    }

    if (watchHistoryCalls == 2) {
      throw const AppException.connection();
    }

    return WatchHistoryPage(
      items: <WatchHistoryItem>[
        _watchHistoryItem(
          episodeId: 'history-2',
          episodeNumber: 3,
          title: 'Who Is Alive?',
        ),
      ],
      nextCursor: null,
      hasMore: false,
    );
  }

  @override
  Future<void> markEpisodeWatched({required String episodeId}) async {}

  @override
  Future<void> markEpisodeUnwatched({required String episodeId}) async {}

  @override
  Future<void> startShow({required String showId}) async {}
}

final class _MarkWatchNextRepository implements ShowsRepository {
  _MarkWatchNextRepository({required this.shows, required this.watchNext});

  final List<LibraryShow> shows;
  final List<WatchNextShow> watchNext;

  int watchNextCalls = 0;
  int staleWatchingCalls = 0;
  int markEpisodeWatchedCalls = 0;

  final List<String> markedEpisodeIds = <String>[];

  @override
  Future<List<LibraryShow>> getLibraryShows() async {
    return shows;
  }

  @override
  Future<List<WatchNextShow>> getWatchNext() async {
    watchNextCalls++;

    return watchNext;
  }

  @override
  Future<List<StaleWatchingShow>> getStaleWatching() async {
    staleWatchingCalls++;

    return const <StaleWatchingShow>[];
  }

  @override
  Future<WatchHistoryPage> getWatchHistory({
    int limit = 30,
    String? cursor,
  }) async {
    return const WatchHistoryPage(
      items: <WatchHistoryItem>[],
      nextCursor: null,
      hasMore: false,
    );
  }

  @override
  Future<void> markEpisodeWatched({required String episodeId}) async {
    markEpisodeWatchedCalls++;
    markedEpisodeIds.add(episodeId);
  }

  @override
  Future<void> markEpisodeUnwatched({required String episodeId}) async {}

  @override
  Future<void> startShow({required String showId}) async {}
}

final class _PendingMarkWatchNextRepository implements ShowsRepository {
  _PendingMarkWatchNextRepository({
    required this.shows,
    required this.watchNext,
  });

  final List<LibraryShow> shows;
  final List<WatchNextShow> watchNext;

  final Completer<void> _markWatchedCompleter = Completer<void>();

  int markEpisodeWatchedCalls = 0;

  void complete() {
    _markWatchedCompleter.complete();
  }

  @override
  Future<List<LibraryShow>> getLibraryShows() async {
    return shows;
  }

  @override
  Future<List<WatchNextShow>> getWatchNext() async {
    return watchNext;
  }

  @override
  Future<List<StaleWatchingShow>> getStaleWatching() async {
    return const <StaleWatchingShow>[];
  }

  @override
  Future<WatchHistoryPage> getWatchHistory({
    int limit = 30,
    String? cursor,
  }) async {
    return const WatchHistoryPage(
      items: <WatchHistoryItem>[],
      nextCursor: null,
      hasMore: false,
    );
  }

  @override
  Future<void> markEpisodeWatched({required String episodeId}) {
    markEpisodeWatchedCalls++;

    return _markWatchedCompleter.future;
  }

  @override
  Future<void> markEpisodeUnwatched({required String episodeId}) async {}

  @override
  Future<void> startShow({required String showId}) async {}
}

final class _MarkWatchNextFailureRepository implements ShowsRepository {
  _MarkWatchNextFailureRepository({
    required this.shows,
    required this.watchNext,
  });

  final List<LibraryShow> shows;
  final List<WatchNextShow> watchNext;

  int markEpisodeWatchedCalls = 0;

  @override
  Future<List<LibraryShow>> getLibraryShows() async {
    return shows;
  }

  @override
  Future<List<WatchNextShow>> getWatchNext() async {
    return watchNext;
  }

  @override
  Future<List<StaleWatchingShow>> getStaleWatching() async {
    return const <StaleWatchingShow>[];
  }

  @override
  Future<WatchHistoryPage> getWatchHistory({
    int limit = 30,
    String? cursor,
  }) async {
    return const WatchHistoryPage(
      items: <WatchHistoryItem>[],
      nextCursor: null,
      hasMore: false,
    );
  }

  @override
  Future<void> markEpisodeWatched({required String episodeId}) {
    markEpisodeWatchedCalls++;

    throw const AppException.connection();
  }

  @override
  Future<void> markEpisodeUnwatched({required String episodeId}) async {}

  @override
  Future<void> startShow({required String showId}) async {}
}

final class _PendingStartShowRepository implements ShowsRepository {
  _PendingStartShowRepository({required this.planningShow});

  final LibraryShow planningShow;

  final Completer<void> _startCompleter = Completer<void>();

  int startShowCalls = 0;

  void completeStart() {
    _startCompleter.complete();
  }

  @override
  Future<List<LibraryShow>> getLibraryShows() async {
    return <LibraryShow>[planningShow];
  }

  @override
  Future<List<WatchNextShow>> getWatchNext() async {
    return const <WatchNextShow>[];
  }

  @override
  Future<List<StaleWatchingShow>> getStaleWatching() async {
    return const <StaleWatchingShow>[];
  }

  @override
  Future<WatchHistoryPage> getWatchHistory({
    int limit = 30,
    String? cursor,
  }) async {
    return const WatchHistoryPage(
      items: <WatchHistoryItem>[],
      nextCursor: null,
      hasMore: false,
    );
  }

  @override
  Future<void> markEpisodeWatched({required String episodeId}) async {}

  @override
  Future<void> markEpisodeUnwatched({required String episodeId}) async {}

  @override
  Future<void> startShow({required String showId}) {
    startShowCalls++;

    return _startCompleter.future;
  }
}

final class _SuccessfulStartShowRepository implements ShowsRepository {
  _SuccessfulStartShowRepository({required this.planningShow});

  final LibraryShow planningShow;

  bool _started = false;

  int startShowCalls = 0;
  final List<String> startedShowIds = <String>[];

  @override
  Future<List<LibraryShow>> getLibraryShows() async {
    if (!_started) {
      return <LibraryShow>[planningShow];
    }

    return <LibraryShow>[
      LibraryShow(
        libraryEntryId: planningShow.libraryEntryId,
        showId: planningShow.showId,
        tmdbId: planningShow.tmdbId,
        title: planningShow.title,
        originalTitle: planningShow.originalTitle,
        firstAirDate: planningShow.firstAirDate,
        posterUrl: planningShow.posterUrl,
        backdropUrl: planningShow.backdropUrl,
        status: LibraryStatus.watching,
        showStatus: planningShow.showStatus,
        voteAverage: planningShow.voteAverage,
        rating: planningShow.rating,
        startedAt: DateTime.utc(2026, 8, 14),
        completedAt: null,
        createdAt: planningShow.createdAt,
        updatedAt: DateTime.utc(2026, 8, 14),
      ),
    ];
  }

  @override
  Future<void> startShow({required String showId}) async {
    startShowCalls++;
    startedShowIds.add(showId);

    _started = true;
  }

  @override
  Future<List<WatchNextShow>> getWatchNext() async {
    return const <WatchNextShow>[];
  }

  @override
  Future<List<StaleWatchingShow>> getStaleWatching() async {
    return const <StaleWatchingShow>[];
  }

  @override
  Future<WatchHistoryPage> getWatchHistory({
    int limit = 30,
    String? cursor,
  }) async {
    return const WatchHistoryPage(
      items: <WatchHistoryItem>[],
      nextCursor: null,
      hasMore: false,
    );
  }

  @override
  Future<void> markEpisodeWatched({required String episodeId}) async {}

  @override
  Future<void> markEpisodeUnwatched({required String episodeId}) async {}
}

final class _FailingStartShowRepository implements ShowsRepository {
  _FailingStartShowRepository({required this.planningShow});

  final LibraryShow planningShow;

  int startShowCalls = 0;

  @override
  Future<List<LibraryShow>> getLibraryShows() async {
    return <LibraryShow>[planningShow];
  }

  @override
  Future<void> startShow({required String showId}) {
    startShowCalls++;

    throw const AppException.connection();
  }

  @override
  Future<List<WatchNextShow>> getWatchNext() async {
    return const <WatchNextShow>[];
  }

  @override
  Future<List<StaleWatchingShow>> getStaleWatching() async {
    return const <StaleWatchingShow>[];
  }

  @override
  Future<WatchHistoryPage> getWatchHistory({
    int limit = 30,
    String? cursor,
  }) async {
    return const WatchHistoryPage(
      items: <WatchHistoryItem>[],
      nextCursor: null,
      hasMore: false,
    );
  }

  @override
  Future<void> markEpisodeWatched({required String episodeId}) async {}

  @override
  Future<void> markEpisodeUnwatched({required String episodeId}) async {}
}
