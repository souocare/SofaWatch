import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/core/viewing/viewing_state_change_notifier.dart';
import 'package:sofawatch/features/history/application/cubit/history_cubit.dart';
import 'package:sofawatch/features/history/domain/models/history_episode.dart';
import 'package:sofawatch/features/history/domain/models/history_episode_item.dart';
import 'package:sofawatch/features/history/domain/models/history_item.dart';
import 'package:sofawatch/features/history/domain/models/history_movie_item.dart';
import 'package:sofawatch/features/history/domain/models/history_page.dart'
    as history_domain;
import 'package:sofawatch/features/history/domain/models/history_preview.dart';
import 'package:sofawatch/features/history/domain/repositories/history_repository.dart';
import 'package:sofawatch/features/history/presentation/pages/history_page.dart';

void main() {
  group('HistoryPage', () {
    testWidgets('shows Episode and Movie History in backend order', (
      WidgetTester tester,
    ) async {
      final _HistoryRepository repository = _HistoryRepository(
        pages: <String?, history_domain.HistoryPage>{
          null: history_domain.HistoryPage(
            items: <HistoryItem>[_movieItem1, _episodeItem1, _movieItem2],
            hasMore: false,
          ),
        },
      );

      await tester.pumpWidget(_buildTestApp(repository: repository));

      await tester.pumpAndSettle();

      expect(find.text('History'), findsOneWidget);

      expect(find.text('Dune'), findsOneWidget);
      expect(find.text('Severance'), findsOneWidget);
      expect(find.text('Arrival'), findsOneWidget);

      expect(find.text('S01E01 · Good News About Hell'), findsOneWidget);

      final double duneY = tester.getTopLeft(find.text('Dune')).dy;
      final double severanceY = tester.getTopLeft(find.text('Severance')).dy;
      final double arrivalY = tester.getTopLeft(find.text('Arrival')).dy;

      expect(duneY, lessThan(severanceY));
      expect(severanceY, lessThan(arrivalY));
    });

    testWidgets('shows empty state when History has no items', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildTestApp(repository: _HistoryRepository()));

      await tester.pumpAndSettle();

      expect(find.text('History'), findsOneWidget);

      expect(
        find.byKey(const ValueKey<String>('history-empty')),
        findsOneWidget,
      );

      expect(find.text('Dune'), findsNothing);
      expect(find.text('Severance'), findsNothing);
    });

    testWidgets('shows initial failure without History items', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          repository: _HistoryRepository(
            initialError: const AppException.connection(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('History'), findsOneWidget);

      expect(find.text('Dune'), findsNothing);
      expect(find.text('Severance'), findsNothing);

      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retries initial History after failure', (
      WidgetTester tester,
    ) async {
      final _RetryHistoryRepository repository = _RetryHistoryRepository();

      await tester.pumpWidget(_buildTestApp(repository: repository));

      await tester.pumpAndSettle();

      expect(repository.calls, 1);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));

      await tester.pumpAndSettle();

      expect(repository.calls, 2);

      expect(find.text('Dune'), findsOneWidget);
      expect(find.text('Severance'), findsOneWidget);
    });

    testWidgets('loads the next History page', (WidgetTester tester) async {
      final _HistoryRepository repository = _HistoryRepository(
        pages: <String?, history_domain.HistoryPage>{
          null: history_domain.HistoryPage(
            items: <HistoryItem>[_movieItem1, _episodeItem1],
            nextCursor: 'cursor-1',
            hasMore: true,
          ),
          'cursor-1': history_domain.HistoryPage(
            items: <HistoryItem>[_movieItem2, _episodeItem2],
            hasMore: false,
          ),
        },
      );

      await tester.pumpWidget(_buildTestApp(repository: repository));

      await tester.pumpAndSettle();

      expect(find.text('Dune'), findsOneWidget);
      expect(find.text('Severance'), findsOneWidget);

      expect(find.text('Arrival'), findsNothing);
      expect(find.text('Dark'), findsNothing);

      final Finder loadMore = find.text('Load more');

      expect(loadMore, findsOneWidget);

      await tester.ensureVisible(loadMore);
      await tester.tap(loadMore);

      await tester.pumpAndSettle();

      expect(repository.calls, 2);

      expect(find.text('Dune'), findsOneWidget);
      expect(find.text('Severance'), findsOneWidget);
      expect(find.text('Arrival'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);

      expect(find.text('Load more'), findsNothing);
    });

    testWidgets('pagination failure preserves already loaded History', (
      WidgetTester tester,
    ) async {
      final _PaginationFailureHistoryRepository repository =
          _PaginationFailureHistoryRepository();

      await tester.pumpWidget(_buildTestApp(repository: repository));

      await tester.pumpAndSettle();

      expect(find.text('Dune'), findsOneWidget);
      expect(find.text('Severance'), findsOneWidget);

      final Finder loadMore = find.text('Load more');

      await tester.ensureVisible(loadMore);
      await tester.tap(loadMore);

      await tester.pumpAndSettle();

      /*
         * A pagination failure is non-fatal.
         *
         * Existing server-owned History must remain visible.
         */
      expect(find.text('Dune'), findsOneWidget);
      expect(find.text('Severance'), findsOneWidget);

      expect(repository.paginationCalls, 1);
    });

    testWidgets('opens Episode Details from Episode History', (
      WidgetTester tester,
    ) async {
      final GoRouter router = _buildRouter(
        repository: _HistoryRepository(
          pages: <String?, history_domain.HistoryPage>{
            null: history_domain.HistoryPage(
              items: <HistoryItem>[_episodeItem1],
              hasMore: false,
            ),
          },
        ),
      );

      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      await tester.pumpAndSettle();

      final Finder episodeRow = find.byKey(
        const ValueKey<String>('history-episode-episode-event-1'),
      );

      expect(episodeRow, findsOneWidget);

      await tester.tap(episodeRow);

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('test-episode-details')),
        findsOneWidget,
      );

      expect(find.text('Episode episode-1'), findsOneWidget);
    });

    testWidgets('opens Movie Details from Movie History', (
      WidgetTester tester,
    ) async {
      final GoRouter router = _buildRouter(
        repository: _HistoryRepository(
          pages: <String?, history_domain.HistoryPage>{
            null: history_domain.HistoryPage(
              items: <HistoryItem>[_movieItem1],
              hasMore: false,
            ),
          },
        ),
      );

      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      await tester.pumpAndSettle();

      final Finder movieRow = find.byKey(
        const ValueKey<String>('history-movie-movie-event-1'),
      );

      expect(movieRow, findsOneWidget);

      await tester.tap(movieRow);

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('test-movie-details')),
        findsOneWidget,
      );

      /*
       * Movie Details routes use the TMDB identifier, matching the rest
       * of SofaWatch's Movie navigation.
       */
      expect(find.text('Movie 438631'), findsOneWidget);
    });
  });
}

Widget _buildTestApp({required HistoryRepository repository}) {
  final ViewingStateChangeNotifier viewingStateChangeNotifier =
      ViewingStateChangeNotifier();

  addTearDown(viewingStateChangeNotifier.dispose);
  final HistoryCubit cubit = HistoryCubit(
    viewingStateChangeNotifier: viewingStateChangeNotifier,
    repository: repository,
  )..load();

  return BlocProvider<HistoryCubit>.value(
    value: cubit,
    child: const MaterialApp(home: HistoryPage()),
  );
}

GoRouter _buildRouter({required HistoryRepository repository}) {
  final ViewingStateChangeNotifier viewingStateChangeNotifier =
      ViewingStateChangeNotifier();

  addTearDown(viewingStateChangeNotifier.dispose);
  final HistoryCubit cubit = HistoryCubit(
    viewingStateChangeNotifier: viewingStateChangeNotifier,
    repository: repository,
  )..load();

  return GoRouter(
    initialLocation: '/history-test',
    routes: <RouteBase>[
      GoRoute(
        path: '/history-test',
        builder: (BuildContext context, GoRouterState state) {
          return BlocProvider<HistoryCubit>.value(
            value: cubit,
            child: const HistoryPage(),
          );
        },
      ),
      GoRoute(
        name: AppRoute.episodeDetails.name,
        path: '/episodes/:episodeId',
        builder: (BuildContext context, GoRouterState state) {
          final String episodeId = state.pathParameters['episodeId']!;

          return Scaffold(
            key: const ValueKey<String>('test-episode-details'),
            body: Center(child: Text('Episode $episodeId')),
          );
        },
      ),
      GoRoute(
        name: AppRoute.movieDetails.name,
        path: '/movies/:movieId',
        builder: (BuildContext context, GoRouterState state) {
          final String movieId = state.pathParameters['movieId']!;

          return Scaffold(
            key: const ValueKey<String>('test-movie-details'),
            body: Center(child: Text('Movie $movieId')),
          );
        },
      ),
    ],
  );
}

final HistoryMovieItem _movieItem1 = HistoryMovieItem(
  eventId: 'movie-event-1',
  watchedAt: DateTime.utc(2026, 8, 19, 22),
  movieId: 'movie-1',
  movieTmdbId: 438631,
  movieTitle: 'Dune',
);

final HistoryEpisodeItem _episodeItem1 = HistoryEpisodeItem(
  eventId: 'episode-event-1',
  watchedAt: DateTime.utc(2026, 8, 19, 21),
  showId: 'show-1',
  showTmdbId: 95396,
  showTitle: 'Severance',
  episode: const HistoryEpisode(
    id: 'episode-1',
    tmdbId: 2101,
    seasonNumber: 1,
    episodeNumber: 1,
    title: 'Good News About Hell',
  ),
);

final HistoryMovieItem _movieItem2 = HistoryMovieItem(
  eventId: 'movie-event-2',
  watchedAt: DateTime.utc(2026, 8, 19, 20),
  movieId: 'movie-2',
  movieTmdbId: 329865,
  movieTitle: 'Arrival',
);

final HistoryEpisodeItem _episodeItem2 = HistoryEpisodeItem(
  eventId: 'episode-event-2',
  watchedAt: DateTime.utc(2026, 8, 19, 19),
  showId: 'show-2',
  showTmdbId: 70523,
  showTitle: 'Dark',
  episode: const HistoryEpisode(
    id: 'episode-2',
    tmdbId: 2202,
    seasonNumber: 1,
    episodeNumber: 2,
    title: 'Lies',
  ),
);

class _HistoryRepository implements HistoryRepository {
  _HistoryRepository({
    this.pages = const <String?, history_domain.HistoryPage>{},
    this.initialError,
  });

  final Map<String?, history_domain.HistoryPage> pages;
  final AppException? initialError;

  int calls = 0;

  @override
  Future<history_domain.HistoryPage> getHistory({
    int limit = 30,
    String? cursor,
  }) async {
    calls += 1;

    if (cursor == null && initialError != null) {
      throw initialError!;
    }

    return pages[cursor] ??
        const history_domain.HistoryPage(
          items: <HistoryItem>[],
          hasMore: false,
        );
  }

  @override
  Future<HistoryPreview> getPreview() {
    throw UnimplementedError(
      'History preview is not used by HistoryPage tests.',
    );
  }
}

final class _RetryHistoryRepository implements HistoryRepository {
  int calls = 0;

  @override
  Future<history_domain.HistoryPage> getHistory({
    int limit = 30,
    String? cursor,
  }) async {
    calls += 1;

    if (calls == 1) {
      throw const AppException.connection();
    }

    return history_domain.HistoryPage(
      items: <HistoryItem>[_movieItem1, _episodeItem1],
      hasMore: false,
    );
  }

  @override
  Future<HistoryPreview> getPreview() {
    throw UnimplementedError();
  }
}

final class _PaginationFailureHistoryRepository implements HistoryRepository {
  int calls = 0;
  int paginationCalls = 0;

  @override
  Future<history_domain.HistoryPage> getHistory({
    int limit = 30,
    String? cursor,
  }) async {
    calls += 1;

    if (cursor == null) {
      return history_domain.HistoryPage(
        items: <HistoryItem>[_movieItem1, _episodeItem1],
        nextCursor: 'cursor-1',
        hasMore: true,
      );
    }

    paginationCalls += 1;

    throw const AppException.connection();
  }

  @override
  Future<HistoryPreview> getPreview() {
    throw UnimplementedError();
  }
}
