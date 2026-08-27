import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/core/viewing/viewing_state_change_notifier.dart';
import 'package:sofawatch/features/history/application/cubit/history_preview_cubit.dart';
import 'package:sofawatch/features/history/application/cubit/history_preview_state.dart';
import 'package:sofawatch/features/history/domain/models/history_episode.dart';
import 'package:sofawatch/features/history/domain/models/history_episode_item.dart';
import 'package:sofawatch/features/history/domain/models/history_movie_item.dart';
import 'package:sofawatch/features/history/domain/models/history_page.dart';
import 'package:sofawatch/features/history/domain/models/history_preview.dart';
import 'package:sofawatch/features/history/domain/repositories/history_repository.dart';

void main() {
  late ViewingStateChangeNotifier viewingStateChangeNotifier;

  setUp(() {
    viewingStateChangeNotifier = ViewingStateChangeNotifier();
  });

  tearDown(() async {
    await viewingStateChangeNotifier.dispose();
  });
  group('HistoryPreviewCubit', () {
    test('starts in initial state', () {
      final HistoryPreviewCubit cubit = HistoryPreviewCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: const _HistoryRepository(),
      );

      addTearDown(cubit.close);

      expect(cubit.state, const HistoryPreviewInitial());
    });

    test('loads History preview successfully', () async {
      final HistoryPreviewCubit cubit = HistoryPreviewCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: _HistoryRepository(preview: _preview),
      );

      addTearDown(cubit.close);

      final Future<void> expectation = expectLater(
        cubit.stream,
        emitsInOrder(<HistoryPreviewState>[
          const HistoryPreviewLoading(),
          HistoryPreviewSuccess(_preview),
        ]),
      );

      await cubit.load();
      await expectation;

      expect(cubit.state, HistoryPreviewSuccess(_preview));
    });

    test('maps AppException failure', () async {
      const AppException error = AppException.connection();

      final HistoryPreviewCubit cubit = HistoryPreviewCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: const _HistoryRepository(error: error),
      );

      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state, const HistoryPreviewFailure(error));
    });

    test('maps unexpected failure to unknown', () async {
      final HistoryPreviewCubit cubit = HistoryPreviewCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: const _UnexpectedHistoryRepository(),
      );

      addTearDown(cubit.close);

      await cubit.load();

      final HistoryPreviewState state = cubit.state;

      expect(state, isA<HistoryPreviewFailure>());

      final HistoryPreviewFailure failure = state as HistoryPreviewFailure;

      expect(failure.error.type, AppExceptionType.unknown);
    });

    test('does not start another load while already loading', () async {
      final _ControlledHistoryRepository repository =
          _ControlledHistoryRepository();

      final HistoryPreviewCubit cubit = HistoryPreviewCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
      );

      addTearDown(cubit.close);

      final Future<void> firstLoad = cubit.load();

      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, const HistoryPreviewLoading());
      expect(repository.previewCalls, 1);

      await cubit.load();

      expect(repository.previewCalls, 1);

      repository.completePreview(_preview);

      await firstLoad;

      expect(cubit.state, HistoryPreviewSuccess(_preview));
    });

    test('retry performs a new preview request', () async {
      final _RetryHistoryRepository repository = _RetryHistoryRepository();

      final HistoryPreviewCubit cubit = HistoryPreviewCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
      );

      addTearDown(cubit.close);

      await cubit.load();

      expect(repository.previewCalls, 1);

      expect(cubit.state, isA<HistoryPreviewFailure>());

      await cubit.retry();

      expect(repository.previewCalls, 2);

      expect(cubit.state, HistoryPreviewSuccess(_preview));
    });

    test('supports an empty History preview', () async {
      const HistoryPreview emptyPreview = HistoryPreview(
        episodes: <HistoryEpisodeItem>[],
        movies: <HistoryMovieItem>[],
      );

      final HistoryPreviewCubit cubit = HistoryPreviewCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: const _HistoryRepository(preview: emptyPreview),
      );

      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state, const HistoryPreviewSuccess(emptyPreview));

      final HistoryPreviewSuccess state = cubit.state as HistoryPreviewSuccess;

      expect(state.preview.isEmpty, isTrue);
    });
    test('reloads History preview after viewing state changes', () async {
      final _RetryHistoryRepository repository = _RetryHistoryRepository();

      final HistoryPreviewCubit cubit = HistoryPreviewCubit(
        repository: repository,
        viewingStateChangeNotifier: viewingStateChangeNotifier,
      );

      addTearDown(cubit.close);

      expect(repository.previewCalls, 0);

      viewingStateChangeNotifier.notifyChanged();

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(repository.previewCalls, 1);
    });
  });
}

final HistoryEpisodeItem _episodeItem = HistoryEpisodeItem(
  eventId: 'episode-event-1',
  watchedAt: DateTime.utc(2026, 8, 19, 20),
  showId: 'show-1',
  showTmdbId: 95396,
  showTitle: 'Severance',
  episode: const HistoryEpisode(
    id: 'episode-1',
    tmdbId: 2101,
    seasonNumber: 1,
    episodeNumber: 1,
    title: 'Good News About Hell',
  ),
);

final HistoryMovieItem _movieItem = HistoryMovieItem(
  eventId: 'movie-event-1',
  watchedAt: DateTime.utc(2026, 8, 19, 19),
  movieId: 'movie-1',
  movieTmdbId: 438631,
  movieTitle: 'Dune',
);

final HistoryPreview _preview = HistoryPreview(
  episodes: <HistoryEpisodeItem>[_episodeItem],
  movies: <HistoryMovieItem>[_movieItem],
);

class _HistoryRepository implements HistoryRepository {
  const _HistoryRepository({this.preview, this.error});

  final HistoryPreview? preview;
  final AppException? error;

  @override
  Future<HistoryPreview> getPreview() async {
    final AppException? failure = error;

    if (failure != null) {
      throw failure;
    }

    return preview ??
        const HistoryPreview(
          episodes: <HistoryEpisodeItem>[],
          movies: <HistoryMovieItem>[],
        );
  }

  @override
  Future<HistoryPage> getHistory({int limit = 30, String? cursor}) {
    throw UnimplementedError();
  }
}

final class _UnexpectedHistoryRepository extends _HistoryRepository {
  const _UnexpectedHistoryRepository();

  @override
  Future<HistoryPreview> getPreview() {
    throw StateError('Unexpected History preview failure.');
  }
}

final class _ControlledHistoryRepository implements HistoryRepository {
  final Completer<HistoryPreview> _previewResult = Completer<HistoryPreview>();

  int previewCalls = 0;

  void completePreview(HistoryPreview preview) {
    if (_previewResult.isCompleted) {
      return;
    }

    _previewResult.complete(preview);
  }

  @override
  Future<HistoryPreview> getPreview() {
    previewCalls += 1;

    return _previewResult.future;
  }

  @override
  Future<HistoryPage> getHistory({int limit = 30, String? cursor}) {
    throw UnimplementedError();
  }
}

final class _RetryHistoryRepository implements HistoryRepository {
  int previewCalls = 0;

  @override
  Future<HistoryPreview> getPreview() async {
    previewCalls += 1;

    if (previewCalls == 1) {
      throw const AppException.connection();
    }

    return _preview;
  }

  @override
  Future<HistoryPage> getHistory({int limit = 30, String? cursor}) {
    throw UnimplementedError();
  }
}
