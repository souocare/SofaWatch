import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/explore/application/cubit/explore_cubit.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_item.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_trending.dart';
import 'package:sofawatch/features/explore/domain/repositories/explore_repository.dart';

void main() {
  test('loads trending content successfully', () async {
    final _FakeExploreRepository repository = _FakeExploreRepository(
      result: ExploreTrending(
        shows: const <ExploreMediaItem>[_show],
        movies: const <ExploreMediaItem>[_movie],
      ),
    );

    final ExploreCubit cubit = ExploreCubit(repository);

    final Future<void> loadFuture = cubit.load();

    expect(cubit.state.trending.isLoading, isTrue);

    await loadFuture;

    expect(cubit.state.trending.isSuccess, isTrue);
    expect(cubit.state.trending.data?.shows, hasLength(1));
    expect(cubit.state.trending.data?.movies, hasLength(1));

    await cubit.close();
  });

  test('emits failure when repository fails', () async {
    final _FakeExploreRepository repository = _FakeExploreRepository(
      error: const AppException.connection(),
    );

    final ExploreCubit cubit = ExploreCubit(repository);

    await cubit.load();

    expect(cubit.state.trending.isFailure, isTrue);

    expect(cubit.state.trending.error?.type, AppExceptionType.connection);

    await cubit.close();
  });

  test('retry loads trending again', () async {
    final _FakeExploreRepository repository = _FakeExploreRepository(
      result: ExploreTrending(
        shows: const <ExploreMediaItem>[_show],
        movies: const <ExploreMediaItem>[],
      ),
    );

    final ExploreCubit cubit = ExploreCubit(repository);

    await cubit.load();
    await cubit.retry();

    expect(repository.calls, 2);

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
  _FakeExploreRepository({this.result, this.error});

  final ExploreTrending? result;
  final AppException? error;

  int calls = 0;

  @override
  Future<ExploreTrending> getTrending({String? language}) async {
    calls++;

    final AppException? currentError = error;

    if (currentError != null) {
      throw currentError;
    }

    return result ??
        ExploreTrending(
          shows: const <ExploreMediaItem>[],
          movies: const <ExploreMediaItem>[],
        );
  }
}
