import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/app/theme/tokens/app_breakpoints.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/shows/application/cubit/shows_cubit.dart';
import 'package:sofawatch/features/shows/domain/models/library_first_episode.dart';
import 'package:sofawatch/features/shows/domain/models/library_show.dart';
import 'package:sofawatch/features/shows/domain/models/library_show_progress.dart';
import 'package:sofawatch/features/shows/domain/models/stale_watching_episode.dart';
import 'package:sofawatch/features/shows/domain/models/stale_watching_show.dart';
import 'package:sofawatch/features/shows/domain/models/upcoming_episode.dart';
import 'package:sofawatch/features/shows/domain/models/upcoming_item.dart';
import 'package:sofawatch/features/shows/domain/models/watch_history_item.dart';
import 'package:sofawatch/features/shows/domain/models/watch_history_page.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_episode.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_progress.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_show.dart';
import 'package:sofawatch/features/shows/domain/repositories/shows_repository.dart';
import 'package:sofawatch/features/shows/presentation/pages/shows_page.dart';

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

      expect(find.textContaining('S02 E04'), findsOneWidget);

      expect(find.textContaining("Woe's Hollow"), findsOneWidget);

      final Finder watchNextCard = find.byKey(
        const ValueKey<String>('shows-watch-next-95396'),
      );

      expect(watchNextCard, findsOneWidget);

      expect(
        find.descendant(
          of: watchNextCard,
          matching: find.byType(LinearProgressIndicator),
        ),
        findsOneWidget,
      );

      final Finder progressIndicatorFinder = find.descendant(
        of: watchNextCard,
        matching: find.byType(LinearProgressIndicator),
      );

      expect(progressIndicatorFinder, findsOneWidget);

      final LinearProgressIndicator progressIndicator = tester
          .widget<LinearProgressIndicator>(progressIndicatorFinder);

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

      expect(
        find.byKey(
          const ValueKey<String>(
            'shows-stale-watching-next-title-episode-next',
          ),
        ),
        findsOneWidget,
      );

      expect(
        find.textContaining('S01 E04 • Please Hold to My Hand'),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('shows-stale-watching-progress-100088'),
        ),
        findsOneWidget,
      );
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
        progress: const LibraryShowProgress(
          watchedEpisodes: 4,
          airedEpisodes: 10,
          percentage: 40,
          caughtUp: false,
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

      final Finder staleShowDetails = find.byKey(
        const ValueKey<String>('shows-stale-watching-show-details-100088'),
      );

      await tester.ensureVisible(staleShowDetails);
      await tester.pumpAndSettle();

      await tester.tap(staleShowDetails);
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('fake-show-details')),
        findsOneWidget,
      );

      expect(find.text('Show 100088'), findsOneWidget);
    });
    testWidgets(
      'opens Episode Details from Watch Next without triggering Show Details',
      (WidgetTester tester) async {
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
          find.byKey(
            const ValueKey<String>(
              'shows-watch-next-episode-details-episode-uuid',
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('fake-episode-details')),
          findsOneWidget,
        );

        expect(find.text('Episode episode-uuid'), findsOneWidget);

        expect(
          find.byKey(const ValueKey<String>('fake-show-details')),
          findsNothing,
        );
      },
    );
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

      final Finder watchList = find.byKey(
        const ValueKey<String>('shows-watch-list'),
      );

      final Finder watchListScrollable = find.descendant(
        of: watchList,
        matching: find.byWidgetPredicate(
          (Widget widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      );
      expect(watchListScrollable, findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('shows-stale-watching-failure')),
        300,
        scrollable: watchListScrollable,
      );

      await tester.pumpAndSettle();

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

      final Finder watchList = find.byKey(
        const ValueKey<String>('shows-watch-list'),
      );

      final Finder watchListScrollable = find.descendant(
        of: watchList,
        matching: find.byWidgetPredicate(
          (Widget widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      );

      expect(watchListScrollable, findsOneWidget);

      final Finder failure = find.byKey(
        const ValueKey<String>('shows-stale-watching-failure'),
      );

      await tester.scrollUntilVisible(
        failure,
        300,
        scrollable: watchListScrollable,
      );

      await tester.pumpAndSettle();

      expect(failure, findsOneWidget);

      final Finder retryButton = find.byKey(
        const ValueKey<String>('shows-stale-watching-retry'),
      );

      expect(retryButton, findsOneWidget);

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
        progress: _emptyLibraryShowProgress,
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

      expect(find.text('S01 E01 • 58 min'), findsOneWidget);
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
          progress: _emptyLibraryShowProgress,
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
        progress: _emptyLibraryShowProgress,
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
        progress: _emptyLibraryShowProgress,
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
        progress: _emptyLibraryShowProgress,
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
        progress: _emptyLibraryShowProgress,
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
        progress: _emptyLibraryShowProgress,
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
          progress: _emptyLibraryShowProgress,
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

    testWidgets(
      'loads earlier Upcoming episodes when user scrolls back to the top',
      (WidgetTester tester) async {
        final _ScrollableUpcomingRepository repository =
            _ScrollableUpcomingRepository();

        final ShowsCubit cubit = ShowsCubit(
          repository: repository,
          now: () => DateTime(2026, 8, 15, 12),
        );

        addTearDown(cubit.close);

        await cubit.load();

        await tester.pumpWidget(_buildTestApp(cubit: cubit));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey<String>('shows-tab-upcoming')),
        );

        await tester.pumpAndSettle();

        final Finder timeline = find.byKey(
          const ValueKey<String>('shows-upcoming-timeline'),
        );

        expect(timeline, findsOneWidget);

        expect(
          repository.upcomingCalls,
          1,
          reason: 'Opening Upcoming at Today must not load more history.',
        );

        final CustomScrollView scrollView = tester.widget<CustomScrollView>(
          timeline,
        );

        final ScrollController controller = scrollView.controller!;
        final ScrollPosition position = controller.position;

        expect(
          position.minScrollExtent,
          lessThan(0),
          reason: 'Past Upcoming content must exist before Today.',
        );

        controller.jumpTo(position.minScrollExtent + 100);

        await tester.pumpAndSettle();

        expect(repository.upcomingCalls, 2);

        expect(repository.fromDates.last, DateTime(2026, 7, 25));
        expect(repository.toDates.last, DateTime(2026, 8, 7));

        expect(
          cubit.state.upcoming
              .map((UpcomingItem item) => item.episode.id)
              .contains('earlier-episode'),
          isTrue,
        );

        expect(
          cubit.state.upcoming
              .map((UpcomingItem item) => item.episode.id)
              .contains('current-0'),
          isTrue,
        );

        expect(
          cubit.state.upcoming.first.episode.id,
          'earlier-episode',
          reason: 'Earlier Episodes must be prepended to the timeline.',
        );
      },
    );

    testWidgets(
      'keeps Upcoming timeline visible while loading earlier episodes',
      (WidgetTester tester) async {
        final _PendingEarlierUpcomingRepository repository =
            _PendingEarlierUpcomingRepository();

        final ShowsCubit cubit = ShowsCubit(
          repository: repository,
          now: () => DateTime(2026, 8, 15, 12),
        );

        addTearDown(cubit.close);

        await cubit.load();

        await tester.pumpWidget(_buildTestApp(cubit: cubit));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey<String>('shows-tab-upcoming')),
        );

        await tester.pumpAndSettle();

        final Finder timeline = find.byKey(
          const ValueKey<String>('shows-upcoming-timeline'),
        );

        final CustomScrollView scrollView = tester.widget<CustomScrollView>(
          timeline,
        );

        final ScrollController controller = scrollView.controller!;
        final ScrollPosition position = controller.position;

        expect(position.minScrollExtent, lessThan(0));

        controller.jumpTo(position.minScrollExtent + 100);

        await tester.pump();

        expect(repository.upcomingCalls, 2);

        expect(cubit.state.isLoadingEarlierUpcoming, isTrue);

        expect(
          cubit.state.upcoming
              .map((UpcomingItem item) => item.episode.id)
              .contains('current-0'),
          isTrue,
          reason: 'Historical loading must not replace the existing timeline.',
        );

        /*
     * Move to the beginning of the currently loaded historical range
     * so the loading indicator is mounted in the viewport.
     */
        controller.jumpTo(controller.position.minScrollExtent);

        await tester.pump();

        expect(
          repository.upcomingCalls,
          2,
          reason:
              'Moving further into history while a request is pending '
              'must not create a duplicate request.',
        );

        expect(
          find.byKey(const ValueKey<String>('shows-upcoming-loading-earlier')),
          findsOneWidget,
        );

        repository.completeEarlier(<UpcomingItem>[
          _makeUpcomingItem(
            id: 'earlier-episode',
            episodeNumber: 1,
            airDate: DateTime(2026, 8, 1),
          ),
        ]);

        await tester.pumpAndSettle();

        expect(cubit.state.isLoadingEarlierUpcoming, isFalse);

        expect(
          find.byKey(const ValueKey<String>('shows-upcoming-loading-earlier')),
          findsNothing,
        );

        expect(
          cubit.state.upcoming
              .map((UpcomingItem item) => item.episode.id)
              .contains('earlier-episode'),
          isTrue,
        );
      },
    );

    testWidgets(
      'shows Retry without removing Upcoming timeline when earlier loading fails',
      (WidgetTester tester) async {
        final _FailingEarlierUpcomingPageRepository repository =
            _FailingEarlierUpcomingPageRepository();

        final ShowsCubit cubit = ShowsCubit(
          repository: repository,
          now: () => DateTime(2026, 8, 15, 12),
        );

        addTearDown(cubit.close);

        await cubit.load();

        await tester.pumpWidget(_buildTestApp(cubit: cubit));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey<String>('shows-tab-upcoming')),
        );

        await tester.pumpAndSettle();

        final Finder timeline = find.byKey(
          const ValueKey<String>('shows-upcoming-timeline'),
        );

        final CustomScrollView scrollView = tester.widget<CustomScrollView>(
          timeline,
        );

        final ScrollController controller = scrollView.controller!;
        final ScrollPosition position = controller.position;

        expect(position.minScrollExtent, lessThan(0));

        controller.jumpTo(position.minScrollExtent + 100);

        await tester.pumpAndSettle();

        expect(repository.upcomingCalls, 2);

        expect(cubit.state.earlierUpcomingError, isNotNull);

        expect(
          cubit.state.upcoming
              .map((UpcomingItem item) => item.episode.id)
              .contains('current-0'),
          isTrue,
          reason:
              'A failed historical request must preserve the current timeline.',
        );

        /*
     * The failure UI lives at the beginning of the historical sliver.
     */
        controller.jumpTo(controller.position.minScrollExtent);

        await tester.pump();

        expect(
          find.byKey(const ValueKey<String>('shows-upcoming-earlier-failure')),
          findsOneWidget,
        );

        expect(
          find.byKey(const ValueKey<String>('shows-upcoming-earlier-retry')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const ValueKey<String>('shows-upcoming-earlier-retry')),
        );

        await tester.pumpAndSettle();

        expect(repository.upcomingCalls, 3);

        expect(cubit.state.earlierUpcomingError, isNull);

        expect(
          find.byKey(const ValueKey<String>('shows-upcoming-earlier-failure')),
          findsNothing,
        );

        expect(
          cubit.state.upcoming
              .map((UpcomingItem item) => item.episode.id)
              .contains('earlier-episode'),
          isTrue,
        );
      },
    );

    testWidgets(
      'preserves Upcoming scroll position after prepending earlier episodes',
      (WidgetTester tester) async {
        final _ScrollableUpcomingRepository repository =
            _ScrollableUpcomingRepository();

        final ShowsCubit cubit = ShowsCubit(
          repository: repository,
          now: () => DateTime(2026, 8, 15, 12),
        );

        addTearDown(cubit.close);

        await cubit.load();

        await tester.pumpWidget(_buildTestApp(cubit: cubit));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey<String>('shows-tab-upcoming')),
        );

        await tester.pumpAndSettle();

        final Finder timelineFinder = find.byKey(
          const ValueKey<String>('shows-upcoming-timeline'),
        );

        final CustomScrollView scrollView = tester.widget<CustomScrollView>(
          timelineFinder,
        );

        final ScrollController controller = scrollView.controller!;
        final ScrollPosition position = controller.position;

        expect(position.minScrollExtent, lessThan(0));

        controller.jumpTo(position.minScrollExtent + 100);

        final double offsetBeforePrepend = controller.offset;

        await tester.pumpAndSettle();

        expect(repository.upcomingCalls, 2);

        expect(cubit.state.upcoming.first.episode.id, 'earlier-episode');

        expect(
          cubit.state.upcoming
              .map((UpcomingItem item) => item.episode.id)
              .contains('current-0'),
          isTrue,
        );

        /*
     * Historical content is inserted before the Today center.
     *
     * CustomScrollView.center keeps the existing scroll coordinate
     * stable instead of requiring manual offset compensation.
     */
        expect(
          controller.offset,
          closeTo(offsetBeforePrepend, 1),
          reason:
              'Prepending historical content before the Today center must '
              'preserve the current scroll position.',
        );
      },
    );
    testWidgets(
      'opens Upcoming anchored at Today even when no episode airs today',
      (WidgetTester tester) async {
        final ShowsCubit cubit = ShowsCubit(
          repository: _FakeShowsRepository(
            shows: <LibraryShow>[_show],
            upcoming: <UpcomingItem>[
              _makeUpcomingItem(
                id: 'tomorrow-episode',
                episodeNumber: 1,
                airDate: DateTime(2026, 8, 16),
              ),
            ],
          ),
          now: () => DateTime(2026, 8, 15, 12),
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
          find.byKey(const ValueKey<String>('shows-upcoming-today-section')),
          findsOneWidget,
        );

        expect(find.text('Today'), findsOneWidget);

        expect(
          find.byKey(const ValueKey<String>('shows-upcoming-today-empty')),
          findsOneWidget,
        );

        expect(find.text('No episodes airing today.'), findsOneWidget);

        final CustomScrollView timeline = tester.widget<CustomScrollView>(
          find.byKey(const ValueKey<String>('shows-upcoming-timeline')),
        );

        expect(
          timeline.controller!.offset,
          closeTo(0, 1),
          reason: 'Upcoming must initially open at the Today center.',
        );
      },
    );
    testWidgets('groups Upcoming episodes into Today and Tomorrow', (
      WidgetTester tester,
    ) async {
      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(
          shows: <LibraryShow>[_show],
          upcoming: <UpcomingItem>[
            _makeUpcomingItem(
              id: 'today-episode',
              episodeNumber: 1,
              airDate: DateTime(2026, 8, 15),
            ),
            _makeUpcomingItem(
              id: 'tomorrow-episode',
              episodeNumber: 2,
              airDate: DateTime(2026, 8, 16),
            ),
          ],
        ),
        now: () => DateTime(2026, 8, 15, 12),
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('shows-tab-upcoming')),
      );

      await tester.pumpAndSettle();

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Tomorrow'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('shows-upcoming-today-episode')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('shows-upcoming-tomorrow-episode')),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('shows-upcoming-temporal-today-episode'),
        ),
        findsOneWidget,
      );

      expect(find.text('Airs today'), findsOneWidget);
      expect(find.text('Airs tomorrow'), findsOneWidget);
    });
    testWidgets(
      'shows dated groups and countdown for episodes within seven days',
      (WidgetTester tester) async {
        final ShowsCubit cubit = ShowsCubit(
          repository: _FakeShowsRepository(
            shows: <LibraryShow>[_show],
            upcoming: <UpcomingItem>[
              _makeUpcomingItem(
                id: 'future-two-days',
                episodeNumber: 3,
                airDate: DateTime(2026, 8, 17),
              ),
              _makeUpcomingItem(
                id: 'future-seven-days',
                episodeNumber: 4,
                airDate: DateTime(2026, 8, 22),
              ),
            ],
          ),
          now: () => DateTime(2026, 8, 15, 12),
        );

        addTearDown(cubit.close);

        await cubit.load();

        await tester.pumpWidget(_buildTestApp(cubit: cubit));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey<String>('shows-tab-upcoming')),
        );

        await tester.pumpAndSettle();

        expect(find.text('Monday, Aug 17'), findsOneWidget);

        expect(find.text('Saturday, Aug 22'), findsOneWidget);

        expect(find.text('In 2 days'), findsOneWidget);
        expect(find.text('In 7 days'), findsOneWidget);

        expect(
          find.byKey(const ValueKey<String>('shows-upcoming-future-two-days')),
          findsOneWidget,
        );

        expect(
          find.byKey(
            const ValueKey<String>('shows-upcoming-future-seven-days'),
          ),
          findsOneWidget,
        );
      },
    );
    testWidgets('groups episodes beyond seven days under Later', (
      WidgetTester tester,
    ) async {
      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(
          shows: <LibraryShow>[_show],
          upcoming: <UpcomingItem>[
            _makeUpcomingItem(
              id: 'later-first',
              episodeNumber: 5,
              airDate: DateTime(2026, 8, 23),
            ),
            _makeUpcomingItem(
              id: 'later-second',
              episodeNumber: 6,
              airDate: DateTime(2026, 9, 5),
            ),
          ],
        ),
        now: () => DateTime(2026, 8, 15, 12),
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
        find.text('Later'),
        findsOneWidget,
        reason:
            'All Episodes after the seven-day detailed window '
            'must share a single Later section.',
      );

      expect(
        find.byKey(const ValueKey<String>('shows-upcoming-later-first')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('shows-upcoming-later-second')),
        findsOneWidget,
      );

      expect(find.text('Aug 23'), findsOneWidget);
      expect(find.text('Sep 5'), findsOneWidget);
    });
    testWidgets('keeps previously aired Upcoming dates above Today', (
      WidgetTester tester,
    ) async {
      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(
          shows: <LibraryShow>[_show],
          upcoming: <UpcomingItem>[
            _makeUpcomingItem(
              id: 'past-episode',
              episodeNumber: 1,
              airDate: DateTime(2026, 8, 14),
            ),
            _makeUpcomingItem(
              id: 'today-episode',
              episodeNumber: 2,
              airDate: DateTime(2026, 8, 15),
            ),
          ],
        ),
        now: () => DateTime(2026, 8, 15, 12),
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('shows-tab-upcoming')),
      );

      await tester.pumpAndSettle();

      final Finder timelineFinder = find.byKey(
        const ValueKey<String>('shows-upcoming-timeline'),
      );

      final CustomScrollView timeline = tester.widget<CustomScrollView>(
        timelineFinder,
      );

      expect(timeline.controller!.position.minScrollExtent, lessThan(0));

      timeline.controller!.jumpTo(
        timeline.controller!.position.minScrollExtent,
      );

      await tester.pumpAndSettle();

      expect(find.text('Friday, Aug 14'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('shows-upcoming-past-episode')),
        findsOneWidget,
      );

      expect(find.text('Aired Aug 14'), findsOneWidget);
    });
    testWidgets(
      'enables Mark Watched for a previously aired Upcoming Episode',
      (WidgetTester tester) async {
        final ShowsCubit cubit = ShowsCubit(
          repository: _FakeShowsRepository(
            shows: <LibraryShow>[_show],
            upcoming: <UpcomingItem>[
              _makeUpcomingItem(
                id: 'past-episode',
                episodeNumber: 1,
                airDate: DateTime(2026, 8, 14),
              ),
            ],
          ),
          now: () => DateTime(2026, 8, 15, 12),
        );

        addTearDown(cubit.close);

        await cubit.load();

        await tester.pumpWidget(_buildTestApp(cubit: cubit));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey<String>('shows-tab-upcoming')),
        );

        await tester.pumpAndSettle();

        final Finder timelineFinder = find.byKey(
          const ValueKey<String>('shows-upcoming-timeline'),
        );

        expect(timelineFinder, findsOneWidget);

        final CustomScrollView scrollView = tester.widget<CustomScrollView>(
          timelineFinder,
        );

        final ScrollController controller = scrollView.controller!;

        expect(
          controller.position.minScrollExtent,
          lessThan(0),
          reason: 'The previously aired Episode must exist before Today.',
        );

        /*
     * Past Upcoming content lives before the CustomScrollView center,
     * so it is intentionally not mounted while the timeline is opened
     * at Today.
     */
        controller.jumpTo(controller.position.minScrollExtent);

        await tester.pumpAndSettle();

        final Finder buttonFinder = find.byKey(
          const ValueKey<String>('shows-upcoming-mark-watched-past-episode'),
        );

        expect(buttonFinder, findsOneWidget);

        final IconButton button = tester.widget<IconButton>(buttonFinder);

        expect(
          button.onPressed,
          isNotNull,
          reason: 'Previously aired Episodes must be markable as watched.',
        );
      },
    );

    testWidgets('enables Mark Watched for an Upcoming Episode airing Today', (
      WidgetTester tester,
    ) async {
      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(
          shows: <LibraryShow>[_show],
          upcoming: <UpcomingItem>[
            _makeUpcomingItem(
              id: 'today-episode',
              episodeNumber: 2,
              airDate: DateTime(2026, 8, 15),
            ),
          ],
        ),
        now: () => DateTime(2026, 8, 15, 12),
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('shows-tab-upcoming')),
      );

      await tester.pumpAndSettle();

      final Finder buttonFinder = find.byKey(
        const ValueKey<String>('shows-upcoming-mark-watched-today-episode'),
      );

      expect(buttonFinder, findsOneWidget);

      final IconButton button = tester.widget<IconButton>(buttonFinder);

      expect(
        button.onPressed,
        isNotNull,
        reason:
            'Episodes dated Today must be markable because no reliable '
            'air time is currently available.',
      );
    });

    testWidgets('disables Mark Watched for a future Upcoming Episode', (
      WidgetTester tester,
    ) async {
      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(
          shows: <LibraryShow>[_show],
          upcoming: <UpcomingItem>[
            _makeUpcomingItem(
              id: 'future-episode',
              episodeNumber: 3,
              airDate: DateTime(2026, 8, 16),
            ),
          ],
        ),
        now: () => DateTime(2026, 8, 15, 12),
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('shows-tab-upcoming')),
      );

      await tester.pumpAndSettle();

      final Finder buttonFinder = find.byKey(
        const ValueKey<String>('shows-upcoming-mark-watched-future-episode'),
      );

      expect(buttonFinder, findsOneWidget);

      final IconButton button = tester.widget<IconButton>(buttonFinder);

      expect(
        button.onPressed,
        isNull,
        reason: 'Future Episodes must not be markable as watched.',
      );
    });
    testWidgets(
      'shows per-Episode progress while marking Upcoming Episode watched',
      (WidgetTester tester) async {
        final _PendingUpcomingWatchRepository repository =
            _PendingUpcomingWatchRepository();

        final ShowsCubit cubit = ShowsCubit(
          repository: repository,
          now: () => DateTime(2026, 8, 15, 12),
        );

        addTearDown(cubit.close);

        await cubit.load();

        await tester.pumpWidget(_buildTestApp(cubit: cubit));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey<String>('shows-tab-upcoming')),
        );

        await tester.pumpAndSettle();

        final Finder buttonFinder = find.byKey(
          const ValueKey<String>('shows-upcoming-mark-watched-today-episode'),
        );

        expect(buttonFinder, findsOneWidget);

        await tester.tap(buttonFinder);
        await tester.pump();

        expect(repository.markEpisodeWatchedCalls, 1);

        expect(repository.markedEpisodeIds, <String>['today-episode']);

        expect(cubit.state.updatingUpcomingEpisodeId, 'today-episode');

        expect(
          find.descendant(
            of: buttonFinder,
            matching: find.byType(CircularProgressIndicator),
          ),
          findsOneWidget,
          reason:
              'Only the Episode currently being marked watched '
              'must show operation progress.',
        );

        repository.completeMarkWatched();

        await tester.pumpAndSettle();

        expect(cubit.state.updatingUpcomingEpisodeId, isNull);

        expect(
          repository.watchNextCalls,
          2,
          reason: 'Watch Next must refresh after marking from Upcoming.',
        );

        expect(
          repository.staleWatchingCalls,
          2,
          reason: 'stale Watching must refresh after marking from Upcoming.',
        );

        expect(
          repository.upcomingCalls,
          2,
          reason: 'Upcoming must refresh after the successful mutation.',
        );
      },
    );

    testWidgets('shows caught up Watching Show in Up to Date section', (
      WidgetTester tester,
    ) async {
      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(shows: <LibraryShow>[_upToDateShow]),
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('shows-up-to-date-section')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('shows-up-to-date-66732')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('shows-up-to-date-title-66732')),
        findsOneWidget,
      );

      expect(find.text('Stranger Things'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('shows-up-to-date-label-66732')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('shows-library-progress-66732')),
        findsOneWidget,
      );

      final LinearProgressIndicator progress = tester
          .widget<LinearProgressIndicator>(
            find.byKey(const ValueKey<String>('shows-library-progress-66732')),
          );

      expect(progress.value, 1.0);
    });
    testWidgets('hides Up to Date section when no Show is caught up', (
      WidgetTester tester,
    ) async {
      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(shows: <LibraryShow>[_show]),
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('shows-up-to-date-section')),
        findsNothing,
      );
    });

    testWidgets(
      'preserves Upcoming timeline and shows feedback when marking watched fails',
      (WidgetTester tester) async {
        final _FailingUpcomingWatchRepository repository =
            _FailingUpcomingWatchRepository();

        final ShowsCubit cubit = ShowsCubit(
          repository: repository,
          now: () => DateTime(2026, 8, 15, 12),
        );

        addTearDown(cubit.close);

        await cubit.load();

        await tester.pumpWidget(_buildTestApp(cubit: cubit));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey<String>('shows-tab-upcoming')),
        );

        await tester.pumpAndSettle();

        final Finder episodeRow = find.byKey(
          const ValueKey<String>('shows-upcoming-today-episode'),
        );

        final Finder buttonFinder = find.byKey(
          const ValueKey<String>('shows-upcoming-mark-watched-today-episode'),
        );

        expect(episodeRow, findsOneWidget);
        expect(buttonFinder, findsOneWidget);

        await tester.tap(buttonFinder);
        await tester.pumpAndSettle();

        expect(repository.markEpisodeWatchedCalls, 1);

        expect(
          repository.upcomingCalls,
          1,
          reason:
              'A failed mutation must not replace or reload '
              'the existing Upcoming timeline.',
        );

        expect(
          episodeRow,
          findsOneWidget,
          reason:
              'A failed mutation must preserve the existing Upcoming Episode.',
        );

        expect(cubit.state.upcomingOperationError, isNotNull);

        expect(
          find.text('Could not mark this episode as watched.'),
          findsOneWidget,
        );

        final IconButton button = tester.widget<IconButton>(
          find.byKey(
            const ValueKey<String>('shows-upcoming-mark-watched-today-episode'),
          ),
        );

        expect(
          button.onPressed,
          isNotNull,
          reason:
              'The Mark Watched action must become available again '
              'after failure.',
        );
      },
    );
    testWidgets('shows compact Refresh action on Mobile', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));

      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(shows: <LibraryShow>[_show]),
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('shows-refresh-mobile')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('shows-refresh-desktop')),
        findsNothing,
      );
    });
    testWidgets('shows labelled Refresh action on Desktop', (
      WidgetTester tester,
    ) async {
      _setTestViewport(
        tester,
        size: const Size(AppBreakpoints.desktop + 100, 1000),
      );

      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(shows: <LibraryShow>[_show]),
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('shows-refresh-desktop')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('shows-refresh-mobile')),
        findsNothing,
      );

      expect(find.text('Refresh'), findsOneWidget);
    });
    testWidgets('shows progress and disables Refresh while refreshing', (
      WidgetTester tester,
    ) async {
      _setTestViewport(
        tester,
        size: const Size(AppBreakpoints.desktop + 100, 1000),
      );

      final _PendingRefreshShowsRepository repository =
          _PendingRefreshShowsRepository();

      final ShowsCubit cubit = ShowsCubit(
        repository: repository,
        now: () => DateTime(2026, 8, 15, 12),
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pumpAndSettle();

      final Finder refreshButton = find.byKey(
        const ValueKey<String>('shows-refresh-desktop'),
      );

      expect(refreshButton, findsOneWidget);

      await tester.tap(refreshButton);
      await tester.pump();

      expect(cubit.state.isRefreshing, isTrue);

      expect(
        find.byKey(const ValueKey<String>('shows-refresh-progress')),
        findsOneWidget,
      );

      expect(find.text('Refreshing…'), findsOneWidget);

      final FilledButton button = tester.widget<FilledButton>(refreshButton);

      expect(
        button.onPressed,
        isNull,
        reason: 'Refresh must not be triggerable twice while already running.',
      );

      /*
   * Existing page content stays mounted during refresh.
   */
      expect(
        find.byKey(const ValueKey<String>('shows-watch-list')),
        findsOneWidget,
      );

      repository.completeRefresh();

      await tester.pumpAndSettle();

      expect(cubit.state.isRefreshing, isFalse);

      expect(
        find.byKey(const ValueKey<String>('shows-refresh-progress')),
        findsNothing,
      );

      expect(find.text('Refresh'), findsOneWidget);
    });
    testWidgets('preserves selected Shows tab during Refresh', (
      WidgetTester tester,
    ) async {
      _setTestViewport(
        tester,
        size: const Size(AppBreakpoints.desktop + 100, 1000),
      );

      final _PendingRefreshShowsRepository repository =
          _PendingRefreshShowsRepository();

      final ShowsCubit cubit = ShowsCubit(
        repository: repository,
        now: () => DateTime(2026, 8, 15, 12),
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('shows-tab-upcoming')),
      );

      await tester.pumpAndSettle();

      TabBar tabBar = tester.widget<TabBar>(
        find.byKey(const ValueKey<String>('shows-tabs')),
      );

      expect(tabBar.controller?.index, 1);

      await tester.tap(
        find.byKey(const ValueKey<String>('shows-refresh-desktop')),
      );

      await tester.pump();

      expect(cubit.state.isRefreshing, isTrue);

      /*
   * Refresh must not recreate the TabController or send the user
   * back to Watch List.
   */
      tabBar = tester.widget<TabBar>(
        find.byKey(const ValueKey<String>('shows-tabs')),
      );

      expect(tabBar.controller?.index, 1);

      expect(
        find.byKey(const ValueKey<String>('shows-upcoming-timeline')),
        findsOneWidget,
      );

      repository.completeRefresh();

      await tester.pumpAndSettle();

      tabBar = tester.widget<TabBar>(
        find.byKey(const ValueKey<String>('shows-tabs')),
      );

      expect(
        tabBar.controller?.index,
        1,
        reason: 'Refresh must preserve the currently selected Shows tab.',
      );
    });
    testWidgets(
      'opens Episode Details from Watch Next without changing card navigation',
      (WidgetTester tester) async {
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
          find.byKey(
            const ValueKey<String>(
              'shows-watch-next-episode-details-episode-uuid',
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('fake-episode-details')),
          findsOneWidget,
        );

        expect(find.text('Episode episode-uuid'), findsOneWidget);

        expect(
          find.byKey(const ValueKey<String>('fake-show-details')),
          findsNothing,
          reason:
              'Tapping the Episode target must not trigger the parent Show navigation.',
        );
      },
    );
    testWidgets(
      'preserves Watch List scroll position and context after returning from Show Details',
      (WidgetTester tester) async {
        _setTestViewport(tester, size: const Size(800, 500));

        final _FakeShowsRepository repository = _FakeShowsRepository(
          shows: <LibraryShow>[_show],
          watchNext: <WatchNextShow>[_watchNextShow],
          staleWatching: <StaleWatchingShow>[_staleWatchingShow],
        );

        final ShowsCubit cubit = ShowsCubit(repository: repository);

        addTearDown(cubit.close);

        await cubit.load();

        final GoRouter router = _buildRouter(cubit: cubit);

        addTearDown(router.dispose);

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));

        await tester.pumpAndSettle();

        final Finder watchListFinder = find.byKey(
          const ValueKey<String>('shows-watch-list'),
        );

        expect(watchListFinder, findsOneWidget);

        final ListView watchList = tester.widget<ListView>(watchListFinder);

        final ScrollController scrollController = watchList.controller!;

        /*
     * Move away from the initial Watch List position.
     */
        await tester.drag(watchListFinder, const Offset(0, -400));

        await tester.pumpAndSettle();

        final double offsetBeforeNavigation = scrollController.offset;

        expect(
          offsetBeforeNavigation,
          greaterThan(0),
          reason: 'The test must establish a non-zero Watch List position.',
        );

        /*
     * Navigation itself is already tested separately.
     *
     * Here the purpose is specifically proving that pushing a Details
     * route does not destroy the state of ShowsPage underneath it.
     */
        router.pushNamed(
          AppRoute.showDetails.name,
          pathParameters: <String, String>{'showId': _show.tmdbId.toString()},
        );

        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('fake-show-details')),
          findsOneWidget,
        );

        router.pop();

        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('shows-watch-list')),
          findsOneWidget,
        );

        final ListView returnedWatchList = tester.widget<ListView>(
          find.byKey(const ValueKey<String>('shows-watch-list')),
        );

        final ScrollController returnedScrollController =
            returnedWatchList.controller!;

        /*
     * The StatefulWidget remained mounted, therefore its controller and
     * scroll offset must still be the same.
     */
        expect(
          returnedScrollController,
          same(scrollController),
          reason:
              'Returning from Show Details must not recreate the Watch List '
              'ScrollController.',
        );

        expect(
          returnedScrollController.offset,
          closeTo(offsetBeforeNavigation, 0.5),
          reason:
              'Returning from Show Details must preserve the Watch List '
              'scroll position.',
        );

        final TabBar tabBar = tester.widget<TabBar>(
          find.byKey(const ValueKey<String>('shows-tabs')),
        );

        expect(
          tabBar.controller?.index,
          0,
          reason:
              'Returning from Show Details must preserve the Watch List tab.',
        );

        /*
     * Navigating away and back must not silently reload the page.
     */
      },
    );
    testWidgets(
      'preserves Upcoming scroll position and context after returning from Episode Details',
      (WidgetTester tester) async {
        _setTestViewport(tester, size: const Size(800, 500));

        final List<UpcomingItem> upcoming = List<UpcomingItem>.generate(18, (
          int index,
        ) {
          return _makeUpcomingItem(
            id: 'navigation-upcoming-$index',
            episodeNumber: index + 1,
            airDate: DateTime(2026, 8, 15).add(Duration(days: index)),
          );
        });

        final _FakeShowsRepository repository = _FakeShowsRepository(
          shows: <LibraryShow>[_show],
          upcoming: upcoming,
        );

        final ShowsCubit cubit = ShowsCubit(
          repository: repository,
          now: () => DateTime(2026, 8, 15, 12),
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

        final Finder timelineFinder = find.byKey(
          const ValueKey<String>('shows-upcoming-timeline'),
        );

        expect(timelineFinder, findsOneWidget);

        final CustomScrollView timeline = tester.widget<CustomScrollView>(
          timelineFinder,
        );

        final ScrollController scrollController = timeline.controller!;

        /*
     * Scroll into the future so that position preservation can actually
     * be observed.
     */
        await tester.drag(timelineFinder, const Offset(0, -450));

        await tester.pumpAndSettle();

        final double offsetBeforeNavigation = scrollController.offset;

        expect(
          offsetBeforeNavigation,
          greaterThan(0),
          reason:
              'The test must establish a non-zero Upcoming timeline position.',
        );

        final UpcomingItem episode = upcoming.first;

        router.pushNamed(
          AppRoute.episodeDetails.name,
          pathParameters: <String, String>{'episodeId': episode.episode.id},
        );

        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('fake-episode-details')),
          findsOneWidget,
        );

        router.pop();

        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('shows-upcoming-timeline')),
          findsOneWidget,
        );

        tabBar = tester.widget<TabBar>(
          find.byKey(const ValueKey<String>('shows-tabs')),
        );

        expect(
          tabBar.controller?.index,
          1,
          reason:
              'Returning from Episode Details must preserve the Upcoming tab.',
        );

        final CustomScrollView returnedTimeline = tester
            .widget<CustomScrollView>(
              find.byKey(const ValueKey<String>('shows-upcoming-timeline')),
            );

        final ScrollController returnedScrollController =
            returnedTimeline.controller!;

        expect(
          returnedScrollController,
          same(scrollController),
          reason:
              'Returning from Episode Details must not recreate the '
              'Upcoming ScrollController.',
        );

        expect(
          returnedScrollController.offset,
          closeTo(offsetBeforeNavigation, 0.5),
          reason:
              'Returning from Episode Details must preserve the Upcoming '
              'timeline position.',
        );

        /*
     * Existing loaded Upcoming context also remains untouched.
     */
        expect(cubit.state.upcoming, upcoming);
      },
    );
    testWidgets('renders Watch List compactly on Mobile', (
      WidgetTester tester,
    ) async {
      _setTestViewport(tester, size: const Size(390, 844));

      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(
          shows: <LibraryShow>[_show],
          watchNext: <WatchNextShow>[_watchNextShow],
          staleWatching: <StaleWatchingShow>[_staleWatchingShow],
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
        find.byKey(const ValueKey<String>('shows-watch-next-95396')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('shows-refresh-mobile')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('shows-refresh-desktop')),
        findsNothing,
      );

      expect(tester.takeException(), isNull);
    });
    testWidgets('renders Upcoming compactly on Mobile', (
      WidgetTester tester,
    ) async {
      _setTestViewport(tester, size: const Size(390, 844));

      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(
          shows: <LibraryShow>[_show],
          upcoming: <UpcomingItem>[
            _makeUpcomingItem(
              id: 'mobile-upcoming',
              episodeNumber: 1,
              airDate: DateTime(2026, 8, 15),
            ),
          ],
        ),
        now: () => DateTime(2026, 8, 15, 12),
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
        find.byKey(const ValueKey<String>('shows-upcoming-timeline')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('shows-upcoming-mobile-upcoming')),
        findsOneWidget,
      );

      expect(tester.takeException(), isNull);
    });
    testWidgets('keeps long Watch List content compact on Mobile', (
      WidgetTester tester,
    ) async {
      _setTestViewport(tester, size: const Size(390, 844));

      final WatchNextShow longContentShow = WatchNextShow(
        libraryEntryId: 'library-mobile-long',
        libraryStatus: LibraryStatus.watching,
        showId: 'show-mobile-long',
        showTmdbId: 999001,
        showTitle:
            'This Is an Extremely Long Television Series Title Used for Responsive Testing',
        posterUrl: null,
        backdropUrl: null,
        nextEpisode: WatchNextEpisode(
          id: 'episode-mobile-long',
          tmdbId: 999002,
          seasonNumber: 12,
          episodeNumber: 24,
          title:
              'This Is Also an Extremely Long Episode Title That Must Not Overflow',
          airDate: DateTime(2026, 8, 15),
          runtime: 58,
          stillUrl: null,
        ),
        progress: const WatchNextProgress(
          watchedEpisodes: 23,
          airedEpisodes: 24,
          percentage: 95.8,
        ),
      );

      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(
          shows: <LibraryShow>[_show],
          watchNext: <WatchNextShow>[longContentShow],
        ),
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('shows-watch-next-999001')),
        findsOneWidget,
      );

      expect(tester.takeException(), isNull);
    });
    testWidgets('keeps Haven\'t Started actions usable on Mobile', (
      WidgetTester tester,
    ) async {
      _setTestViewport(tester, size: const Size(390, 844));

      final LibraryShow planningShow = LibraryShow(
        libraryEntryId: 'library-planning-mobile',
        showId: 'show-planning-mobile',
        tmdbId: 777001,
        title: 'A Very Long Show Title for Mobile Layout Validation',
        originalTitle: 'A Very Long Show Title for Mobile Layout Validation',
        status: LibraryStatus.planning,
        showStatus: 'Returning Series',
        voteAverage: 8.5,
        createdAt: DateTime.utc(2026, 8, 1),
        updatedAt: DateTime.utc(2026, 8, 15),
        progress: _emptyLibraryShowProgress,
        firstAvailableEpisode: LibraryFirstEpisode(
          id: 'first-mobile-episode',
          tmdbId: 777002,
          seasonNumber: 1,
          episodeNumber: 1,
          title: 'A Very Long First Episode Title',
          airDate: DateTime(2026, 8, 10),
          runtime: 55,
        ),
      );

      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(shows: <LibraryShow>[planningShow]),
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      final Finder startButton = find.byKey(
        const ValueKey<String>('shows-havent-started-start-777001'),
      );

      await tester.ensureVisible(startButton);
      await tester.pumpAndSettle();

      expect(startButton, findsOneWidget);

      expect(tester.takeException(), isNull);
    });
    testWidgets('constrains and centers Watch List on wide Desktop', (
      WidgetTester tester,
    ) async {
      _setTestViewport(tester, size: const Size(1920, 1080));

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

      final Finder content = find.byKey(
        const ValueKey<String>('shows-watch-list-content'),
      );

      expect(content, findsOneWidget);

      final Size contentSize = tester.getSize(content);

      expect(
        contentSize.width,
        closeTo(1040, 0.5),
        reason:
            'Watch List should use the available Desktop width only up to its '
            'maximum readable width.',
      );

      final Offset topLeft = tester.getTopLeft(content);

      expect(
        topLeft.dx,
        closeTo((1920 - 1040) / 2, 1),
        reason: 'Wide Desktop content should remain horizontally centered.',
      );

      expect(tester.takeException(), isNull);
    });
    testWidgets('constrains and centers Upcoming on wide Desktop', (
      WidgetTester tester,
    ) async {
      _setTestViewport(tester, size: const Size(1920, 1080));

      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(
          shows: <LibraryShow>[_show],
          upcoming: <UpcomingItem>[
            _makeUpcomingItem(
              id: 'desktop-upcoming',
              episodeNumber: 1,
              airDate: DateTime(2026, 8, 15),
            ),
          ],
        ),
        now: () => DateTime(2026, 8, 15, 12),
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey<String>('shows-tab-upcoming')),
      );

      await tester.pumpAndSettle();

      final Finder content = find.byKey(
        const ValueKey<String>('shows-upcoming-today-content'),
      );

      expect(content, findsOneWidget);

      expect(tester.getSize(content).width, closeTo(1040, 0.5));

      expect(tester.getTopLeft(content).dx, closeTo((1920 - 1040) / 2, 1));

      expect(
        find.byKey(const ValueKey<String>('shows-upcoming-desktop-upcoming')),
        findsOneWidget,
      );

      expect(tester.takeException(), isNull);
    });
    testWidgets('paginates stale Watching Shows after six mobile cards', (
      WidgetTester tester,
    ) async {
      final List<StaleWatchingShow> staleShows =
          List<StaleWatchingShow>.generate(7, (int index) {
            final int number = index + 1;

            return StaleWatchingShow(
              libraryEntryId: 'library-stale-$number',
              libraryStatus: LibraryStatus.watching,
              showId: 'show-stale-$number',
              showTmdbId: 100000 + number,
              showTitle: 'Stale Show $number',
              posterUrl: null,
              backdropUrl: null,
              lastWatched: StaleWatchingEpisode(
                id: 'last-$number',
                tmdbId: 200000 + number,
                seasonNumber: 1,
                episodeNumber: number,
                title: 'Last Episode $number',
                watchedAt: DateTime.utc(2026, 5, 1),
              ),
              nextEpisode: WatchNextEpisode(
                id: 'next-$number',
                tmdbId: 300000 + number,
                seasonNumber: 1,
                episodeNumber: number + 1,
                title: 'Next Episode $number',
                runtime: 45,
              ),
              progress: const LibraryShowProgress(
                watchedEpisodes: 4,
                airedEpisodes: 10,
                percentage: 40,
                caughtUp: false,
              ),
            );
          });

      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(
          shows: <LibraryShow>[_show],
          staleWatching: staleShows,
        ),
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('shows-stale-watching-pager')),
        findsOneWidget,
      );

      expect(
        find.byKey(
          const ValueKey<String>('shows-stale-watching-page-indicator'),
        ),
        findsOneWidget,
      );

      expect(find.text('Stale Show 1'), findsOneWidget);

      /*
     * The seventh Show belongs to the second page and should not yet be
     * painted by the PageView.
     */
      expect(find.text('Stale Show 7'), findsNothing);

      final Finder stalePager = find.byKey(
        const ValueKey<String>('shows-stale-watching-pager'),
      );

      await tester.ensureVisible(stalePager);
      await tester.pumpAndSettle();

      final Offset pagerTopLeft = tester.getTopLeft(stalePager);

      await tester.dragFrom(
        Offset(pagerTopLeft.dx + 200, pagerTopLeft.dy + 100),
        const Offset(-500, 0),
      );

      await tester.pumpAndSettle();

      expect(find.text('Stale Show 7'), findsOneWidget);
    });
    testWidgets(
      'shows Haven\'t Started refresh only when at least six Shows exist',
      (WidgetTester tester) async {
        final List<LibraryShow> fiveShows = List<LibraryShow>.generate(
          5,
          (int index) => _makeHaventStartedShow(index: index + 1),
        );

        final ShowsCubit cubitWithFive = ShowsCubit(
          repository: _FakeShowsRepository(shows: fiveShows),
        );

        addTearDown(cubitWithFive.close);

        await cubitWithFive.load();

        await tester.pumpWidget(_buildTestApp(cubit: cubitWithFive));

        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('shows-havent-started-refresh')),
          findsNothing,
        );

        await tester.pumpWidget(const SizedBox.shrink());

        final List<LibraryShow> sixShows = List<LibraryShow>.generate(
          6,
          (int index) => _makeHaventStartedShow(index: index + 1),
        );

        final ShowsCubit cubitWithSix = ShowsCubit(
          repository: _FakeShowsRepository(shows: sixShows),
        );

        addTearDown(cubitWithSix.close);

        await cubitWithSix.load();

        await tester.pumpWidget(_buildTestApp(cubit: cubitWithSix));

        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('shows-havent-started-refresh')),
          findsOneWidget,
        );
      },
    );
    testWidgets(
      'refreshes Haven\'t Started preview while keeping five visible Shows',
      (WidgetTester tester) async {
        final List<LibraryShow> shows = List<LibraryShow>.generate(
          8,
          (int index) => _makeHaventStartedShow(index: index + 1),
        );

        final ShowsCubit cubit = ShowsCubit(
          repository: _FakeShowsRepository(shows: shows),
        );

        addTearDown(cubit.close);

        await cubit.load();

        await tester.pumpWidget(_buildTestApp(cubit: cubit));

        await tester.pumpAndSettle();

        final Finder refreshButton = find.byKey(
          const ValueKey<String>('shows-havent-started-refresh'),
        );

        expect(refreshButton, findsOneWidget);

        int visibleCount() {
          return shows.where((LibraryShow show) {
            return find
                .byKey(ValueKey<String>('shows-havent-started-${show.tmdbId}'))
                .evaluate()
                .isNotEmpty;
          }).length;
        }

        expect(visibleCount(), 5);

        await tester.tap(refreshButton);
        await tester.pumpAndSettle();

        expect(visibleCount(), 5);
      },
    );
  });
}

void _setTestViewport(WidgetTester tester, {required Size size}) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;

  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
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
      GoRoute(
        name: AppRoute.episodeDetails.name,
        path: '/episodes/:episodeId',
        builder: (BuildContext context, GoRouterState state) {
          final String episodeId = state.pathParameters['episodeId']!;

          return Scaffold(
            key: const ValueKey<String>('fake-episode-details'),
            body: Center(child: Text('Episode $episodeId')),
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
  progress: _emptyLibraryShowProgress,
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

final LibraryShow _upToDateShow = LibraryShow(
  libraryEntryId: 'library-up-to-date',
  showId: 'show-up-to-date',
  tmdbId: 66732,
  title: 'Stranger Things',
  originalTitle: 'Stranger Things',
  status: LibraryStatus.watching,
  showStatus: 'Returning Series',
  voteAverage: 8.6,
  createdAt: DateTime.utc(2026, 8, 1),
  updatedAt: DateTime.utc(2026, 8, 15),
  progress: const LibraryShowProgress(
    watchedEpisodes: 34,
    airedEpisodes: 34,
    percentage: 100,
    caughtUp: true,
  ),
);

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
  progress: const LibraryShowProgress(
    watchedEpisodes: 4,
    airedEpisodes: 10,
    percentage: 40,
    caughtUp: false,
  ),
);

UpcomingItem _makeUpcomingItem({
  required String id,
  required int episodeNumber,
  required DateTime airDate,
}) {
  return UpcomingItem(
    libraryEntryId: 'library-$id',
    libraryStatus: LibraryStatus.watching,
    showId: 'show-$id',
    showTmdbId: 95396,
    showTitle: 'Severance',
    posterUrl: null,
    backdropUrl: null,
    episode: UpcomingEpisode(
      id: id,
      tmdbId: 4000000 + episodeNumber,
      seasonNumber: 3,
      episodeNumber: episodeNumber,
      title: 'Episode $episodeNumber',
      airDate: airDate,
      runtime: 52,
      stillUrl: null,
      isWatched: false,
    ),
  );
}

const LibraryShowProgress _emptyLibraryShowProgress = LibraryShowProgress(
  watchedEpisodes: 0,
  airedEpisodes: 0,
  percentage: 0,
  caughtUp: false,
);

List<UpcomingItem> _currentUpcomingItems() {
  return List<UpcomingItem>.generate(40, (int index) {
    return _makeUpcomingItem(
      id: 'current-$index',
      episodeNumber: index + 1,
      airDate: DateTime(2026, 8, 15).add(Duration(days: index)),
    );
  });
}

final class _FakeShowsRepository implements ShowsRepository {
  const _FakeShowsRepository({
    required this.shows,
    this.watchNext = const <WatchNextShow>[],
    this.staleWatching = const <StaleWatchingShow>[],
    this.upcoming = const <UpcomingItem>[],
  });

  final List<LibraryShow> shows;
  final List<WatchNextShow> watchNext;
  final List<StaleWatchingShow> staleWatching;
  final List<UpcomingItem> upcoming;

  @override
  Future<List<LibraryShow>> getLibraryShows() async {
    return shows;
  }

  @override
  Future<List<WatchNextShow>> getWatchNext({int? limit}) async {
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

  @override
  Future<List<UpcomingItem>> getMissedRecently() async {
    return const <UpcomingItem>[];
  }

  @override
  Future<List<UpcomingItem>> getUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) async {
    return upcoming;
  }
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
  Future<List<WatchNextShow>> getWatchNext({int? limit}) async {
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

  @override
  Future<List<UpcomingItem>> getMissedRecently() async {
    return const <UpcomingItem>[];
  }

  @override
  Future<List<UpcomingItem>> getUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) async {
    return const <UpcomingItem>[];
  }
}

final class _WatchNextFailureRepository implements ShowsRepository {
  const _WatchNextFailureRepository({required this.shows});

  final List<LibraryShow> shows;

  @override
  Future<List<LibraryShow>> getLibraryShows() async {
    return shows;
  }

  @override
  Future<List<WatchNextShow>> getWatchNext({int? limit}) async {
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

  @override
  Future<List<UpcomingItem>> getMissedRecently() async {
    return const <UpcomingItem>[];
  }

  @override
  Future<List<UpcomingItem>> getUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) async {
    return const <UpcomingItem>[];
  }
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
  Future<List<WatchNextShow>> getWatchNext({int? limit}) async {
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

  @override
  Future<List<UpcomingItem>> getMissedRecently() async {
    return const <UpcomingItem>[];
  }

  @override
  Future<List<UpcomingItem>> getUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) async {
    return const <UpcomingItem>[];
  }
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
  Future<List<WatchNextShow>> getWatchNext({int? limit}) async {
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

  @override
  Future<List<UpcomingItem>> getMissedRecently() async {
    return const <UpcomingItem>[];
  }

  @override
  Future<List<UpcomingItem>> getUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) async {
    return const <UpcomingItem>[];
  }
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
  Future<List<WatchNextShow>> getWatchNext({int? limit}) async {
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

  @override
  Future<List<UpcomingItem>> getMissedRecently() async {
    return const <UpcomingItem>[];
  }

  @override
  Future<List<UpcomingItem>> getUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) async {
    return const <UpcomingItem>[];
  }
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
  Future<List<WatchNextShow>> getWatchNext({int? limit}) async {
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

  @override
  Future<List<UpcomingItem>> getMissedRecently() async {
    return const <UpcomingItem>[];
  }

  @override
  Future<List<UpcomingItem>> getUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) async {
    return const <UpcomingItem>[];
  }
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
  Future<List<WatchNextShow>> getWatchNext({int? limit}) async {
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

  @override
  Future<List<UpcomingItem>> getMissedRecently() async {
    return const <UpcomingItem>[];
  }

  @override
  Future<List<UpcomingItem>> getUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) async {
    return const <UpcomingItem>[];
  }
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
  Future<List<WatchNextShow>> getWatchNext({int? limit}) async {
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

  @override
  Future<List<UpcomingItem>> getMissedRecently() async {
    return const <UpcomingItem>[];
  }

  @override
  Future<List<UpcomingItem>> getUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) async {
    return const <UpcomingItem>[];
  }
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
  Future<List<WatchNextShow>> getWatchNext({int? limit}) async {
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
  Future<List<UpcomingItem>> getUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) async {
    return const <UpcomingItem>[];
  }

  @override
  Future<void> startShow({required String showId}) {
    startShowCalls++;

    return _startCompleter.future;
  }

  @override
  Future<List<UpcomingItem>> getMissedRecently() async {
    return const <UpcomingItem>[];
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
        progress: _emptyLibraryShowProgress,
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
  Future<List<WatchNextShow>> getWatchNext({int? limit}) async {
    return const <WatchNextShow>[];
  }

  @override
  Future<List<StaleWatchingShow>> getStaleWatching() async {
    return const <StaleWatchingShow>[];
  }

  @override
  Future<List<UpcomingItem>> getMissedRecently() async {
    return const <UpcomingItem>[];
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
  Future<List<UpcomingItem>> getUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) async {
    return const <UpcomingItem>[];
  }
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
  Future<List<UpcomingItem>> getMissedRecently() async {
    return const <UpcomingItem>[];
  }

  @override
  Future<List<WatchNextShow>> getWatchNext({int? limit}) async {
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
  Future<List<UpcomingItem>> getUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) async {
    return const <UpcomingItem>[];
  }
}

final class _ScrollableUpcomingRepository implements ShowsRepository {
  int upcomingCalls = 0;

  final List<DateTime?> fromDates = <DateTime?>[];
  final List<DateTime?> toDates = <DateTime?>[];

  @override
  Future<List<UpcomingItem>> getUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) async {
    upcomingCalls++;

    fromDates.add(fromDate);
    toDates.add(toDate);

    if (upcomingCalls == 1) {
      return _currentUpcomingItems();
    }

    return <UpcomingItem>[
      _makeUpcomingItem(
        id: 'earlier-episode',
        episodeNumber: 1,
        airDate: DateTime(2026, 8, 1),
      ),
    ];
  }

  @override
  Future<List<LibraryShow>> getLibraryShows() async {
    return <LibraryShow>[_show];
  }

  @override
  Future<List<WatchNextShow>> getWatchNext({int? limit}) async {
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

  @override
  Future<List<UpcomingItem>> getMissedRecently() async {
    return const <UpcomingItem>[];
  }
}

final class _PendingEarlierUpcomingRepository implements ShowsRepository {
  int upcomingCalls = 0;

  final Completer<List<UpcomingItem>> _earlierCompleter =
      Completer<List<UpcomingItem>>();

  void completeEarlier(List<UpcomingItem> items) {
    _earlierCompleter.complete(items);
  }

  @override
  Future<List<UpcomingItem>> getUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) {
    upcomingCalls++;

    if (upcomingCalls == 1) {
      return Future<List<UpcomingItem>>.value(_currentUpcomingItems());
    }

    return _earlierCompleter.future;
  }

  @override
  Future<List<LibraryShow>> getLibraryShows() async => <LibraryShow>[_show];

  @override
  Future<List<WatchNextShow>> getWatchNext({int? limit}) async =>
      const <WatchNextShow>[];

  @override
  Future<List<StaleWatchingShow>> getStaleWatching() async =>
      const <StaleWatchingShow>[];

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

  @override
  Future<List<UpcomingItem>> getMissedRecently() async {
    return const <UpcomingItem>[];
  }
}

final class _FailingEarlierUpcomingPageRepository implements ShowsRepository {
  int upcomingCalls = 0;

  @override
  Future<List<UpcomingItem>> getUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) async {
    upcomingCalls++;

    if (upcomingCalls == 1) {
      return _currentUpcomingItems();
    }

    if (upcomingCalls == 2) {
      throw const AppException.connection();
    }

    return <UpcomingItem>[
      _makeUpcomingItem(
        id: 'earlier-episode',
        episodeNumber: 1,
        airDate: DateTime(2026, 8, 1),
      ),
    ];
  }

  @override
  Future<List<LibraryShow>> getLibraryShows() async => <LibraryShow>[_show];

  @override
  Future<List<WatchNextShow>> getWatchNext({int? limit}) async =>
      const <WatchNextShow>[];

  @override
  Future<List<StaleWatchingShow>> getStaleWatching() async =>
      const <StaleWatchingShow>[];

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

  @override
  Future<List<UpcomingItem>> getMissedRecently() async {
    return const <UpcomingItem>[];
  }
}

final class _PendingUpcomingWatchRepository implements ShowsRepository {
  _PendingUpcomingWatchRepository();

  final Completer<void> _markWatchedCompleter = Completer<void>();

  int markEpisodeWatchedCalls = 0;
  int upcomingCalls = 0;
  int watchNextCalls = 0;
  int staleWatchingCalls = 0;

  final List<String> markedEpisodeIds = <String>[];

  void completeMarkWatched() {
    _markWatchedCompleter.complete();
  }

  @override
  Future<List<LibraryShow>> getLibraryShows() async {
    return <LibraryShow>[_show];
  }

  @override
  Future<List<WatchNextShow>> getWatchNext({int? limit}) async {
    watchNextCalls++;

    return const <WatchNextShow>[];
  }

  @override
  Future<List<StaleWatchingShow>> getStaleWatching() async {
    staleWatchingCalls++;

    return const <StaleWatchingShow>[];
  }

  @override
  Future<List<UpcomingItem>> getUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) async {
    upcomingCalls++;

    return <UpcomingItem>[
      _makeUpcomingItem(
        id: 'today-episode',
        episodeNumber: 1,
        airDate: DateTime(2026, 8, 15),
      ),
    ];
  }

  @override
  Future<void> markEpisodeWatched({required String episodeId}) {
    markEpisodeWatchedCalls++;
    markedEpisodeIds.add(episodeId);

    return _markWatchedCompleter.future;
  }

  @override
  Future<void> markEpisodeUnwatched({required String episodeId}) async {}

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
  Future<void> startShow({required String showId}) async {}

  @override
  Future<List<UpcomingItem>> getMissedRecently() async {
    return const <UpcomingItem>[];
  }
}

final class _FailingUpcomingWatchRepository implements ShowsRepository {
  int markEpisodeWatchedCalls = 0;
  int upcomingCalls = 0;

  @override
  Future<List<LibraryShow>> getLibraryShows() async {
    return <LibraryShow>[_show];
  }

  @override
  Future<List<WatchNextShow>> getWatchNext({int? limit}) async {
    return const <WatchNextShow>[];
  }

  @override
  Future<List<StaleWatchingShow>> getStaleWatching() async {
    return const <StaleWatchingShow>[];
  }

  @override
  Future<List<UpcomingItem>> getUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) async {
    upcomingCalls++;

    return <UpcomingItem>[
      _makeUpcomingItem(
        id: 'today-episode',
        episodeNumber: 1,
        airDate: DateTime(2026, 8, 15),
      ),
    ];
  }

  @override
  Future<void> markEpisodeWatched({required String episodeId}) {
    markEpisodeWatchedCalls++;

    throw const AppException.connection();
  }

  @override
  Future<void> markEpisodeUnwatched({required String episodeId}) async {}

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
  Future<void> startShow({required String showId}) async {}

  @override
  Future<List<UpcomingItem>> getMissedRecently() async {
    return const <UpcomingItem>[];
  }
}

final class _PendingRefreshShowsRepository implements ShowsRepository {
  int libraryCalls = 0;
  int watchNextCalls = 0;
  int staleWatchingCalls = 0;
  int upcomingCalls = 0;

  Completer<List<LibraryShow>>? _refreshLibraryCompleter;

  void completeRefresh() {
    final Completer<List<LibraryShow>>? completer = _refreshLibraryCompleter;

    if (completer == null || completer.isCompleted) {
      return;
    }

    completer.complete(<LibraryShow>[_show]);
  }

  @override
  Future<List<LibraryShow>> getLibraryShows() {
    libraryCalls++;

    /*
     * First request is the initial page load.
     *
     * The second request is the explicit Refresh and remains pending
     * until the test completes it.
     */
    if (libraryCalls == 1) {
      return Future<List<LibraryShow>>.value(<LibraryShow>[_show]);
    }

    _refreshLibraryCompleter ??= Completer<List<LibraryShow>>();

    return _refreshLibraryCompleter!.future;
  }

  @override
  Future<List<WatchNextShow>> getWatchNext({int? limit}) async {
    watchNextCalls++;

    return <WatchNextShow>[_watchNextShow];
  }

  @override
  Future<List<StaleWatchingShow>> getStaleWatching() async {
    staleWatchingCalls++;

    return const <StaleWatchingShow>[];
  }

  @override
  Future<List<UpcomingItem>> getUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
  }) async {
    upcomingCalls++;

    return <UpcomingItem>[
      _makeUpcomingItem(
        id: 'refresh-upcoming',
        episodeNumber: 1,
        airDate: DateTime(2026, 8, 15),
      ),
    ];
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

  @override
  Future<List<UpcomingItem>> getMissedRecently() async {
    return const <UpcomingItem>[];
  }
}

LibraryShow _makeHaventStartedShow({required int index}) {
  return LibraryShow(
    libraryEntryId: 'library-havent-started-$index',
    showId: 'show-havent-started-$index',
    tmdbId: 500000 + index,
    title: 'Haven\'t Started Show $index',
    originalTitle: 'Haven\'t Started Show $index',
    status: LibraryStatus.planning,
    showStatus: 'Returning Series',
    voteAverage: 8,
    createdAt: DateTime.utc(2026, 8, 1),
    updatedAt: DateTime.utc(2026, 8, 10),
    progress: _emptyLibraryShowProgress,
  );
}
