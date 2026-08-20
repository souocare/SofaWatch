import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/server/application/cubit/server_logs_cubit.dart';
import 'package:sofawatch/features/server/application/cubit/server_logs_state.dart';
import 'package:sofawatch/features/server/domain/models/background_job.dart';
import 'package:sofawatch/features/server/domain/models/server_health.dart';
import 'package:sofawatch/features/server/domain/models/server_logs.dart';
import 'package:sofawatch/features/server/domain/repositories/server_repository.dart';

void main() {
  group('ServerLogsCubit', () {
    test('starts in initial state', () {
      final ServerLogsCubit cubit = ServerLogsCubit(
        repository: _ServerRepository(),
      );

      addTearDown(cubit.close);

      expect(cubit.state, const ServerLogsInitial());
    });

    test('loads the first Server Logs page', () async {
      final _ServerRepository repository = _ServerRepository(
        pages: <_LogsRequest, ServerLogsPage>{
          const _LogsRequest(offset: 0, limit: 50): _firstPage,
        },
      );

      final ServerLogsCubit cubit = ServerLogsCubit(repository: repository);

      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state, isA<ServerLogsSuccess>());

      final ServerLogsSuccess state = cubit.state as ServerLogsSuccess;

      expect(state.page, _firstPage);

      expect(state.level, isNull);

      expect(state.isRefreshing, isFalse);

      expect(state.isLoadingMore, isFalse);

      expect(state.refreshError, isNull);

      expect(state.paginationError, isNull);

      expect(repository.requests, <_LogsRequest>[
        const _LogsRequest(offset: 0, limit: 50),
      ]);
    });

    test('supports an empty first Server Logs page', () async {
      final _ServerRepository repository = _ServerRepository(
        pages: <_LogsRequest, ServerLogsPage>{
          const _LogsRequest(offset: 0, limit: 50): const ServerLogsPage(
            items: <ServerLogEntry>[],
            offset: 0,
            limit: 50,
            total: 0,
            hasNext: false,
          ),
        },
      );

      final ServerLogsCubit cubit = ServerLogsCubit(repository: repository);

      addTearDown(cubit.close);

      await cubit.load();

      final ServerLogsSuccess state = cubit.state as ServerLogsSuccess;

      expect(state.page.items, isEmpty);

      expect(state.page.total, 0);

      expect(state.page.hasNext, isFalse);
    });

    test('maps initial AppException failure', () async {
      final _ServerRepository repository = _ServerRepository(
        error: const AppException.connection(),
      );

      final ServerLogsCubit cubit = ServerLogsCubit(repository: repository);

      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state, isA<ServerLogsFailure>());

      final ServerLogsFailure state = cubit.state as ServerLogsFailure;

      expect(state.error.type, AppExceptionType.connection);

      expect(state.level, isNull);
    });

    test('maps unexpected initial failure to unknown', () async {
      final _ServerRepository repository = _ServerRepository(
        unexpectedError: StateError('Unexpected failure.'),
      );

      final ServerLogsCubit cubit = ServerLogsCubit(repository: repository);

      addTearDown(cubit.close);

      await cubit.load();

      final ServerLogsFailure state = cubit.state as ServerLogsFailure;

      expect(state.error.type, AppExceptionType.unknown);
    });

    test('changes level and resets pagination', () async {
      final _ServerRepository repository = _ServerRepository(
        pages: <_LogsRequest, ServerLogsPage>{
          const _LogsRequest(offset: 0, limit: 50): _firstPage,
          const _LogsRequest(level: ServerLogLevel.error, offset: 0, limit: 50):
              _errorPage,
        },
      );

      final ServerLogsCubit cubit = ServerLogsCubit(repository: repository);

      addTearDown(cubit.close);

      await cubit.load();
      await cubit.setLevel(ServerLogLevel.error);

      final ServerLogsSuccess state = cubit.state as ServerLogsSuccess;

      expect(state.level, ServerLogLevel.error);

      expect(state.page, _errorPage);

      expect(
        repository.requests.last,
        const _LogsRequest(level: ServerLogLevel.error, offset: 0, limit: 50),
      );
    });

    test('does not reload when level is unchanged', () async {
      final _ServerRepository repository = _ServerRepository(
        pages: <_LogsRequest, ServerLogsPage>{
          const _LogsRequest(offset: 0, limit: 50): _firstPage,
        },
      );

      final ServerLogsCubit cubit = ServerLogsCubit(repository: repository);

      addTearDown(cubit.close);

      await cubit.load();

      expect(repository.calls, 1);

      await cubit.setLevel(null);

      expect(repository.calls, 1);
    });

    test('retry preserves failed level filter', () async {
      final _RetryLevelServerRepository repository =
          _RetryLevelServerRepository();

      final ServerLogsCubit cubit = ServerLogsCubit(repository: repository);

      addTearDown(cubit.close);

      await cubit.setLevel(ServerLogLevel.error);

      expect(cubit.state, isA<ServerLogsFailure>());

      final ServerLogsFailure failedState = cubit.state as ServerLogsFailure;

      expect(failedState.level, ServerLogLevel.error);

      await cubit.retry();

      final ServerLogsSuccess successState = cubit.state as ServerLogsSuccess;

      expect(successState.level, ServerLogLevel.error);

      expect(repository.requests, <_LogsRequest>[
        const _LogsRequest(level: ServerLogLevel.error, offset: 0, limit: 50),
        const _LogsRequest(level: ServerLogLevel.error, offset: 0, limit: 50),
      ]);
    });

    test('refresh preserves current data while loading', () async {
      final _ControlledRefreshServerRepository repository =
          _ControlledRefreshServerRepository();

      final ServerLogsCubit cubit = ServerLogsCubit(repository: repository);

      addTearDown(cubit.close);

      await cubit.load();

      final Future<void> refresh = cubit.refresh();

      await Future<void>.delayed(Duration.zero);

      final ServerLogsSuccess loadingState = cubit.state as ServerLogsSuccess;

      expect(loadingState.page, _firstPage);

      expect(loadingState.isRefreshing, isTrue);

      repository.completeRefresh(_refreshedPage);

      await refresh;

      final ServerLogsSuccess finalState = cubit.state as ServerLogsSuccess;

      expect(finalState.page, _refreshedPage);

      expect(finalState.isRefreshing, isFalse);
    });

    test('refresh failure preserves current data', () async {
      final _RefreshFailureServerRepository repository =
          _RefreshFailureServerRepository();

      final ServerLogsCubit cubit = ServerLogsCubit(repository: repository);

      addTearDown(cubit.close);

      await cubit.load();
      await cubit.refresh();

      final ServerLogsSuccess state = cubit.state as ServerLogsSuccess;

      expect(state.page, _firstPage);

      expect(state.isRefreshing, isFalse);

      expect(state.refreshError?.type, AppExceptionType.connection);
    });

    test('loads next page and appends backend order', () async {
      final _ServerRepository repository = _ServerRepository(
        pages: <_LogsRequest, ServerLogsPage>{
          const _LogsRequest(offset: 0, limit: 50): _firstPage,
          const _LogsRequest(offset: 2, limit: 50): _secondPage,
        },
      );

      final ServerLogsCubit cubit = ServerLogsCubit(repository: repository);

      addTearDown(cubit.close);

      await cubit.load();
      await cubit.loadMore();

      final ServerLogsSuccess state = cubit.state as ServerLogsSuccess;

      expect(state.page.items, <ServerLogEntry>[_log1, _log2, _log3]);

      expect(state.page.total, 3);

      expect(state.page.hasNext, isFalse);

      expect(state.isLoadingMore, isFalse);

      expect(
        repository.requests.last,
        const _LogsRequest(offset: 2, limit: 50),
      );
    });

    test('does not load more before initial load', () async {
      final _ServerRepository repository = _ServerRepository();

      final ServerLogsCubit cubit = ServerLogsCubit(repository: repository);

      addTearDown(cubit.close);

      await cubit.loadMore();

      expect(repository.calls, 0);
    });

    test('does not load more when there is no next page', () async {
      final _ServerRepository repository = _ServerRepository(
        pages: <_LogsRequest, ServerLogsPage>{
          const _LogsRequest(offset: 0, limit: 50): _errorPage,
        },
      );

      final ServerLogsCubit cubit = ServerLogsCubit(repository: repository);

      addTearDown(cubit.close);

      await cubit.load();

      final ServerLogsSuccess state = cubit.state as ServerLogsSuccess;

      expect(state.canLoadMore, isFalse);

      await cubit.loadMore();

      expect(repository.calls, 1);
    });

    test('pagination failure preserves existing logs', () async {
      final _PaginationFailureServerRepository repository =
          _PaginationFailureServerRepository();

      final ServerLogsCubit cubit = ServerLogsCubit(repository: repository);

      addTearDown(cubit.close);

      await cubit.load();
      await cubit.loadMore();

      final ServerLogsSuccess state = cubit.state as ServerLogsSuccess;

      expect(state.page, _firstPage);

      expect(state.isLoadingMore, isFalse);

      expect(state.paginationError?.type, AppExceptionType.connection);
    });

    test('retryPagination retries failed page', () async {
      final _RetryPaginationServerRepository repository =
          _RetryPaginationServerRepository();

      final ServerLogsCubit cubit = ServerLogsCubit(repository: repository);

      addTearDown(cubit.close);

      await cubit.load();
      await cubit.loadMore();

      ServerLogsSuccess state = cubit.state as ServerLogsSuccess;

      expect(state.paginationError, isNotNull);

      await cubit.retryPagination();

      state = cubit.state as ServerLogsSuccess;

      expect(state.page.items, <ServerLogEntry>[_log1, _log2, _log3]);

      expect(state.paginationError, isNull);

      expect(repository.calls, 3);
    });

    test('ignores older response after level changes', () async {
      final _ControlledFilterServerRepository repository =
          _ControlledFilterServerRepository();

      final ServerLogsCubit cubit = ServerLogsCubit(repository: repository);

      addTearDown(cubit.close);

      final Future<void> firstLoad = cubit.load();

      await Future<void>.delayed(Duration.zero);

      final Future<void> filteredLoad = cubit.setLevel(ServerLogLevel.error);

      await Future<void>.delayed(Duration.zero);

      repository.completeFiltered(_errorPage);

      await filteredLoad;

      repository.completeInitial(_firstPage);

      await firstLoad;

      final ServerLogsSuccess state = cubit.state as ServerLogsSuccess;

      expect(state.level, ServerLogLevel.error);

      expect(state.page, _errorPage);
    });

    test('ignores pagination response after level changes', () async {
      final _ControlledPaginationFilterRepository repository =
          _ControlledPaginationFilterRepository();

      final ServerLogsCubit cubit = ServerLogsCubit(repository: repository);

      addTearDown(cubit.close);

      await cubit.load();

      final Future<void> pagination = cubit.loadMore();

      await Future<void>.delayed(Duration.zero);

      final Future<void> filter = cubit.setLevel(ServerLogLevel.error);

      await Future<void>.delayed(Duration.zero);

      repository.completeFilter(_errorPage);

      await filter;

      repository.completePagination(_secondPage);

      await pagination;

      final ServerLogsSuccess state = cubit.state as ServerLogsSuccess;

      expect(state.level, ServerLogLevel.error);

      expect(state.page, _errorPage);

      expect(state.page.items, isNot(contains(_log3)));
    });
  });
}

final ServerLogEntry _log1 = ServerLogEntry(
  timestamp: _date1,
  level: ServerLogLevel.error,
  logger: 'app.jobs.executor',
  message: 'Metadata sync failed.',
  component: ServerLogComponent.worker,
);

final ServerLogEntry _log2 = ServerLogEntry(
  timestamp: _date2,
  level: ServerLogLevel.info,
  logger: 'app.main',
  message: 'SofaWatch API starting',
  component: ServerLogComponent.api,
);

final ServerLogEntry _log3 = ServerLogEntry(
  timestamp: _date3,
  level: ServerLogLevel.warning,
  logger: 'app.providers.tmdb.client',
  message: 'TMDB request retry.',
  component: ServerLogComponent.api,
);

final ServerLogEntry _errorLog = ServerLogEntry(
  timestamp: _date1,
  level: ServerLogLevel.error,
  logger: 'app.jobs.executor',
  message: 'Metadata sync failed.',
  component: ServerLogComponent.worker,
);

final DateTime _date1 = DateTime.utc(2026, 8, 20, 15, 30);

final DateTime _date2 = DateTime.utc(2026, 8, 20, 15);

final DateTime _date3 = DateTime.utc(2026, 8, 20, 14, 30);

final ServerLogsPage _firstPage = ServerLogsPage(
  items: <ServerLogEntry>[_log1, _log2],
  offset: 0,
  limit: 50,
  total: 3,
  hasNext: true,
);

final ServerLogsPage _secondPage = ServerLogsPage(
  items: <ServerLogEntry>[_log3],
  offset: 2,
  limit: 50,
  total: 3,
  hasNext: false,
);

final ServerLogsPage _errorPage = ServerLogsPage(
  items: <ServerLogEntry>[_errorLog],
  offset: 0,
  limit: 50,
  total: 1,
  hasNext: false,
);

final ServerLogsPage _refreshedPage = ServerLogsPage(
  items: <ServerLogEntry>[_log3, _log1],
  offset: 0,
  limit: 50,
  total: 2,
  hasNext: false,
);

final class _LogsRequest {
  const _LogsRequest({this.level, required this.offset, required this.limit});

  final ServerLogLevel? level;
  final int offset;
  final int limit;

  @override
  bool operator ==(Object other) {
    return other is _LogsRequest &&
        other.level == level &&
        other.offset == offset &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(level, offset, limit);
}

class _ServerRepository implements ServerRepository {
  _ServerRepository({
    this.pages = const <_LogsRequest, ServerLogsPage>{},
    this.error,
    this.unexpectedError,
  });

  final Map<_LogsRequest, ServerLogsPage> pages;
  final AppException? error;
  final Object? unexpectedError;

  int calls = 0;

  final List<_LogsRequest> requests = <_LogsRequest>[];

  @override
  Future<ServerLogsPage> getLogs({
    ServerLogLevel? level,
    int offset = 0,
    int limit = 50,
  }) async {
    calls += 1;

    final _LogsRequest request = _LogsRequest(
      level: level,
      offset: offset,
      limit: limit,
    );

    requests.add(request);

    final AppException? failure = error;

    if (failure != null) {
      throw failure;
    }

    final Object? unexpected = unexpectedError;

    if (unexpected != null) {
      throw unexpected;
    }

    return pages[request] ??
        const ServerLogsPage(
          items: <ServerLogEntry>[],
          offset: 0,
          limit: 50,
          total: 0,
          hasNext: false,
        );
  }

  @override
  Future<ServerHealth> getHealth() {
    throw UnimplementedError();
  }

  @override
  Future<List<BackgroundJob>> getBackgroundJobs() {
    throw UnimplementedError();
  }

  @override
  Future<BackgroundJob> runBackgroundJob(String jobKey) {
    throw UnimplementedError();
  }
}

final class _RetryLevelServerRepository implements ServerRepository {
  int calls = 0;

  final List<_LogsRequest> requests = <_LogsRequest>[];

  @override
  Future<ServerLogsPage> getLogs({
    ServerLogLevel? level,
    int offset = 0,
    int limit = 50,
  }) async {
    calls += 1;

    requests.add(_LogsRequest(level: level, offset: offset, limit: limit));

    if (calls == 1) {
      throw const AppException.connection();
    }

    return _errorPage;
  }

  @override
  Future<ServerHealth> getHealth() {
    throw UnimplementedError();
  }

  @override
  Future<List<BackgroundJob>> getBackgroundJobs() {
    throw UnimplementedError();
  }

  @override
  Future<BackgroundJob> runBackgroundJob(String jobKey) {
    throw UnimplementedError();
  }
}

final class _ControlledRefreshServerRepository implements ServerRepository {
  int calls = 0;

  final Completer<ServerLogsPage> _refresh = Completer<ServerLogsPage>();

  void completeRefresh(ServerLogsPage page) {
    _refresh.complete(page);
  }

  @override
  Future<ServerLogsPage> getLogs({
    ServerLogLevel? level,
    int offset = 0,
    int limit = 50,
  }) {
    calls += 1;

    if (calls == 1) {
      return Future<ServerLogsPage>.value(_firstPage);
    }

    return _refresh.future;
  }

  @override
  Future<ServerHealth> getHealth() {
    throw UnimplementedError();
  }

  @override
  Future<List<BackgroundJob>> getBackgroundJobs() {
    throw UnimplementedError();
  }

  @override
  Future<BackgroundJob> runBackgroundJob(String jobKey) {
    throw UnimplementedError();
  }
}

final class _RefreshFailureServerRepository implements ServerRepository {
  int calls = 0;

  @override
  Future<ServerLogsPage> getLogs({
    ServerLogLevel? level,
    int offset = 0,
    int limit = 50,
  }) async {
    calls += 1;

    if (calls == 1) {
      return _firstPage;
    }

    throw const AppException.connection();
  }

  @override
  Future<ServerHealth> getHealth() {
    throw UnimplementedError();
  }

  @override
  Future<List<BackgroundJob>> getBackgroundJobs() {
    throw UnimplementedError();
  }

  @override
  Future<BackgroundJob> runBackgroundJob(String jobKey) {
    throw UnimplementedError();
  }
}

final class _PaginationFailureServerRepository implements ServerRepository {
  int calls = 0;

  @override
  Future<ServerLogsPage> getLogs({
    ServerLogLevel? level,
    int offset = 0,
    int limit = 50,
  }) async {
    calls += 1;

    if (calls == 1) {
      return _firstPage;
    }

    throw const AppException.connection();
  }

  @override
  Future<ServerHealth> getHealth() {
    throw UnimplementedError();
  }

  @override
  Future<List<BackgroundJob>> getBackgroundJobs() {
    throw UnimplementedError();
  }

  @override
  Future<BackgroundJob> runBackgroundJob(String jobKey) {
    throw UnimplementedError();
  }
}

final class _RetryPaginationServerRepository implements ServerRepository {
  int calls = 0;

  @override
  Future<ServerLogsPage> getLogs({
    ServerLogLevel? level,
    int offset = 0,
    int limit = 50,
  }) async {
    calls += 1;

    if (calls == 1) {
      return _firstPage;
    }

    if (calls == 2) {
      throw const AppException.connection();
    }

    return _secondPage;
  }

  @override
  Future<ServerHealth> getHealth() {
    throw UnimplementedError();
  }

  @override
  Future<List<BackgroundJob>> getBackgroundJobs() {
    throw UnimplementedError();
  }

  @override
  Future<BackgroundJob> runBackgroundJob(String jobKey) {
    throw UnimplementedError();
  }
}

final class _ControlledFilterServerRepository implements ServerRepository {
  final Completer<ServerLogsPage> _initial = Completer<ServerLogsPage>();

  final Completer<ServerLogsPage> _filtered = Completer<ServerLogsPage>();

  void completeInitial(ServerLogsPage page) {
    _initial.complete(page);
  }

  void completeFiltered(ServerLogsPage page) {
    _filtered.complete(page);
  }

  @override
  Future<ServerLogsPage> getLogs({
    ServerLogLevel? level,
    int offset = 0,
    int limit = 50,
  }) {
    if (level == ServerLogLevel.error) {
      return _filtered.future;
    }

    return _initial.future;
  }

  @override
  Future<ServerHealth> getHealth() {
    throw UnimplementedError();
  }

  @override
  Future<List<BackgroundJob>> getBackgroundJobs() {
    throw UnimplementedError();
  }

  @override
  Future<BackgroundJob> runBackgroundJob(String jobKey) {
    throw UnimplementedError();
  }
}

final class _ControlledPaginationFilterRepository implements ServerRepository {
  final Completer<ServerLogsPage> _pagination = Completer<ServerLogsPage>();

  final Completer<ServerLogsPage> _filter = Completer<ServerLogsPage>();

  void completePagination(ServerLogsPage page) {
    _pagination.complete(page);
  }

  void completeFilter(ServerLogsPage page) {
    _filter.complete(page);
  }

  @override
  Future<ServerLogsPage> getLogs({
    ServerLogLevel? level,
    int offset = 0,
    int limit = 50,
  }) {
    if (level == ServerLogLevel.error) {
      return _filter.future;
    }

    if (offset > 0) {
      return _pagination.future;
    }

    return Future<ServerLogsPage>.value(_firstPage);
  }

  @override
  Future<ServerHealth> getHealth() {
    throw UnimplementedError();
  }

  @override
  Future<List<BackgroundJob>> getBackgroundJobs() {
    throw UnimplementedError();
  }

  @override
  Future<BackgroundJob> runBackgroundJob(String jobKey) {
    throw UnimplementedError();
  }
}
