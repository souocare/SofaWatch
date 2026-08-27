import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/core/viewing/viewing_state_change_notifier.dart';
import 'package:sofawatch/features/history/application/cubit/history_cubit.dart';
import 'package:sofawatch/features/history/application/cubit/history_state.dart';
import 'package:sofawatch/features/history/domain/models/history_episode.dart';
import 'package:sofawatch/features/history/domain/models/history_episode_item.dart';
import 'package:sofawatch/features/history/domain/models/history_item.dart';
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
  group('HistoryCubit', () {
    test('starts empty and idle', () {
      final HistoryCubit cubit = HistoryCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: _HistoryRepository(),
      );

      addTearDown(cubit.close);

      expect(cubit.state.items, isEmpty);
      expect(cubit.state.nextCursor, isNull);
      expect(cubit.state.hasMore, isFalse);
      expect(cubit.state.hasLoaded, isFalse);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.isLoadingMore, isFalse);
      expect(cubit.state.error, isNull);
      expect(cubit.state.paginationError, isNull);
    });

    test('loads the first History page', () async {
      final _HistoryRepository repository = _HistoryRepository(
        pages: <String?, HistoryPage>{
          null: HistoryPage(
            items: <HistoryItem>[_movieItem1, _episodeItem1],
            nextCursor: 'cursor-1',
            hasMore: true,
          ),
        },
      );

      final HistoryCubit cubit = HistoryCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
      );

      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.items, <HistoryItem>[_movieItem1, _episodeItem1]);

      expect(cubit.state.nextCursor, 'cursor-1');
      expect(cubit.state.hasMore, isTrue);
      expect(cubit.state.hasLoaded, isTrue);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.error, isNull);
      expect(cubit.state.paginationError, isNull);

      expect(repository.calls, 1);
      expect(repository.requests.single.limit, 30);
      expect(repository.requests.single.cursor, isNull);
    });

    test('supports an empty first History page', () async {
      final HistoryCubit cubit = HistoryCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: _HistoryRepository(),
      );

      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.hasLoaded, isTrue);
      expect(cubit.state.items, isEmpty);
      expect(cubit.state.isEmpty, isTrue);
      expect(cubit.state.hasMore, isFalse);
      expect(cubit.state.nextCursor, isNull);
    });

    test('loads another page and appends it in backend order', () async {
      final _HistoryRepository repository = _HistoryRepository(
        pages: <String?, HistoryPage>{
          null: HistoryPage(
            items: <HistoryItem>[_movieItem1, _episodeItem1],
            nextCursor: 'cursor-1',
            hasMore: true,
          ),
          'cursor-1': HistoryPage(
            items: <HistoryItem>[_movieItem2, _episodeItem2],
            nextCursor: 'cursor-2',
            hasMore: true,
          ),
        },
      );

      final HistoryCubit cubit = HistoryCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
      );

      addTearDown(cubit.close);

      await cubit.load();
      await cubit.loadMore();

      expect(cubit.state.items, <HistoryItem>[
        _movieItem1,
        _episodeItem1,
        _movieItem2,
        _episodeItem2,
      ]);

      expect(cubit.state.nextCursor, 'cursor-2');
      expect(cubit.state.hasMore, isTrue);
      expect(cubit.state.isLoadingMore, isFalse);

      expect(repository.calls, 2);

      expect(repository.requests[1].limit, 30);
      expect(repository.requests[1].cursor, 'cursor-1');
    });

    test('clears cursor when final page is loaded', () async {
      final _HistoryRepository repository = _HistoryRepository(
        pages: <String?, HistoryPage>{
          null: HistoryPage(
            items: <HistoryItem>[_movieItem1],
            nextCursor: 'cursor-1',
            hasMore: true,
          ),
          'cursor-1': HistoryPage(
            items: <HistoryItem>[_episodeItem1],
            hasMore: false,
          ),
        },
      );

      final HistoryCubit cubit = HistoryCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
      );

      addTearDown(cubit.close);

      await cubit.load();
      await cubit.loadMore();

      expect(cubit.state.hasMore, isFalse);
      expect(cubit.state.nextCursor, isNull);
      expect(cubit.state.canLoadMore, isFalse);
    });

    test('defensively removes duplicate events from pagination', () async {
      final _HistoryRepository repository = _HistoryRepository(
        pages: <String?, HistoryPage>{
          null: HistoryPage(
            items: <HistoryItem>[_movieItem1, _episodeItem1],
            nextCursor: 'cursor-1',
            hasMore: true,
          ),
          'cursor-1': HistoryPage(
            items: <HistoryItem>[_episodeItem1, _movieItem2],
            hasMore: false,
          ),
        },
      );

      final HistoryCubit cubit = HistoryCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
      );

      addTearDown(cubit.close);

      await cubit.load();
      await cubit.loadMore();

      expect(cubit.state.items, <HistoryItem>[
        _movieItem1,
        _episodeItem1,
        _movieItem2,
      ]);
    });

    test('does not load more before initial History has loaded', () async {
      final _HistoryRepository repository = _HistoryRepository();

      final HistoryCubit cubit = HistoryCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
      );

      addTearDown(cubit.close);

      await cubit.loadMore();

      expect(repository.calls, 0);
    });

    test('does not load more when there is no next page', () async {
      final _HistoryRepository repository = _HistoryRepository(
        pages: <String?, HistoryPage>{
          null: HistoryPage(items: <HistoryItem>[_movieItem1], hasMore: false),
        },
      );

      final HistoryCubit cubit = HistoryCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
      );

      addTearDown(cubit.close);

      await cubit.load();

      expect(repository.calls, 1);
      expect(cubit.state.canLoadMore, isFalse);

      await cubit.loadMore();

      expect(repository.calls, 1);
    });

    test('does not load more without a cursor', () async {
      final _HistoryRepository repository = _HistoryRepository(
        pages: <String?, HistoryPage>{
          null: HistoryPage(items: <HistoryItem>[_movieItem1], hasMore: true),
        },
      );

      final HistoryCubit cubit = HistoryCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
      );

      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.hasMore, isTrue);
      expect(cubit.state.nextCursor, isNull);
      expect(cubit.state.canLoadMore, isFalse);

      await cubit.loadMore();

      expect(repository.calls, 1);
    });

    test('prevents duplicate initial loading requests', () async {
      final _ControlledHistoryRepository repository =
          _ControlledHistoryRepository();

      final HistoryCubit cubit = HistoryCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
      );

      addTearDown(cubit.close);

      final Future<void> firstLoad = cubit.load();

      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.isLoading, isTrue);
      expect(repository.calls, 1);

      await cubit.load();

      expect(repository.calls, 1);

      repository.complete(
        HistoryPage(items: <HistoryItem>[_movieItem1], hasMore: false),
      );

      await firstLoad;

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.items, <HistoryItem>[_movieItem1]);
    });

    test('prevents duplicate pagination requests', () async {
      final _ControlledPaginationHistoryRepository repository =
          _ControlledPaginationHistoryRepository();

      final HistoryCubit cubit = HistoryCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
      );

      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.canLoadMore, isTrue);

      final Future<void> firstLoadMore = cubit.loadMore();

      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.isLoadingMore, isTrue);
      expect(repository.paginationCalls, 1);

      await cubit.loadMore();

      expect(repository.paginationCalls, 1);

      repository.completePagination(
        HistoryPage(items: <HistoryItem>[_episodeItem1], hasMore: false),
      );

      await firstLoadMore;

      expect(cubit.state.items, <HistoryItem>[_movieItem1, _episodeItem1]);
    });

    test('maps initial AppException failure to fatal error', () async {
      const AppException error = AppException.connection();

      final HistoryCubit cubit = HistoryCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: _HistoryRepository(initialError: error),
      );

      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.error, error);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.hasLoaded, isFalse);
      expect(cubit.state.items, isEmpty);
    });

    test('maps unexpected initial failure to unknown', () async {
      final HistoryCubit cubit = HistoryCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: const _UnexpectedHistoryRepository(),
      );

      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.error?.type, AppExceptionType.unknown);

      expect(cubit.state.isLoading, isFalse);
    });

    test('pagination failure preserves existing History', () async {
      const AppException paginationError = AppException.connection();

      final _PaginationFailureRepository repository =
          _PaginationFailureRepository(paginationError: paginationError);

      final HistoryCubit cubit = HistoryCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
      );

      addTearDown(cubit.close);

      await cubit.load();

      final List<HistoryItem> existingItems = List<HistoryItem>.of(
        cubit.state.items,
      );

      expect(existingItems, <HistoryItem>[_movieItem1]);

      await cubit.loadMore();

      expect(cubit.state.items, existingItems);
      expect(cubit.state.paginationError, paginationError);
      expect(cubit.state.error, isNull);
      expect(cubit.state.hasLoaded, isTrue);
      expect(cubit.state.isLoadingMore, isFalse);
      expect(cubit.state.nextCursor, 'cursor-1');
      expect(cubit.state.hasMore, isTrue);
    });

    test('maps unexpected pagination failure to unknown', () async {
      final _UnexpectedPaginationRepository repository =
          _UnexpectedPaginationRepository();

      final HistoryCubit cubit = HistoryCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
      );

      addTearDown(cubit.close);

      await cubit.load();
      await cubit.loadMore();

      expect(cubit.state.paginationError?.type, AppExceptionType.unknown);

      expect(cubit.state.items, <HistoryItem>[_movieItem1]);
    });

    test('retry reloads the authoritative first page', () async {
      final _RetryHistoryRepository repository = _RetryHistoryRepository();

      final HistoryCubit cubit = HistoryCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
      );

      addTearDown(cubit.close);

      await cubit.load();

      expect(repository.calls, 1);
      expect(cubit.state.error, isNotNull);

      await cubit.retry();

      expect(repository.calls, 2);
      expect(cubit.state.error, isNull);
      expect(cubit.state.hasLoaded, isTrue);

      expect(cubit.state.items, <HistoryItem>[_movieItem1]);
    });

    test('reload replaces existing History with newest server page', () async {
      final _ReloadHistoryRepository repository = _ReloadHistoryRepository();

      final HistoryCubit cubit = HistoryCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
      );

      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.items, <HistoryItem>[_movieItem2]);

      await cubit.load();

      expect(cubit.state.items, <HistoryItem>[_movieItem1]);

      expect(repository.calls, 2);
    });

    test('retryLoadMore repeats pagination after failure', () async {
      final _RetryPaginationRepository repository =
          _RetryPaginationRepository();

      final HistoryCubit cubit = HistoryCubit(
        viewingStateChangeNotifier: viewingStateChangeNotifier,
        repository: repository,
      );

      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.items, <HistoryItem>[_movieItem1]);

      await cubit.loadMore();

      expect(repository.paginationCalls, 1);
      expect(cubit.state.paginationError, isNotNull);

      await cubit.retryLoadMore();

      expect(repository.paginationCalls, 2);
      expect(cubit.state.paginationError, isNull);

      expect(cubit.state.items, <HistoryItem>[_movieItem1, _episodeItem1]);

      expect(cubit.state.hasMore, isFalse);
      expect(cubit.state.nextCursor, isNull);
    });
    test('reloads History after viewing state changes', () async {
      final _HistoryRepository repository = _HistoryRepository();

      final HistoryCubit cubit = HistoryCubit(
        repository: repository,
        viewingStateChangeNotifier: viewingStateChangeNotifier,
      );

      addTearDown(cubit.close);

      expect(repository.calls, 0);

      viewingStateChangeNotifier.notifyChanged();

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(repository.calls, 1);
      expect(cubit.state.hasLoaded, isTrue);
    });
  });

  group('HistoryState', () {
    test('isEmpty requires a successful first load', () {
      const HistoryState initial = HistoryState();

      expect(initial.items, isEmpty);
      expect(initial.isEmpty, isFalse);

      const HistoryState loadedEmpty = HistoryState(hasLoaded: true);

      expect(loadedEmpty.isEmpty, isTrue);
    });

    test('canLoadMore requires a loaded usable cursor', () {
      const HistoryState state = HistoryState(
        hasLoaded: true,
        hasMore: true,
        nextCursor: 'cursor-1',
      );

      expect(state.canLoadMore, isTrue);

      expect(state.copyWith(isLoading: true).canLoadMore, isFalse);

      expect(state.copyWith(isLoadingMore: true).canLoadMore, isFalse);

      expect(state.copyWith(hasMore: false).canLoadMore, isFalse);

      expect(state.copyWith(clearNextCursor: true).canLoadMore, isFalse);
    });
  });
}

final HistoryMovieItem _movieItem1 = HistoryMovieItem(
  eventId: 'movie-event-1',
  watchedAt: DateTime.utc(2026, 8, 19, 22),
  movieId: 'movie-1',
  movieTmdbId: 438631,
  movieTitle: 'Dune',
);

final HistoryEpisodeItem _episodeItem1 = HistoryEpisodeItem(
  eventId: 'episode-event-1',
  watchedAt: DateTime.utc(2026, 8, 19, 21),
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

final HistoryMovieItem _movieItem2 = HistoryMovieItem(
  eventId: 'movie-event-2',
  watchedAt: DateTime.utc(2026, 8, 18, 20),
  movieId: 'movie-2',
  movieTmdbId: 329865,
  movieTitle: 'Arrival',
);

final HistoryEpisodeItem _episodeItem2 = HistoryEpisodeItem(
  eventId: 'episode-event-2',
  watchedAt: DateTime.utc(2026, 8, 17, 19),
  showId: 'show-2',
  showTmdbId: 66732,
  showTitle: 'Stranger Things',
  episode: const HistoryEpisode(
    id: 'episode-2',
    tmdbId: 2202,
    seasonNumber: 1,
    episodeNumber: 2,
    title: 'The Weirdo on Maple Street',
  ),
);

final class _HistoryRequest {
  const _HistoryRequest({required this.limit, required this.cursor});

  final int limit;
  final String? cursor;
}

class _HistoryRepository implements HistoryRepository {
  _HistoryRepository({Map<String?, HistoryPage>? pages, this.initialError})
    : pages =
          pages ??
          <String?, HistoryPage>{
            null: const HistoryPage(items: <HistoryItem>[], hasMore: false),
          };

  final Map<String?, HistoryPage> pages;
  final AppException? initialError;

  int calls = 0;

  final List<_HistoryRequest> requests = <_HistoryRequest>[];

  @override
  Future<HistoryPreview> getPreview() {
    throw UnimplementedError();
  }

  @override
  Future<HistoryPage> getHistory({int limit = 30, String? cursor}) async {
    calls += 1;

    requests.add(_HistoryRequest(limit: limit, cursor: cursor));

    final AppException? failure = initialError;

    if (cursor == null && failure != null) {
      throw failure;
    }

    return pages[cursor] ??
        const HistoryPage(items: <HistoryItem>[], hasMore: false);
  }
}

final class _UnexpectedHistoryRepository implements HistoryRepository {
  const _UnexpectedHistoryRepository();

  @override
  Future<HistoryPreview> getPreview() {
    throw UnimplementedError();
  }

  @override
  Future<HistoryPage> getHistory({int limit = 30, String? cursor}) {
    throw StateError('Unexpected History failure.');
  }
}

final class _ControlledHistoryRepository implements HistoryRepository {
  final Completer<HistoryPage> _result = Completer<HistoryPage>();

  int calls = 0;

  void complete(HistoryPage page) {
    if (_result.isCompleted) {
      return;
    }

    _result.complete(page);
  }

  @override
  Future<HistoryPreview> getPreview() {
    throw UnimplementedError();
  }

  @override
  Future<HistoryPage> getHistory({int limit = 30, String? cursor}) {
    calls += 1;

    return _result.future;
  }
}

final class _ControlledPaginationHistoryRepository
    implements HistoryRepository {
  final Completer<HistoryPage> _paginationResult = Completer<HistoryPage>();

  int paginationCalls = 0;

  void completePagination(HistoryPage page) {
    if (_paginationResult.isCompleted) {
      return;
    }

    _paginationResult.complete(page);
  }

  @override
  Future<HistoryPreview> getPreview() {
    throw UnimplementedError();
  }

  @override
  Future<HistoryPage> getHistory({int limit = 30, String? cursor}) {
    if (cursor == null) {
      return Future<HistoryPage>.value(
        HistoryPage(
          items: <HistoryItem>[_movieItem1],
          nextCursor: 'cursor-1',
          hasMore: true,
        ),
      );
    }

    paginationCalls += 1;

    return _paginationResult.future;
  }
}

final class _PaginationFailureRepository implements HistoryRepository {
  const _PaginationFailureRepository({required this.paginationError});

  final AppException paginationError;

  @override
  Future<HistoryPreview> getPreview() {
    throw UnimplementedError();
  }

  @override
  Future<HistoryPage> getHistory({int limit = 30, String? cursor}) async {
    if (cursor == null) {
      return HistoryPage(
        items: <HistoryItem>[_movieItem1],
        nextCursor: 'cursor-1',
        hasMore: true,
      );
    }

    throw paginationError;
  }
}

final class _UnexpectedPaginationRepository implements HistoryRepository {
  @override
  Future<HistoryPreview> getPreview() {
    throw UnimplementedError();
  }

  @override
  Future<HistoryPage> getHistory({int limit = 30, String? cursor}) async {
    if (cursor == null) {
      return HistoryPage(
        items: <HistoryItem>[_movieItem1],
        nextCursor: 'cursor-1',
        hasMore: true,
      );
    }

    throw StateError('Unexpected pagination failure.');
  }
}

final class _RetryHistoryRepository implements HistoryRepository {
  int calls = 0;

  @override
  Future<HistoryPreview> getPreview() {
    throw UnimplementedError();
  }

  @override
  Future<HistoryPage> getHistory({int limit = 30, String? cursor}) async {
    calls += 1;

    if (calls == 1) {
      throw const AppException.connection();
    }

    return HistoryPage(items: <HistoryItem>[_movieItem1], hasMore: false);
  }
}

final class _ReloadHistoryRepository implements HistoryRepository {
  int calls = 0;

  @override
  Future<HistoryPreview> getPreview() {
    throw UnimplementedError();
  }

  @override
  Future<HistoryPage> getHistory({int limit = 30, String? cursor}) async {
    calls += 1;

    if (calls == 1) {
      return HistoryPage(items: <HistoryItem>[_movieItem2], hasMore: false);
    }

    return HistoryPage(items: <HistoryItem>[_movieItem1], hasMore: false);
  }
}

final class _RetryPaginationRepository implements HistoryRepository {
  int paginationCalls = 0;

  @override
  Future<HistoryPreview> getPreview() {
    throw UnimplementedError();
  }

  @override
  Future<HistoryPage> getHistory({int limit = 30, String? cursor}) async {
    if (cursor == null) {
      return HistoryPage(
        items: <HistoryItem>[_movieItem1],
        nextCursor: 'cursor-1',
        hasMore: true,
      );
    }

    paginationCalls += 1;

    if (paginationCalls == 1) {
      throw const AppException.connection();
    }

    return HistoryPage(items: <HistoryItem>[_episodeItem1], hasMore: false);
  }
}
