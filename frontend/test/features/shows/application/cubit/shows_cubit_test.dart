import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/shows/application/cubit/shows_cubit.dart';
import 'package:sofawatch/features/shows/application/cubit/shows_state.dart';
import 'package:sofawatch/features/shows/domain/models/library_show.dart';
import 'package:sofawatch/features/shows/domain/repositories/shows_repository.dart';

void main() {
  group('ShowsCubit', () {
    test('starts in initial state', () {
      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(shows: const <LibraryShow>[]),
      );

      expect(cubit.state, const ShowsInitial());

      cubit.close();
    });

    test('loads Shows from the Library', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        shows: <LibraryShow>[
          _libraryShow(
            tmdbId: 95396,
            title: 'Severance',
            status: LibraryStatus.watching,
          ),
          _libraryShow(
            tmdbId: 1396,
            title: 'Breaking Bad',
            status: LibraryStatus.completed,
          ),
        ],
      );

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      final List<ShowsState> emittedStates = <ShowsState>[];

      final subscription = cubit.stream.listen(emittedStates.add);

      await cubit.load();
      await Future<void>.delayed(Duration.zero);

      expect(repository.calls, 1);

      expect(emittedStates, <ShowsState>[
        const ShowsLoading(),
        ShowsSuccess(repository.shows),
      ]);

      expect((cubit.state as ShowsSuccess).shows, hasLength(2));

      await subscription.cancel();
      await cubit.close();
    });

    test('supports an empty Library', () async {
      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(shows: const <LibraryShow>[]),
      );

      await cubit.load();

      final ShowsSuccess state = cubit.state as ShowsSuccess;

      expect(state.shows, isEmpty);
      expect(state.isEmpty, isTrue);

      await cubit.close();
    });

    test('emits failure when repository throws AppException', () async {
      const AppException expectedError = AppException.connection();

      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(error: expectedError),
      );

      await cubit.load();

      expect(cubit.state, const ShowsFailure(expectedError));

      await cubit.close();
    });

    test('maps unexpected errors to unknown failure', () async {
      final ShowsCubit cubit = ShowsCubit(
        repository: _FakeShowsRepository(unexpectedError: StateError('boom')),
      );

      await cubit.load();

      final ShowsFailure state = cubit.state as ShowsFailure;

      expect(state.error.type, AppExceptionType.unknown);

      await cubit.close();
    });

    test('retry loads the Library again', () async {
      final _FakeShowsRepository repository = _FakeShowsRepository(
        shows: <LibraryShow>[
          _libraryShow(
            tmdbId: 95396,
            title: 'Severance',
            status: LibraryStatus.watching,
          ),
        ],
      );

      final ShowsCubit cubit = ShowsCubit(repository: repository);

      await cubit.load();

      expect(repository.calls, 1);

      await cubit.retry();

      expect(repository.calls, 2);

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

final class _FakeShowsRepository implements ShowsRepository {
  _FakeShowsRepository({
    this.shows = const <LibraryShow>[],
    this.error,
    this.unexpectedError,
  });

  final List<LibraryShow> shows;
  final AppException? error;
  final Object? unexpectedError;

  int calls = 0;

  @override
  Future<List<LibraryShow>> getLibraryShows() async {
    calls++;

    final AppException? appError = error;

    if (appError != null) {
      throw appError;
    }

    final Object? unknownError = unexpectedError;

    if (unknownError != null) {
      throw unknownError;
    }

    return shows;
  }
}
