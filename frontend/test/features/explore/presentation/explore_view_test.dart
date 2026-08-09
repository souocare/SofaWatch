import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/explore/application/cubit/explore_cubit.dart';
import 'package:sofawatch/features/explore/application/cubit/explore_state.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_item.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_trending.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_trending_window.dart';
import 'package:sofawatch/features/explore/domain/repositories/explore_repository.dart';
import 'package:sofawatch/features/explore/presentation/views/explore_view.dart';

void main() {
  testWidgets('shows Trending Today and Trending This Week', (
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
      ),
    );

    await cubit.load();

    await tester.pumpWidget(_buildTestApp(cubit));

    await tester.pump();

    expect(find.text('Trending Today'), findsOneWidget);

    expect(find.text('Trending This Week'), findsOneWidget);

    expect(find.text('Dune'), findsOneWidget);

    expect(find.text('Severance'), findsOneWidget);

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
    'filters Trending This Week locally without hiding Trending Today',
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
      );

      final ExploreCubit cubit = ExploreCubit(repository);

      await cubit.load();

      await tester.pumpWidget(_buildTestApp(cubit));

      await tester.pump();

      expect(repository.calls, 2);

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

      expect(repository.calls, 2);

      await cubit.close();
    },
  );

  testWidgets('shows skeleton while trending is loading', (
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

    repository.complete(
      ExploreTrendingWindow.day,
      ExploreTrending(items: const <ExploreMediaItem>[]),
    );

    repository.complete(
      ExploreTrendingWindow.week,
      ExploreTrending(items: const <ExploreMediaItem>[]),
    );

    await loadFuture;
    await tester.pump();

    await cubit.close();
  });

  testWidgets('shows empty state when both trending sections are empty', (
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

final class _FakeExploreRepository implements ExploreRepository {
  _FakeExploreRepository({required this.results});

  final Map<ExploreTrendingWindow, ExploreTrending> results;

  int calls = 0;

  @override
  Future<ExploreTrending> getTrending({
    required ExploreTrendingWindow window,
    String? language,
  }) async {
    calls++;

    return results[window] ??
        ExploreTrending(items: const <ExploreMediaItem>[]);
  }
}

final class _PendingExploreRepository implements ExploreRepository {
  final Map<ExploreTrendingWindow, Completer<ExploreTrending>> _completers =
      <ExploreTrendingWindow, Completer<ExploreTrending>>{
        ExploreTrendingWindow.day: Completer<ExploreTrending>(),
        ExploreTrendingWindow.week: Completer<ExploreTrending>(),
      };

  @override
  Future<ExploreTrending> getTrending({
    required ExploreTrendingWindow window,
    String? language,
  }) {
    return _completers[window]!.future;
  }

  void complete(ExploreTrendingWindow window, ExploreTrending value) {
    _completers[window]!.complete(value);
  }
}
