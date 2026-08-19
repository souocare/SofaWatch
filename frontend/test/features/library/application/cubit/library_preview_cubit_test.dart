import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/library/application/cubit/library_preview_cubit.dart';
import 'package:sofawatch/features/library/application/cubit/library_preview_state.dart';
import 'package:sofawatch/features/library/domain/models/imported_library_media.dart';
import 'package:sofawatch/features/library/domain/models/library_entry.dart';
import 'package:sofawatch/features/library/domain/models/library_preview.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';
import 'package:sofawatch/features/library/domain/repositories/library_repository.dart';

void main() {
  group('LibraryPreviewCubit', () {
    test('starts in Initial', () {
      final LibraryPreviewCubit cubit = LibraryPreviewCubit(
        repository: const _LibraryPreviewRepository(),
      );

      addTearDown(cubit.close);

      expect(cubit.state, const LibraryPreviewInitial());
    });

    test('loads Library preview successfully', () async {
      final LibraryPreviewCubit cubit = LibraryPreviewCubit(
        repository: const _LibraryPreviewRepository(),
      );

      addTearDown(cubit.close);

      final Future<List<LibraryPreviewState>> states = cubit.stream
          .take(2)
          .toList();

      await cubit.load();

      expect(await states, <LibraryPreviewState>[
        const LibraryPreviewLoading(),
        const LibraryPreviewSuccess(_preview),
      ]);
    });

    test('maps AppException failure', () async {
      final LibraryPreviewCubit cubit = LibraryPreviewCubit(
        repository: const _FailingLibraryPreviewRepository(),
      );

      addTearDown(cubit.close);

      await cubit.load();

      expect(
        cubit.state,
        isA<LibraryPreviewFailure>().having(
          (LibraryPreviewFailure state) => state.error.type,
          'error.type',
          AppExceptionType.connection,
        ),
      );
    });

    test('maps unexpected failure to unknown', () async {
      final LibraryPreviewCubit cubit = LibraryPreviewCubit(
        repository: const _UnexpectedLibraryPreviewRepository(),
      );

      addTearDown(cubit.close);

      await cubit.load();

      expect(
        cubit.state,
        isA<LibraryPreviewFailure>().having(
          (LibraryPreviewFailure state) => state.error.type,
          'error.type',
          AppExceptionType.unknown,
        ),
      );
    });

    test('ignores another load while loading', () async {
      final _ControlledLibraryPreviewRepository repository =
          _ControlledLibraryPreviewRepository();

      final LibraryPreviewCubit cubit = LibraryPreviewCubit(
        repository: repository,
      );

      addTearDown(cubit.close);

      final Future<void> firstLoad = cubit.load();

      await Future<void>.delayed(Duration.zero);

      expect(repository.calls, 1);

      await cubit.load();

      expect(repository.calls, 1);

      repository.complete(_preview);

      await firstLoad;

      expect(cubit.state, const LibraryPreviewSuccess(_preview));
    });

    test('retry loads Library preview again', () async {
      final _RetryLibraryPreviewRepository repository =
          _RetryLibraryPreviewRepository();

      final LibraryPreviewCubit cubit = LibraryPreviewCubit(
        repository: repository,
      );

      addTearDown(cubit.close);

      await cubit.load();

      expect(repository.calls, 1);
      expect(cubit.state, isA<LibraryPreviewFailure>());

      await cubit.retry();

      expect(repository.calls, 2);

      expect(cubit.state, const LibraryPreviewSuccess(_preview));
    });
  });
}

const LibraryPreview _preview = LibraryPreview(
  shows: <LibraryPreviewShow>[
    LibraryPreviewShow(
      id: 'show-id',
      tmdbId: 95396,
      title: 'Severance',
      posterUrl: null,
    ),
  ],
  movies: <LibraryPreviewMovie>[
    LibraryPreviewMovie(
      id: 'movie-id',
      tmdbId: 438631,
      title: 'Dune',
      posterUrl: null,
    ),
  ],
);

final class _LibraryPreviewRepository implements LibraryRepository {
  const _LibraryPreviewRepository();

  @override
  Future<LibraryPreview> getPreview() async {
    return _preview;
  }

  @override
  Future<ImportedLibraryMedia> importShowByTmdbId(int tmdbId) {
    throw UnimplementedError();
  }

  @override
  Future<ImportedLibraryMedia> importMovieByTmdbId(int tmdbId) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryEntry?> getShowEntry(String showId) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryEntry?> getMovieEntry(String movieId) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryEntry> addShow(String showId) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryEntry> addMovie(String movieId) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeShow(String showId) {
    throw UnimplementedError();
  }

  @override
  Future<void> removeMovie(String movieId) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryEntry> updateShowStatus(String showId, LibraryStatus status) {
    throw UnimplementedError();
  }

  @override
  Future<LibraryEntry> updateMovieStatus(String movieId, LibraryStatus status) {
    throw UnimplementedError();
  }
}

final class _FailingLibraryPreviewRepository implements LibraryRepository {
  const _FailingLibraryPreviewRepository();

  @override
  Future<LibraryPreview> getPreview() {
    throw const AppException.connection();
  }

  @override
  Future<ImportedLibraryMedia> importShowByTmdbId(int tmdbId) =>
      throw UnimplementedError();

  @override
  Future<ImportedLibraryMedia> importMovieByTmdbId(int tmdbId) =>
      throw UnimplementedError();

  @override
  Future<LibraryEntry?> getShowEntry(String showId) =>
      throw UnimplementedError();

  @override
  Future<LibraryEntry?> getMovieEntry(String movieId) =>
      throw UnimplementedError();

  @override
  Future<LibraryEntry> addShow(String showId) => throw UnimplementedError();

  @override
  Future<LibraryEntry> addMovie(String movieId) => throw UnimplementedError();

  @override
  Future<void> removeShow(String showId) => throw UnimplementedError();

  @override
  Future<void> removeMovie(String movieId) => throw UnimplementedError();

  @override
  Future<LibraryEntry> updateShowStatus(String showId, LibraryStatus status) =>
      throw UnimplementedError();

  @override
  Future<LibraryEntry> updateMovieStatus(
    String movieId,
    LibraryStatus status,
  ) => throw UnimplementedError();
}

final class _UnexpectedLibraryPreviewRepository implements LibraryRepository {
  const _UnexpectedLibraryPreviewRepository();

  @override
  Future<LibraryPreview> getPreview() {
    throw StateError('Unexpected Library preview failure.');
  }

  @override
  Future<ImportedLibraryMedia> importShowByTmdbId(int tmdbId) =>
      throw UnimplementedError();

  @override
  Future<ImportedLibraryMedia> importMovieByTmdbId(int tmdbId) =>
      throw UnimplementedError();

  @override
  Future<LibraryEntry?> getShowEntry(String showId) =>
      throw UnimplementedError();

  @override
  Future<LibraryEntry?> getMovieEntry(String movieId) =>
      throw UnimplementedError();

  @override
  Future<LibraryEntry> addShow(String showId) => throw UnimplementedError();

  @override
  Future<LibraryEntry> addMovie(String movieId) => throw UnimplementedError();

  @override
  Future<void> removeShow(String showId) => throw UnimplementedError();

  @override
  Future<void> removeMovie(String movieId) => throw UnimplementedError();

  @override
  Future<LibraryEntry> updateShowStatus(String showId, LibraryStatus status) =>
      throw UnimplementedError();

  @override
  Future<LibraryEntry> updateMovieStatus(
    String movieId,
    LibraryStatus status,
  ) => throw UnimplementedError();
}

final class _ControlledLibraryPreviewRepository implements LibraryRepository {
  final Completer<LibraryPreview> _result = Completer<LibraryPreview>();

  int calls = 0;

  void complete(LibraryPreview preview) {
    _result.complete(preview);
  }

  @override
  Future<LibraryPreview> getPreview() {
    calls += 1;

    return _result.future;
  }

  @override
  Future<ImportedLibraryMedia> importShowByTmdbId(int tmdbId) =>
      throw UnimplementedError();

  @override
  Future<ImportedLibraryMedia> importMovieByTmdbId(int tmdbId) =>
      throw UnimplementedError();

  @override
  Future<LibraryEntry?> getShowEntry(String showId) =>
      throw UnimplementedError();

  @override
  Future<LibraryEntry?> getMovieEntry(String movieId) =>
      throw UnimplementedError();

  @override
  Future<LibraryEntry> addShow(String showId) => throw UnimplementedError();

  @override
  Future<LibraryEntry> addMovie(String movieId) => throw UnimplementedError();

  @override
  Future<void> removeShow(String showId) => throw UnimplementedError();

  @override
  Future<void> removeMovie(String movieId) => throw UnimplementedError();

  @override
  Future<LibraryEntry> updateShowStatus(String showId, LibraryStatus status) =>
      throw UnimplementedError();

  @override
  Future<LibraryEntry> updateMovieStatus(
    String movieId,
    LibraryStatus status,
  ) => throw UnimplementedError();
}

final class _RetryLibraryPreviewRepository implements LibraryRepository {
  int calls = 0;

  @override
  Future<LibraryPreview> getPreview() async {
    calls += 1;

    if (calls == 1) {
      throw const AppException.connection();
    }

    return _preview;
  }

  @override
  Future<ImportedLibraryMedia> importShowByTmdbId(int tmdbId) =>
      throw UnimplementedError();

  @override
  Future<ImportedLibraryMedia> importMovieByTmdbId(int tmdbId) =>
      throw UnimplementedError();

  @override
  Future<LibraryEntry?> getShowEntry(String showId) =>
      throw UnimplementedError();

  @override
  Future<LibraryEntry?> getMovieEntry(String movieId) =>
      throw UnimplementedError();

  @override
  Future<LibraryEntry> addShow(String showId) => throw UnimplementedError();

  @override
  Future<LibraryEntry> addMovie(String movieId) => throw UnimplementedError();

  @override
  Future<void> removeShow(String showId) => throw UnimplementedError();

  @override
  Future<void> removeMovie(String movieId) => throw UnimplementedError();

  @override
  Future<LibraryEntry> updateShowStatus(String showId, LibraryStatus status) =>
      throw UnimplementedError();

  @override
  Future<LibraryEntry> updateMovieStatus(
    String movieId,
    LibraryStatus status,
  ) => throw UnimplementedError();
}
