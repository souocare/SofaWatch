import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/shows/application/cubit/shows_cubit.dart';
import 'package:sofawatch/features/shows/domain/models/library_show.dart';
import 'package:sofawatch/features/shows/domain/repositories/shows_repository.dart';
import 'package:sofawatch/features/shows/presentation/pages/shows_page.dart';

void main() {
  group('ShowsPage', () {
    testWidgets('shows Watch List and Upcoming tabs', (
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
        repository: _FakeShowsRepository(shows: <LibraryShow>[_show]),
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
        find.byKey(const ValueKey<String>('shows-item-95396')),
        findsOneWidget,
      );

      expect(find.text('Severance'), findsOneWidget);
    });

    testWidgets('switches from Watch List to Upcoming', (
      WidgetTester tester,
    ) async {
      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(shows: <LibraryShow>[_show]),
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
        repository: _FakeShowsRepository(shows: <LibraryShow>[_show]),
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

      expect(find.text('Severance'), findsOneWidget);
    });

    testWidgets('shows Watch List empty state when Library has no Shows', (
      WidgetTester tester,
    ) async {
      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(shows: const <LibraryShow>[]),
      );

      addTearDown(cubit.close);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit: cubit));

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('shows-watch-list-empty')),
        findsOneWidget,
      );

      expect(find.text('Nothing to watch yet'), findsOneWidget);
    });

    testWidgets('preserves selected tab while Details is pushed and popped', (
      WidgetTester tester,
    ) async {
      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(shows: <LibraryShow>[_show]),
      );

      addTearDown(cubit.close);

      await cubit.load();

      final GoRouter router = _buildRouter(cubit: cubit);

      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      await tester.pumpAndSettle();

      // Select Upcoming before leaving Shows.
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

      /*
       * Simulate opening Details while Shows remains underneath in
       * the navigation stack.
       *
       * Upcoming does not contain real Episode/Show cards yet, so
       * navigation is triggered directly through the router here.
       */
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

    testWidgets('opens Show Details from Watch List', (
      WidgetTester tester,
    ) async {
      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(shows: <LibraryShow>[_show]),
      );

      addTearDown(cubit.close);

      await cubit.load();

      final GoRouter router = _buildRouter(cubit: cubit);

      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('shows-item-95396')));

      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('fake-show-details')),
        findsOneWidget,
      );

      expect(find.text('Show 95396'), findsOneWidget);
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

final class _FakeShowsRepository implements ShowsRepository {
  const _FakeShowsRepository({required this.shows});

  final List<LibraryShow> shows;

  @override
  Future<List<LibraryShow>> getLibraryShows() async {
    return shows;
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
}
