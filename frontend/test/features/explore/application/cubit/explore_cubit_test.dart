import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/explore/application/cubit/explore_cubit.dart';
import 'package:sofawatch/features/explore/application/cubit/explore_state.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_item.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_trending.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_trending_window.dart';
import 'package:sofawatch/features/explore/domain/repositories/explore_repository.dart';

void main() {
  test('loads daily and weekly trending content successfully', () async {
    final _FakeExploreRepository repository = _FakeExploreRepository(
      results: <ExploreTrendingWindow, ExploreTrending>{
        ExploreTrendingWindow.day: ExploreTrending(
          items: const <ExploreMediaItem>[_movie, _show],
        ),
        ExploreTrendingWindow.week: ExploreTrending(
          items: const <ExploreMediaItem>[_show, _movie],
        ),
      },
    );

    final ExploreCubit cubit = ExploreCubit(repository);

    final Future<void> loadFuture = cubit.load();

    expect(cubit.state.today.isLoading, isTrue);
    expect(cubit.state.week.isLoading, isTrue);

    await loadFuture;

    expect(cubit.state.today.isSuccess, isTrue);
    expect(cubit.state.week.isSuccess, isTrue);

    expect(cubit.state.today.data?.items, hasLength(2));

    expect(cubit.state.week.data?.items, hasLength(2));

    expect(repository.requestedWindows, <ExploreTrendingWindow>[
      ExploreTrendingWindow.day,
      ExploreTrendingWindow.week,
    ]);

    await cubit.close();
  });

  test('emits failure when repository fails', () async {
    final _FakeExploreRepository repository = _FakeExploreRepository(
      error: const AppException.connection(),
    );

    final ExploreCubit cubit = ExploreCubit(repository);

    await cubit.load();

    expect(cubit.state.today.isFailure, isTrue);
    expect(cubit.state.week.isFailure, isTrue);

    expect(cubit.state.today.error?.type, AppExceptionType.connection);

    expect(cubit.state.week.error?.type, AppExceptionType.connection);

    await cubit.close();
  });

  test('retry loads Today and Week again', () async {
    final _FakeExploreRepository repository = _FakeExploreRepository(
      results: <ExploreTrendingWindow, ExploreTrending>{
        ExploreTrendingWindow.day: ExploreTrending(
          items: const <ExploreMediaItem>[_movie],
        ),
        ExploreTrendingWindow.week: ExploreTrending(
          items: const <ExploreMediaItem>[_show],
        ),
      },
    );

    final ExploreCubit cubit = ExploreCubit(repository);

    await cubit.load();
    await cubit.retry();

    expect(repository.calls, 4);

    expect(repository.requestedWindows, <ExploreTrendingWindow>[
      ExploreTrendingWindow.day,
      ExploreTrendingWindow.week,
      ExploreTrendingWindow.day,
      ExploreTrendingWindow.week,
    ]);

    await cubit.close();
  });

  test('filters weekly trending media locally', () async {
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

    expect(cubit.state.filteredWeekItems, hasLength(2));

    cubit.changeWeekFilter(ExploreWeekFilter.shows);

    expect(cubit.state.filteredWeekItems, hasLength(1));

    expect(
      cubit.state.filteredWeekItems.single.mediaType,
      ExploreMediaType.show,
    );

    cubit.changeWeekFilter(ExploreWeekFilter.movies);

    expect(cubit.state.filteredWeekItems, hasLength(1));

    expect(
      cubit.state.filteredWeekItems.single.mediaType,
      ExploreMediaType.movie,
    );

    cubit.changeWeekFilter(ExploreWeekFilter.all);

    expect(cubit.state.filteredWeekItems, hasLength(2));

    await cubit.close();
  });

  test('changing Week filter does not repeat remote requests', () async {
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

    expect(repository.calls, 2);

    cubit.changeWeekFilter(ExploreWeekFilter.shows);

    cubit.changeWeekFilter(ExploreWeekFilter.movies);

    cubit.changeWeekFilter(ExploreWeekFilter.all);

    expect(repository.calls, 2);

    expect(repository.requestedWindows, <ExploreTrendingWindow>[
      ExploreTrendingWindow.day,
      ExploreTrendingWindow.week,
    ]);

    await cubit.close();
  });

  test('does not emit when selecting the active Week filter', () async {
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

    expect(cubit.state.weekFilter, ExploreWeekFilter.all);

    final ExploreState previousState = cubit.state;

    cubit.changeWeekFilter(ExploreWeekFilter.all);

    expect(cubit.state, same(previousState));

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
  _FakeExploreRepository({
    this.results = const <ExploreTrendingWindow, ExploreTrending>{},
    this.error,
  });

  final Map<ExploreTrendingWindow, ExploreTrending> results;
  final AppException? error;

  final List<ExploreTrendingWindow> requestedWindows =
      <ExploreTrendingWindow>[];

  int calls = 0;

  @override
  Future<ExploreTrending> getTrending({
    required ExploreTrendingWindow window,
    String? language,
  }) async {
    calls++;
    requestedWindows.add(window);

    final AppException? currentError = error;

    if (currentError != null) {
      throw currentError;
    }

    return results[window] ??
        ExploreTrending(items: const <ExploreMediaItem>[]);
  }
}
