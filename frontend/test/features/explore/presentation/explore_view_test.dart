import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/explore/application/cubit/explore_cubit.dart';
import 'package:sofawatch/features/explore/application/cubit/explore_state.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_collection.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_item.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_trending.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_trending_window.dart';
import 'package:sofawatch/features/explore/domain/repositories/explore_repository.dart';
import 'package:sofawatch/features/explore/presentation/views/explore_view.dart';

void main() {
  testWidgets('shows Trending Today, Trending This Week and Popular TV Shows', (
    WidgetTester tester,
  ) async {
    final ExploreCubit cubit = ExploreCubit(
      _FakeExploreRepository(
        results: <ExploreTrendingWindow, ExploreTrending>{
          ExploreTrendingWindow.day: ExploreTrending(
            items: const <ExploreMediaItem>[_movie],
          ),
          ExploreTrendingWindow.week: ExploreTrending(
            items: const <ExploreMediaItem>[_show],
          ),
        },
        popularShows: const ExploreMediaCollection(
          items: <ExploreMediaItem>[_popularShow],
        ),
      ),
    );

    await cubit.load();

    await tester.pumpWidget(_buildTestApp(cubit));

    await tester.pump();

    expect(find.text('Trending Today'), findsOneWidget);

    expect(find.text('Trending This Week'), findsOneWidget);

    expect(find.text('Popular TV Shows'), findsOneWidget);

    expect(find.text('Dune'), findsOneWidget);

    expect(find.text('Severance'), findsOneWidget);

    expect(find.text('Breaking Bad'), findsOneWidget);

    await cubit.close();
  });

  testWidgets('shows Week media filters', (WidgetTester tester) async {
    final ExploreCubit cubit = ExploreCubit(
      _FakeExploreRepository(
        results: <ExploreTrendingWindow, ExploreTrending>{
          ExploreTrendingWindow.day: ExploreTrending(
            items: const <ExploreMediaItem>[_movie],
          ),
          ExploreTrendingWindow.week: ExploreTrending(
            items: const <ExploreMediaItem>[_show, _movie],
          ),
        },
      ),
    );

    await cubit.load();

    await tester.pumpWidget(_buildTestApp(cubit));

    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('explore-week-filter-all')),
      findsOneWidget,
    );

    expect(
      find.byKey(const ValueKey<String>('explore-week-filter-shows')),
      findsOneWidget,
    );

    expect(
      find.byKey(const ValueKey<String>('explore-week-filter-movies')),
      findsOneWidget,
    );

    await cubit.close();
  });

  testWidgets(
    'filters Trending This Week locally without hiding other sections',
    (WidgetTester tester) async {
      final _FakeExploreRepository repository = _FakeExploreRepository(
        results: <ExploreTrendingWindow, ExploreTrending>{
          ExploreTrendingWindow.day: ExploreTrending(
            items: const <ExploreMediaItem>[_movie],
          ),
          ExploreTrendingWindow.week: ExploreTrending(
            items: const <ExploreMediaItem>[_show, _movie],
          ),
        },
        popularShows: const ExploreMediaCollection(
          items: <ExploreMediaItem>[_popularShow],
        ),
      );

      final ExploreCubit cubit = ExploreCubit(repository);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit));

      await tester.pump();

      expect(repository.trendingCalls, 2);

      expect(repository.popularShowsCalls, 1);

      await tester.tap(
        find.byKey(const ValueKey<String>('explore-week-filter-shows')),
      );

      await tester.pump();

      expect(cubit.state.weekFilter, ExploreWeekFilter.shows);

      expect(cubit.state.filteredWeekItems, hasLength(1));

      expect(
        cubit.state.filteredWeekItems.single.mediaType,
        ExploreMediaType.show,
      );

      expect(find.text('Trending Today'), findsOneWidget);

      expect(find.text('Popular TV Shows'), findsOneWidget);

      expect(repository.trendingCalls, 2);

      expect(repository.popularShowsCalls, 1);

      await cubit.close();
    },
  );

  testWidgets('shows skeleton while Explore is loading', (
    WidgetTester tester,
  ) async {
    final _PendingExploreRepository repository = _PendingExploreRepository();

    final ExploreCubit cubit = ExploreCubit(repository);

    final Future<void> loadFuture = cubit.load();

    await tester.pumpWidget(_buildTestApp(cubit));

    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('explore-trending-loading')),
      findsOneWidget,
    );

    repository.completeTrending(
      ExploreTrendingWindow.day,
      ExploreTrending(items: const <ExploreMediaItem>[]),
    );

    repository.completeTrending(
      ExploreTrendingWindow.week,
      ExploreTrending(items: const <ExploreMediaItem>[]),
    );

    repository.completePopularShows(
      const ExploreMediaCollection(items: <ExploreMediaItem>[]),
    );

    await loadFuture;
    await tester.pump();

    await cubit.close();
  });

  testWidgets('shows empty state when all Explore sections are empty', (
    WidgetTester tester,
  ) async {
    final ExploreCubit cubit = ExploreCubit(
      _FakeExploreRepository(
        results: <ExploreTrendingWindow, ExploreTrending>{
          ExploreTrendingWindow.day: ExploreTrending(
            items: const <ExploreMediaItem>[],
          ),
          ExploreTrendingWindow.week: ExploreTrending(
            items: const <ExploreMediaItem>[],
          ),
        },
      ),
    );

    await cubit.load();

    await tester.pumpWidget(_buildTestApp(cubit));

    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('explore-trending-empty')),
      findsOneWidget,
    );

    await cubit.close();
  });
}

Widget _buildTestApp(ExploreCubit cubit) {
  return MaterialApp(
    home: Scaffold(
      body: BlocProvider<ExploreCubit>.value(
        value: cubit,
        child: const ExploreView(),
      ),
    ),
  );
}

const ExploreMediaItem _show = ExploreMediaItem(
  mediaType: ExploreMediaType.show,
  tmdbId: 95396,
  title: 'Severance',
  originalTitle: 'Severance',
  originalLanguage: 'en',
  genreIds: <int>[18],
  popularity: 120,
  voteAverage: 8.4,
  voteCount: 2100,
);

const ExploreMediaItem _movie = ExploreMediaItem(
  mediaType: ExploreMediaType.movie,
  tmdbId: 438631,
  title: 'Dune',
  originalTitle: 'Dune',
  originalLanguage: 'en',
  genreIds: <int>[878],
  popularity: 95,
  voteAverage: 7.8,
  voteCount: 13000,
);

const ExploreMediaItem _popularShow = ExploreMediaItem(
  mediaType: ExploreMediaType.show,
  tmdbId: 1396,
  title: 'Breaking Bad',
  originalTitle: 'Breaking Bad',
  originalLanguage: 'en',
  genreIds: <int>[18],
  popularity: 100,
  voteAverage: 9.5,
  voteCount: 16000,
);

final class _FakeExploreRepository implements ExploreRepository {
  _FakeExploreRepository({
    required this.results,
    this.popularShows = const ExploreMediaCollection(
      items: <ExploreMediaItem>[],
    ),
  });

  final Map<ExploreTrendingWindow, ExploreTrending> results;

  final ExploreMediaCollection popularShows;

  int trendingCalls = 0;
  int popularShowsCalls = 0;

  @override
  Future<ExploreTrending> getTrending({
    required ExploreTrendingWindow window,
    String? language,
  }) async {
    trendingCalls++;

    return results[window] ??
        ExploreTrending(items: const <ExploreMediaItem>[]);
  }

  @override
  Future<ExploreMediaCollection> getPopularShows({String? language}) async {
    popularShowsCalls++;

    return popularShows;
  }
}

final class _PendingExploreRepository implements ExploreRepository {
  final Map<ExploreTrendingWindow, Completer<ExploreTrending>>
  _trendingCompleters = <ExploreTrendingWindow, Completer<ExploreTrending>>{
    ExploreTrendingWindow.day: Completer<ExploreTrending>(),
    ExploreTrendingWindow.week: Completer<ExploreTrending>(),
  };

  final Completer<ExploreMediaCollection> _popularShowsCompleter =
      Completer<ExploreMediaCollection>();

  @override
  Future<ExploreTrending> getTrending({
    required ExploreTrendingWindow window,
    String? language,
  }) {
    return _trendingCompleters[window]!.future;
  }

  @override
  Future<ExploreMediaCollection> getPopularShows({String? language}) {
    return _popularShowsCompleter.future;
  }

  void completeTrending(ExploreTrendingWindow window, ExploreTrending value) {
    _trendingCompleters[window]!.complete(value);
  }

  void completePopularShows(ExploreMediaCollection value) {
    _popularShowsCompleter.complete(value);
  }
}
