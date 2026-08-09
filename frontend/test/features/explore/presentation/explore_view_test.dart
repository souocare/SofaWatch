import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/explore/application/cubit/explore_cubit.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_item.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_trending.dart';
import 'package:sofawatch/features/explore/domain/repositories/explore_repository.dart';
import 'package:sofawatch/features/explore/presentation/views/explore_view.dart';
import 'dart:async';

void main() {
  testWidgets('shows Trending Shows and Trending Movies', (
    WidgetTester tester,
  ) async {
    final ExploreCubit cubit = ExploreCubit(
      _FakeExploreRepository(
        ExploreTrending(
          shows: const <ExploreMediaItem>[_show],
          movies: const <ExploreMediaItem>[_movie],
        ),
      ),
    );

    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<ExploreCubit>.value(
            value: cubit,
            child: const ExploreView(),
          ),
        ),
      ),
    );

    expect(find.text('Trending Shows'), findsOneWidget);

    expect(find.text('Trending Movies'), findsOneWidget);

    expect(find.text('Severance'), findsOneWidget);
    expect(find.text('Dune'), findsOneWidget);

    await cubit.close();
  });

  testWidgets('shows skeleton while trending is loading', (
    WidgetTester tester,
  ) async {
    final _PendingExploreRepository repository = _PendingExploreRepository();

    final ExploreCubit cubit = ExploreCubit(repository);

    cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<ExploreCubit>.value(
            value: cubit,
            child: const ExploreView(),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('explore-trending-loading')),
      findsOneWidget,
    );

    repository.completer.complete(
      ExploreTrending(
        shows: const <ExploreMediaItem>[],
        movies: const <ExploreMediaItem>[],
      ),
    );

    await tester.pump();
    await cubit.close();
  });
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
  _FakeExploreRepository(this.result);

  final ExploreTrending result;

  @override
  Future<ExploreTrending> getTrending({String? language}) async {
    return result;
  }
}

final class _PendingExploreRepository implements ExploreRepository {
  final Completer<ExploreTrending> completer = Completer<ExploreTrending>();

  @override
  Future<ExploreTrending> getTrending({String? language}) {
    return completer.future;
  }
}
