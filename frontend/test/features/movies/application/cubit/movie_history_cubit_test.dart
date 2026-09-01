import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/core/viewing/viewing_state_change_notifier.dart';
import 'package:sofawatch/features/history/domain/models/history_media_type.dart';
import 'package:sofawatch/features/history/domain/models/history_movie_item.dart';
import 'package:sofawatch/features/history/domain/models/history_page.dart';
import 'package:sofawatch/features/history/domain/models/history_preview.dart';
import 'package:sofawatch/features/history/domain/repositories/history_repository.dart';
import 'package:sofawatch/features/movies/application/cubit/movie_history_cubit.dart';
import 'package:sofawatch/features/movies/domain/repositories/movie_viewing_repository.dart';

void main() {
  group('MovieHistoryCubit', () {
    late ViewingStateChangeNotifier viewingStateChangeNotifier;

    setUp(() {
      viewingStateChangeNotifier = ViewingStateChangeNotifier();
    });

    tearDown(() async {
      await viewingStateChangeNotifier.dispose();
    });

    test('starts with an empty state', () async {
      final MovieHistoryCubit cubit = MovieHistoryCubit(
        historyRepository: _FakeHistoryRepository(),
        viewingRepository: _FakeMovieViewingRepository(),
        viewingStateChangeNotifier: viewingStateChangeNotifier,
      );

      expect(cubit.state.items, isEmpty);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.error, isNull);
      expect(cubit.state.mutationError, isNull);
      expect(cubit.state.mutatingMovieIds, isEmpty);
      expect(cubit.state.mutatingEventIds, isEmpty);

      await cubit.close();
    });

    test('loads Movie history with the 18-event preview limit', () async {
      final List<HistoryMovieItem> items = List<HistoryMovieItem>.generate(
        18,
        (int index) => _movieHistoryItem(index),
      );

      final _FakeHistoryRepository repository = _FakeHistoryRepository(
        page: HistoryPage(items: items, hasMore: true, nextCursor: 'next-page'),
      );

      final MovieHistoryCubit cubit = MovieHistoryCubit(
        historyRepository: repository,
        viewingRepository: _FakeMovieViewingRepository(),
        viewingStateChangeNotifier: viewingStateChangeNotifier,
      );

      await cubit.load();

      expect(repository.historyCalls, 1);
      expect(repository.lastLimit, MovieHistoryCubit.previewLimit);
      expect(repository.lastMediaType, HistoryMediaType.movies);

      expect(cubit.state.items, items);
      expect(cubit.state.items, hasLength(18));
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.error, isNull);

      await cubit.close();
    });

    test('keeps at most 18 Movie events defensively', () async {
      final List<HistoryMovieItem> items = List<HistoryMovieItem>.generate(
        25,
        (int index) => _movieHistoryItem(index),
      );

      final MovieHistoryCubit cubit = MovieHistoryCubit(
        historyRepository: _FakeHistoryRepository(
          page: HistoryPage(items: items, hasMore: false),
        ),
        viewingRepository: _FakeMovieViewingRepository(),
        viewingStateChangeNotifier: viewingStateChangeNotifier,
      );

      await cubit.load();

      expect(cubit.state.items, hasLength(18));
      expect(cubit.state.items.first.eventId, 'event-0');
      expect(cubit.state.items.last.eventId, 'event-17');

      await cubit.close();
    });

    test('preserves independent events for the same Movie', () async {
      final HistoryMovieItem firstViewing = HistoryMovieItem(
        eventId: 'event-first',
        watchedAt: DateTime.utc(2026, 8, 30, 20),
        movieId: 'movie-1',
        movieTmdbId: 438631,
        movieTitle: 'Dune',
      );

      final HistoryMovieItem secondViewing = HistoryMovieItem(
        eventId: 'event-second',
        watchedAt: DateTime.utc(2026, 8, 31, 22),
        movieId: 'movie-1',
        movieTmdbId: 438631,
        movieTitle: 'Dune',
      );

      final MovieHistoryCubit cubit = MovieHistoryCubit(
        historyRepository: _FakeHistoryRepository(
          page: HistoryPage(
            items: <HistoryMovieItem>[secondViewing, firstViewing],
            hasMore: false,
          ),
        ),
        viewingRepository: _FakeMovieViewingRepository(),
        viewingStateChangeNotifier: viewingStateChangeNotifier,
      );

      await cubit.load();

      expect(cubit.state.items, hasLength(2));

      expect(
        cubit.state.items.map((HistoryMovieItem item) => item.movieId),
        <String>['movie-1', 'movie-1'],
      );

      expect(
        cubit.state.items.map((HistoryMovieItem item) => item.eventId),
        <String>['event-second', 'event-first'],
      );

      await cubit.close();
    });

    test('preserves loaded items when a refresh fails', () async {
      final _MutableHistoryRepository repository = _MutableHistoryRepository(
        page: HistoryPage(
          items: <HistoryMovieItem>[_movieHistoryItem(1)],
          hasMore: false,
        ),
      );

      final MovieHistoryCubit cubit = MovieHistoryCubit(
        historyRepository: repository,
        viewingRepository: _FakeMovieViewingRepository(),
        viewingStateChangeNotifier: viewingStateChangeNotifier,
      );

      await cubit.load();

      expect(cubit.state.items, hasLength(1));

      repository.error = const AppException.connection();

      await cubit.load();

      expect(cubit.state.items, hasLength(1));
      expect(cubit.state.error, isA<AppException>());
      expect(cubit.state.isLoading, isFalse);

      await cubit.close();
    });

    test(
      'recordWatch records a viewing and invalidates viewing state',
      () async {
        final _FakeHistoryRepository historyRepository = _FakeHistoryRepository(
          page: const HistoryPage(items: <HistoryMovieItem>[], hasMore: false),
        );

        final _FakeMovieViewingRepository viewingRepository =
            _FakeMovieViewingRepository();

        final MovieHistoryCubit cubit = MovieHistoryCubit(
          historyRepository: historyRepository,
          viewingRepository: viewingRepository,
          viewingStateChangeNotifier: viewingStateChangeNotifier,
        );

        await cubit.load();

        expect(historyRepository.historyCalls, 1);

        await cubit.recordWatch('movie-1');

        /*
       * notifyChanged() is synchronous, but the listener intentionally starts
       * load() without awaiting it.
       */
        await _flushAsyncWork();

        expect(viewingRepository.recordedMovieIds, <String>['movie-1']);

        /*
       * One initial load + one notifier-driven reload.
       */
        expect(historyRepository.historyCalls, 2);

        expect(cubit.state.isMovieMutating('movie-1'), isFalse);
        expect(cubit.state.mutationError, isNull);

        await cubit.close();
      },
    );

    test(
      'deleteWatchEvent deletes exactly one event and invalidates state',
      () async {
        final _FakeHistoryRepository historyRepository = _FakeHistoryRepository(
          page: HistoryPage(
            items: <HistoryMovieItem>[_movieHistoryItem(1)],
            hasMore: false,
          ),
        );

        final _FakeMovieViewingRepository viewingRepository =
            _FakeMovieViewingRepository();

        final MovieHistoryCubit cubit = MovieHistoryCubit(
          historyRepository: historyRepository,
          viewingRepository: viewingRepository,
          viewingStateChangeNotifier: viewingStateChangeNotifier,
        );

        await cubit.load();

        await cubit.deleteWatchEvent(movieId: 'movie-1', eventId: 'event-1');

        await _flushAsyncWork();

        expect(viewingRepository.deletedEvents, <_DeletedWatchEvent>[
          const _DeletedWatchEvent(movieId: 'movie-1', eventId: 'event-1'),
        ]);

        expect(historyRepository.historyCalls, 2);
        expect(cubit.state.isEventMutating('event-1'), isFalse);
        expect(cubit.state.mutationError, isNull);

        await cubit.close();
      },
    );

    test(
      'prevents duplicate recordWatch submissions for the same Movie',
      () async {
        final _ControlledMovieViewingRepository viewingRepository =
            _ControlledMovieViewingRepository();

        final MovieHistoryCubit cubit = MovieHistoryCubit(
          historyRepository: _FakeHistoryRepository(),
          viewingRepository: viewingRepository,
          viewingStateChangeNotifier: viewingStateChangeNotifier,
        );

        final Future<void> first = cubit.recordWatch('movie-1');

        await viewingRepository.recordRequested.future;

        expect(cubit.state.isMovieMutating('movie-1'), isTrue);

        final Future<void> second = cubit.recordWatch('movie-1');

        expect(viewingRepository.recordCalls, 1);

        viewingRepository.completeRecord();

        await Future.wait(<Future<void>>[first, second]);
        await _flushAsyncWork();

        expect(viewingRepository.recordCalls, 1);
        expect(cubit.state.isMovieMutating('movie-1'), isFalse);

        await cubit.close();
      },
    );

    test('prevents duplicate deletion of the same event', () async {
      final _ControlledMovieViewingRepository viewingRepository =
          _ControlledMovieViewingRepository();

      final MovieHistoryCubit cubit = MovieHistoryCubit(
        historyRepository: _FakeHistoryRepository(),
        viewingRepository: viewingRepository,
        viewingStateChangeNotifier: viewingStateChangeNotifier,
      );

      final Future<void> first = cubit.deleteWatchEvent(
        movieId: 'movie-1',
        eventId: 'event-1',
      );

      await viewingRepository.deleteRequested.future;

      expect(cubit.state.isEventMutating('event-1'), isTrue);

      final Future<void> second = cubit.deleteWatchEvent(
        movieId: 'movie-1',
        eventId: 'event-1',
      );

      expect(viewingRepository.deleteCalls, 1);

      viewingRepository.completeDelete();

      await Future.wait(<Future<void>>[first, second]);
      await _flushAsyncWork();

      expect(viewingRepository.deleteCalls, 1);
      expect(cubit.state.isEventMutating('event-1'), isFalse);

      await cubit.close();
    });

    test('mutation failure keeps History items visible', () async {
      final HistoryMovieItem item = _movieHistoryItem(1);

      final MovieHistoryCubit cubit = MovieHistoryCubit(
        historyRepository: _FakeHistoryRepository(
          page: HistoryPage(items: <HistoryMovieItem>[item], hasMore: false),
        ),
        viewingRepository: _FakeMovieViewingRepository(
          recordError: const AppException.connection(),
        ),
        viewingStateChangeNotifier: viewingStateChangeNotifier,
      );

      await cubit.load();

      await cubit.recordWatch('movie-1');

      expect(cubit.state.items, <HistoryMovieItem>[item]);
      expect(cubit.state.mutationError, isA<AppException>());
      expect(cubit.state.isMovieMutating('movie-1'), isFalse);

      await cubit.close();
    });

    test('clearMutationError clears only the mutation failure', () async {
      final MovieHistoryCubit cubit = MovieHistoryCubit(
        historyRepository: _FakeHistoryRepository(),
        viewingRepository: _FakeMovieViewingRepository(
          recordError: const AppException.connection(),
        ),
        viewingStateChangeNotifier: viewingStateChangeNotifier,
      );

      await cubit.recordWatch('movie-1');

      expect(cubit.state.mutationError, isNotNull);

      cubit.clearMutationError();

      expect(cubit.state.mutationError, isNull);

      await cubit.close();
    });
  });
}

Future<void> _flushAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

HistoryMovieItem _movieHistoryItem(int index) {
  return HistoryMovieItem(
    eventId: 'event-$index',
    watchedAt: DateTime.utc(
      2026,
      8,
      31,
      22,
      30,
    ).subtract(Duration(hours: index)),
    movieId: 'movie-$index',
    movieTmdbId: 100000 + index,
    movieTitle: 'Movie $index',
    posterUrl: '/api/v1/images/movies/movie-$index/poster',
  );
}

class _FakeHistoryRepository implements HistoryRepository {
  _FakeHistoryRepository({
    this.page = const HistoryPage(items: <HistoryMovieItem>[], hasMore: false),
  });

  final HistoryPage page;

  int historyCalls = 0;
  int? lastLimit;
  HistoryMediaType? lastMediaType;

  @override
  Future<HistoryPage> getHistory({
    int limit = 30,
    String? cursor,
    HistoryMediaType mediaType = HistoryMediaType.all,
  }) async {
    historyCalls++;
    lastLimit = limit;
    lastMediaType = mediaType;

    return page;
  }

  @override
  Future<HistoryPreview> getPreview() {
    throw UnimplementedError();
  }
}

final class _MutableHistoryRepository implements HistoryRepository {
  _MutableHistoryRepository({required this.page});

  HistoryPage page;
  AppException? error;

  @override
  Future<HistoryPage> getHistory({
    int limit = 30,
    String? cursor,
    HistoryMediaType mediaType = HistoryMediaType.all,
  }) async {
    final AppException? currentError = error;

    if (currentError != null) {
      throw currentError;
    }

    return page;
  }

  @override
  Future<HistoryPreview> getPreview() {
    throw UnimplementedError();
  }
}

class _FakeMovieViewingRepository implements MovieViewingRepository {
  _FakeMovieViewingRepository({this.recordError});

  final AppException? recordError;

  final List<String> recordedMovieIds = <String>[];
  final List<_DeletedWatchEvent> deletedEvents = <_DeletedWatchEvent>[];

  @override
  Future<void> recordWatch(String movieId) async {
    final AppException? currentError = recordError;

    if (currentError != null) {
      throw currentError;
    }

    recordedMovieIds.add(movieId);
  }

  @override
  Future<void> deleteWatchEvent({
    required String movieId,
    required String eventId,
  }) async {
    deletedEvents.add(_DeletedWatchEvent(movieId: movieId, eventId: eventId));
  }
}

final class _ControlledMovieViewingRepository
    implements MovieViewingRepository {
  int recordCalls = 0;
  int deleteCalls = 0;

  final Completer<void> recordRequested = Completer<void>();
  final Completer<void> deleteRequested = Completer<void>();

  final Completer<void> _recordResult = Completer<void>();
  final Completer<void> _deleteResult = Completer<void>();

  void completeRecord() {
    if (!_recordResult.isCompleted) {
      _recordResult.complete();
    }
  }

  void completeDelete() {
    if (!_deleteResult.isCompleted) {
      _deleteResult.complete();
    }
  }

  @override
  Future<void> recordWatch(String movieId) {
    recordCalls++;

    if (!recordRequested.isCompleted) {
      recordRequested.complete();
    }

    return _recordResult.future;
  }

  @override
  Future<void> deleteWatchEvent({
    required String movieId,
    required String eventId,
  }) {
    deleteCalls++;

    if (!deleteRequested.isCompleted) {
      deleteRequested.complete();
    }

    return _deleteResult.future;
  }
}

final class _DeletedWatchEvent {
  const _DeletedWatchEvent({required this.movieId, required this.eventId});

  final String movieId;
  final String eventId;

  @override
  bool operator ==(Object other) {
    return other is _DeletedWatchEvent &&
        other.movieId == movieId &&
        other.eventId == eventId;
  }

  @override
  int get hashCode => Object.hash(movieId, eventId);
}
