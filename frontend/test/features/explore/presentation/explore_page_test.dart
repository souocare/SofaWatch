import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/explore/application/cubit/explore_cubit.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_genre.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_genre_options.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_collection.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_item.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_trending.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_trending_window.dart';
import 'package:sofawatch/features/explore/domain/repositories/explore_repository.dart';
import 'package:sofawatch/features/explore/presentation/views/explore_view.dart';

void main() {
  group('ExploreView', () {
    testWidgets('shows the Explore discovery header', (
      WidgetTester tester,
    ) async {
      final ExploreCubit cubit = await _createLoadedCubit();

      await tester.pumpWidget(_buildTestApp(cubit));
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('explore-page-title')),
        findsOneWidget,
      );

      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('Discover something worth watching.'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('provides a scrollable discovery content area', (
      WidgetTester tester,
    ) async {
      final ExploreCubit cubit = await _createLoadedCubit();

      await tester.pumpWidget(_buildTestApp(cubit));
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('explore-scroll-view')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('explore-trending-content')),
        findsOneWidget,
      );

      await cubit.close();
    });

    testWidgets('does not expose a local Search field', (
      WidgetTester tester,
    ) async {
      final ExploreCubit cubit = await _createLoadedCubit();

      await tester.pumpWidget(_buildTestApp(cubit));
      await tester.pump();

      expect(find.byType(TextField), findsNothing);

      await cubit.close();
    });

    testWidgets('shows all current Explore discovery sections', (
      WidgetTester tester,
    ) async {
      final ExploreCubit cubit = await _createLoadedCubit();

      await tester.pumpWidget(_buildTestApp(cubit));
      await tester.pump();

      expect(find.text('Trending Today'), findsOneWidget);
      expect(find.text('Trending This Week'), findsOneWidget);
      expect(find.text('Popular TV Shows'), findsOneWidget);
      expect(find.text('Popular Movies'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('shows discovery media from each section', (
      WidgetTester tester,
    ) async {
      final ExploreCubit cubit = await _createLoadedCubit();

      await tester.pumpWidget(_buildTestApp(cubit));
      await tester.pump();

      expect(find.text('Dune'), findsOneWidget);
      expect(find.text('Severance'), findsOneWidget);
      expect(find.text('Breaking Bad'), findsOneWidget);
      expect(find.text('Interstellar'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('shows genre filters for Popular sections', (
      WidgetTester tester,
    ) async {
      final ExploreCubit cubit = await _createLoadedCubit();

      await tester.pumpWidget(_buildTestApp(cubit));
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('explore-popular-shows-genre-all')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('explore-popular-shows-genre-18')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('explore-popular-movies-genre-all')),
        findsOneWidget,
      );

      expect(
        find.byKey(const ValueKey<String>('explore-popular-movies-genre-878')),
        findsOneWidget,
      );

      await cubit.close();
    });
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

Future<ExploreCubit> _createLoadedCubit() async {
  final ExploreCubit cubit = ExploreCubit(_FakeExploreRepository());

  await cubit.load();

  return cubit;
}

final class _FakeExploreRepository implements ExploreRepository {
  @override
  Future<ExploreTrending> getTrending({
    required ExploreTrendingWindow window,
    String? language,
  }) async {
    return switch (window) {
      ExploreTrendingWindow.day => ExploreTrending(
        items: const <ExploreMediaItem>[
          ExploreMediaItem(
            mediaType: ExploreMediaType.movie,
            tmdbId: 438631,
            title: 'Dune',
            originalTitle: 'Dune',
            originalLanguage: 'en',
            genreIds: <int>[878],
            popularity: 95,
            voteAverage: 7.8,
            voteCount: 13000,
          ),
        ],
      ),
      ExploreTrendingWindow.week => ExploreTrending(
        items: const <ExploreMediaItem>[
          ExploreMediaItem(
            mediaType: ExploreMediaType.show,
            tmdbId: 95396,
            title: 'Severance',
            originalTitle: 'Severance',
            originalLanguage: 'en',
            genreIds: <int>[18],
            popularity: 120,
            voteAverage: 8.4,
            voteCount: 2100,
          ),
        ],
      ),
    };
  }

  @override
  Future<ExploreGenreOptions> getGenres({String? language}) async {
    return const ExploreGenreOptions(
      shows: <ExploreGenre>[
        ExploreGenre(id: 18, name: 'Drama'),
        ExploreGenre(id: 35, name: 'Comedy'),
      ],
      movies: <ExploreGenre>[
        ExploreGenre(id: 878, name: 'Science Fiction'),
        ExploreGenre(id: 12, name: 'Adventure'),
      ],
    );
  }

  @override
  Future<ExploreMediaCollection> getPopularShows({
    int? genreId,
    String? language,
  }) async {
    return const ExploreMediaCollection(
      items: <ExploreMediaItem>[
        ExploreMediaItem(
          mediaType: ExploreMediaType.show,
          tmdbId: 1396,
          title: 'Breaking Bad',
          originalTitle: 'Breaking Bad',
          originalLanguage: 'en',
          genreIds: <int>[18],
          popularity: 100,
          voteAverage: 9.5,
          voteCount: 16000,
        ),
      ],
    );
  }

  @override
  Future<ExploreMediaCollection> getPopularMovies({
    int? genreId,
    String? language,
  }) async {
    return const ExploreMediaCollection(
      items: <ExploreMediaItem>[
        ExploreMediaItem(
          mediaType: ExploreMediaType.movie,
          tmdbId: 157336,
          title: 'Interstellar',
          originalTitle: 'Interstellar',
          originalLanguage: 'en',
          genreIds: <int>[12, 18, 878],
          popularity: 110,
          voteAverage: 8.5,
          voteCount: 36000,
        ),
      ],
    );
  }
}
