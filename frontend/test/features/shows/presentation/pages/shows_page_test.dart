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
import 'package:sofawatch/features/shows/domain/models/watch_next_episode.dart';
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

      expect(find.text("Woe's Hollow"), findsOneWidget);

      expect(find.textContaining('S02E04'), findsOneWidget);

      expect(find.textContaining('52 min'), findsOneWidget);
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
);

final class _FakeShowsRepository implements ShowsRepository {
  const _FakeShowsRepository({
    required this.shows,
    this.watchNext = const <WatchNextShow>[],
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
}
