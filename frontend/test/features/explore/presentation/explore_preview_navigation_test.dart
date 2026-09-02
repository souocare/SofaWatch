import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sofawatch/app/router/app_routes.dart';
import 'package:sofawatch/features/explore/application/cubit/explore_cubit.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_genre.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_genre_options.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_collection.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_item.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_trending.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_trending_window.dart';
import 'package:sofawatch/features/explore/domain/repositories/explore_repository.dart';
import 'package:sofawatch/features/explore/presentation/views/explore_view.dart';
import 'package:sofawatch/features/library/application/cubit/library_cubit.dart';
import 'package:sofawatch/features/library/domain/models/imported_library_media.dart';
import 'package:sofawatch/features/library/domain/models/library_entry.dart';
import 'package:sofawatch/features/library/domain/models/library_media_type.dart';
import 'package:sofawatch/features/library/domain/models/library_preview.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/library/domain/repositories/library_repository.dart';

void main() {
  group('Explore preview navigation', () {
    testWidgets(
      'opens Show preview and preserves Explore state after closing',
      (WidgetTester tester) async {
        final _FakeExploreRepository exploreRepository =
            _FakeExploreRepository();

        final ExploreCubit exploreCubit = ExploreCubit(exploreRepository);

        final LibraryCubit libraryCubit = LibraryCubit(
          _FakeLibraryRepository(),
        );

        await exploreCubit.load();
        await exploreCubit.changeShowGenre(18);

        expect(exploreCubit.state.selectedShowGenreId, 18);

        expect(exploreCubit.state.selectedMovieGenreId, isNull);

        final int loadCallsBeforeNavigation = exploreRepository.totalCalls;

        final GoRouter router = _createRouter(
          exploreCubit: exploreCubit,
          libraryCubit: libraryCubit,
        );

        await tester.pumpWidget(_buildTestApp(router: router));

        await tester.pumpAndSettle();

        final Finder showCard = find.byKey(
          const ValueKey<String>('explore-media-open-show-1396'),
        );

        expect(showCard, findsOneWidget);

        await tester.ensureVisible(showCard);

        await tester.tap(showCard);

        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('test-show-preview')),
          findsOneWidget,
        );

        expect(find.text('Show 1396'), findsOneWidget);

        expect(
          find.byKey(const ValueKey<String>('test-show-preview-close')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const ValueKey<String>('test-show-preview-close')),
        );

        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('test-show-preview')),
          findsNothing,
        );

        expect(
          find.byKey(const ValueKey<String>('explore-scroll-view')),
          findsOneWidget,
        );

        expect(exploreCubit.state.selectedShowGenreId, 18);

        expect(exploreCubit.state.selectedMovieGenreId, isNull);

        expect(exploreRepository.totalCalls, loadCallsBeforeNavigation);

        await exploreCubit.close();
        await libraryCubit.close();

        router.dispose();
      },
    );

    testWidgets(
      'opens Movie preview and preserves Explore state after closing',
      (WidgetTester tester) async {
        final _FakeExploreRepository exploreRepository =
            _FakeExploreRepository();

        final ExploreCubit exploreCubit = ExploreCubit(exploreRepository);

        final LibraryCubit libraryCubit = LibraryCubit(
          _FakeLibraryRepository(),
        );

        await exploreCubit.load();
        await exploreCubit.changeMovieGenre(878);

        expect(exploreCubit.state.selectedMovieGenreId, 878);

        expect(exploreCubit.state.selectedShowGenreId, isNull);

        final int loadCallsBeforeNavigation = exploreRepository.totalCalls;

        final GoRouter router = _createRouter(
          exploreCubit: exploreCubit,
          libraryCubit: libraryCubit,
        );

        await tester.pumpWidget(_buildTestApp(router: router));

        await tester.pumpAndSettle();

        final Finder movieCard = find.byKey(
          const ValueKey<String>('explore-media-open-movie-157336'),
        );

        expect(movieCard, findsOneWidget);

        await tester.ensureVisible(movieCard);

        await tester.tap(movieCard);

        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('test-movie-preview')),
          findsOneWidget,
        );

        expect(find.text('Movie 157336'), findsOneWidget);

        expect(
          find.byKey(const ValueKey<String>('test-movie-preview-close')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const ValueKey<String>('test-movie-preview-close')),
        );

        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('test-movie-preview')),
          findsNothing,
        );

        expect(
          find.byKey(const ValueKey<String>('explore-scroll-view')),
          findsOneWidget,
        );

        expect(exploreCubit.state.selectedMovieGenreId, 878);

        expect(exploreCubit.state.selectedShowGenreId, isNull);

        expect(exploreRepository.totalCalls, loadCallsBeforeNavigation);

        await exploreCubit.close();
        await libraryCubit.close();

        router.dispose();
      },
    );
  });
}

Widget _buildTestApp({required GoRouter router}) {
  return MaterialApp.router(routerConfig: router);
}

GoRouter _createRouter({
  required ExploreCubit exploreCubit,
  required LibraryCubit libraryCubit,
}) {
  return GoRouter(
    initialLocation: '/explore',
    routes: <RouteBase>[
      GoRoute(
        name: AppRoute.explore.name,
        path: '/explore',
        builder: (BuildContext context, GoRouterState state) {
          return MultiBlocProvider(
            providers: <BlocProvider<dynamic>>[
              BlocProvider<ExploreCubit>.value(value: exploreCubit),
              BlocProvider<LibraryCubit>.value(value: libraryCubit),
            ],
            child: const Scaffold(body: ExploreView()),
          );
        },
      ),
      GoRoute(
        name: AppRoute.showDetails.name,
        path: '/shows/:showId',
        builder: (BuildContext context, GoRouterState state) {
          final String showId = state.pathParameters['showId']!;

          return Scaffold(
            key: const ValueKey<String>('test-show-preview'),
            appBar: AppBar(
              leading: IconButton(
                key: const ValueKey<String>('test-show-preview-close'),
                onPressed: () {
                  context.pop();
                },
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            body: Center(child: Text('Show $showId')),
          );
        },
      ),
      GoRoute(
        name: AppRoute.tmdbMovieDetails.name,
        path: '/movies/tmdb/:tmdbId',
        builder: (BuildContext context, GoRouterState state) {
          final String tmdbId = state.pathParameters['tmdbId']!;

          return Scaffold(
            key: const ValueKey<String>('test-movie-preview'),
            appBar: AppBar(
              leading: IconButton(
                key: const ValueKey<String>('test-movie-preview-close'),
                onPressed: () {
                  context.pop();
                },
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            body: Center(child: Text('Movie $tmdbId')),
          );
        },
      ),
    ],
  );
}

final class _FakeExploreRepository implements ExploreRepository {
  int trendingCalls = 0;
  int genreCalls = 0;
  int popularShowsCalls = 0;
  int popularMoviesCalls = 0;

  int get totalCalls =>
      trendingCalls + genreCalls + popularShowsCalls + popularMoviesCalls;

  @override
  Future<ExploreTrending> getTrending({
    required ExploreTrendingWindow window,
    String? language,
  }) async {
    trendingCalls++;

    return switch (window) {
      ExploreTrendingWindow.day => ExploreTrending(
        items: const <ExploreMediaItem>[_trendingMovie],
      ),
      ExploreTrendingWindow.week => ExploreTrending(
        items: const <ExploreMediaItem>[_trendingShow],
      ),
    };
  }

  @override
  Future<ExploreGenreOptions> getGenres({String? language}) async {
    genreCalls++;

    return const ExploreGenreOptions(
      shows: <ExploreGenre>[ExploreGenre(id: 18, name: 'Drama')],
      movies: <ExploreGenre>[ExploreGenre(id: 878, name: 'Science Fiction')],
    );
  }

  @override
  Future<ExploreMediaCollection> getPopularShows({
    int? genreId,
    String? language,
  }) async {
    popularShowsCalls++;

    return const ExploreMediaCollection(
      items: <ExploreMediaItem>[_popularShow],
    );
  }

  @override
  Future<ExploreMediaCollection> getPopularMovies({
    int? genreId,
    String? language,
  }) async {
    popularMoviesCalls++;

    return const ExploreMediaCollection(
      items: <ExploreMediaItem>[_popularMovie],
    );
  }
}

final class _FakeLibraryRepository implements LibraryRepository {
  @override
  Future<ImportedLibraryMedia> importShowByTmdbId(int tmdbId) async {
    return ImportedLibraryMedia(
      id: 'show-$tmdbId',
      tmdbId: tmdbId,
      mediaType: LibraryMediaType.show,
    );
  }

  @override
  Future<LibraryEntry?> getMovieEntry(String movieId) async {
    return null;
  }

  @override
  Future<LibraryEntry?> getShowEntry(String showId) async {
    return null;
  }

  @override
  Future<LibraryEntry> updateMovieStatus(
    String movieId,
    LibraryStatus status,
  ) async {
    return LibraryEntry(
      id: 'entry-uuid',
      mediaId: movieId,
      mediaType: LibraryMediaType.movie,
      status: status,
      createdAt: DateTime.utc(2026, 8, 10),
      updatedAt: DateTime.utc(2026, 8, 10),
    );
  }

  @override
  Future<ImportedLibraryMedia> importMovieByTmdbId(int tmdbId) async {
    return ImportedLibraryMedia(
      id: 'movie-$tmdbId',
      tmdbId: tmdbId,
      mediaType: LibraryMediaType.movie,
    );
  }

  @override
  Future<LibraryEntry> addShow(String showId) async {
    return _entry(mediaId: showId, mediaType: LibraryMediaType.show);
  }

  @override
  Future<LibraryEntry> addMovie(String movieId) async {
    return _entry(mediaId: movieId, mediaType: LibraryMediaType.movie);
  }

  @override
  Future<void> removeShow(String showId) async {}

  @override
  Future<void> removeMovie(String movieId) async {}

  @override
  Future<LibraryEntry> updateShowStatus(
    String showId,
    LibraryStatus status,
  ) async {
    return _entry(
      mediaId: showId,
      mediaType: LibraryMediaType.show,
      status: status,
    );
  }

  LibraryEntry _entry({
    required String mediaId,
    required LibraryMediaType mediaType,
    LibraryStatus status = LibraryStatus.planning,
  }) {
    final DateTime now = DateTime.utc(2026, 8, 9);

    return LibraryEntry(
      id: 'library-entry',
      mediaId: mediaId,
      mediaType: mediaType,
      status: status,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<LibraryPreview> getPreview() {
    throw UnimplementedError();
  }
}

const ExploreMediaItem _trendingMovie = ExploreMediaItem(
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

const ExploreMediaItem _trendingShow = ExploreMediaItem(
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

const ExploreMediaItem _popularMovie = ExploreMediaItem(
  mediaType: ExploreMediaType.movie,
  tmdbId: 157336,
  title: 'Interstellar',
  originalTitle: 'Interstellar',
  originalLanguage: 'en',
  genreIds: <int>[12, 18, 878],
  popularity: 110,
  voteAverage: 8.5,
  voteCount: 36000,
);
