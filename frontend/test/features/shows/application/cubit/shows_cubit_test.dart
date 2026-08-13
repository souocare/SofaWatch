import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/shows/application/cubit/shows_cubit.dart';
import 'package:sofawatch/features/shows/application/cubit/shows_state.dart';
import 'package:sofawatch/features/shows/domain/models/library_show.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_episode.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_show.dart';
import 'package:sofawatch/features/shows/domain/repositories/shows_repository.dart';

void main() {
  group('ShowsCubit', () {
    test('starts with an empty Shows state', () {
      final ShowsCubit cubit = ShowsCubit(repository: _FakeShowsRepository());

      expect(cubit.state, const ShowsState());

      cubit.close();
    });

    test('loads Library and Watch Next', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        shows: <LibraryShow>[
          _libraryShow(
            tmdbId: 95396,
            title: 'Severance',
            status: LibraryStatus.watching,
          ),
        ],
        watchNext: <WatchNextShow>[_watchNextShow()],
      );

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      await cubit.load();

      expect(repository.libraryCalls, 1);
      expect(repository.watchNextCalls, 1);

      expect(cubit.state.libraryShows, repository.shows);

      expect(cubit.state.watchNext, repository.watchNext);

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.error, isNull);
      expect(cubit.state.watchNextError, isNull);

      await cubit.close();
    });

    test('supports an empty Library and empty Watch Next', () async {
      final ShowsCubit cubit = ShowsCubit(repository: _FakeShowsRepository());

      await cubit.load();

      expect(cubit.state.libraryShows, isEmpty);
      expect(cubit.state.watchNext, isEmpty);

      expect(cubit.state.isLibraryEmpty, isTrue);
      expect(cubit.state.isWatchNextEmpty, isTrue);

      await cubit.close();
    });

    test('does not load Watch Next when Library loading fails', () async {
      const AppException expectedError = AppException.connection();

      final _FakeShowsRepository repository = _FakeShowsRepository(
        libraryError: expectedError,
      );

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      await cubit.load();

      expect(repository.libraryCalls, 1);
      expect(repository.watchNextCalls, 0);

      expect(cubit.state.error, expectedError);
      expect(cubit.state.hasFatalError, isTrue);

      await cubit.close();
    });

    test('maps unexpected Library errors to unknown failure', () async {
      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(
          libraryUnexpectedError: StateError('boom'),
        ),
      );

      await cubit.load();

      expect(cubit.state.error?.type, AppExceptionType.unknown);

      await cubit.close();
    });

    test('preserves Library when Watch Next fails', () async {
      const AppException expectedError = AppException.connection();

      final _FakeShowsRepository repository = _FakeShowsRepository(
        shows: <LibraryShow>[
          _libraryShow(
            tmdbId: 95396,
            title: 'Severance',
            status: LibraryStatus.watching,
          ),
        ],
        watchNextError: expectedError,
      );

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      await cubit.load();

      expect(cubit.state.libraryShows, hasLength(1));

      expect(cubit.state.error, isNull);

      expect(cubit.state.watchNextError, expectedError);

      expect(cubit.state.watchNext, isEmpty);

      await cubit.close();
    });

    test(
      'maps unexpected Watch Next errors without failing the page',
      () async {
        final ShowsCubit cubit = ShowsCubit(
          repository: _FakeShowsRepository(
            shows: <LibraryShow>[
              _libraryShow(
                tmdbId: 95396,
                title: 'Severance',
                status: LibraryStatus.watching,
              ),
            ],
            watchNextUnexpectedError: StateError('boom'),
          ),
        );

        await cubit.load();

        expect(cubit.state.error, isNull);

        expect(cubit.state.watchNextError?.type, AppExceptionType.unknown);

        expect(cubit.state.libraryShows, hasLength(1));

        await cubit.close();
      },
    );

    test('retry reloads Library and Watch Next', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        shows: <LibraryShow>[
          _libraryShow(
            tmdbId: 95396,
            title: 'Severance',
            status: LibraryStatus.watching,
          ),
        ],
        watchNext: <WatchNextShow>[_watchNextShow()],
      );

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      await cubit.load();

      expect(repository.libraryCalls, 1);
      expect(repository.watchNextCalls, 1);

      await cubit.retry();

      expect(repository.libraryCalls, 2);
      expect(repository.watchNextCalls, 2);

      await cubit.close();
    });

    test('retryWatchNext reloads only Watch Next', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        shows: <LibraryShow>[
          _libraryShow(
            tmdbId: 95396,
            title: 'Severance',
            status: LibraryStatus.watching,
          ),
        ],
        watchNext: <WatchNextShow>[_watchNextShow()],
      );

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      await cubit.load();

      expect(repository.libraryCalls, 1);
      expect(repository.watchNextCalls, 1);

      await cubit.retryWatchNext();

      expect(repository.libraryCalls, 1);
      expect(repository.watchNextCalls, 2);

      await cubit.close();
    });
  });
}

LibraryShow _libraryShow({
  required int tmdbId,
  required String title,
  required LibraryStatus status,
}) {
  return LibraryShow(
    libraryEntryId: 'library-$tmdbId',
    showId: 'show-$tmdbId',
    tmdbId: tmdbId,
    title: title,
    originalTitle: title,
    status: status,
    showStatus: 'Returning Series',
    voteAverage: 8.0,
    createdAt: DateTime.utc(2026, 8, 1),
    updatedAt: DateTime.utc(2026, 8, 10),
  );
}

WatchNextShow _watchNextShow() {
  return WatchNextShow(
    libraryEntryId: 'library-95396',
    libraryStatus: LibraryStatus.watching,
    showId: 'show-95396',
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
}

final class _FakeShowsRepository implements ShowsRepository {
  _FakeShowsRepository({
    this.shows = const <LibraryShow>[],
    this.watchNext = const <WatchNextShow>[],
    this.libraryError,
    this.libraryUnexpectedError,
    this.watchNextError,
    this.watchNextUnexpectedError,
  });

  final List<LibraryShow> shows;
  final List<WatchNextShow> watchNext;

  final AppException? libraryError;
  final Object? libraryUnexpectedError;

  final AppException? watchNextError;
  final Object? watchNextUnexpectedError;

  int libraryCalls = 0;
  int watchNextCalls = 0;

  @override
  Future<List<LibraryShow>> getLibraryShows() async {
    libraryCalls++;

    final AppException? appError = libraryError;

    if (appError != null) {
      throw appError;
    }

    final Object? unknownError = libraryUnexpectedError;

    if (unknownError != null) {
      throw unknownError;
    }

    return shows;
  }

  @override
  Future<List<WatchNextShow>> getWatchNext() async {
    watchNextCalls++;

    final AppException? appError = watchNextError;

    if (appError != null) {
      throw appError;
    }

    final Object? unknownError = watchNextUnexpectedError;

    if (unknownError != null) {
      throw unknownError;
    }

    return watchNext;
  }
}
