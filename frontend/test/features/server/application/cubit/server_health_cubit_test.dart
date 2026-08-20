import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/server/application/cubit/server_health_cubit.dart';
import 'package:sofawatch/features/server/application/cubit/server_health_state.dart';
import 'package:sofawatch/features/server/domain/models/server_health.dart';
import 'package:sofawatch/features/server/domain/repositories/server_repository.dart';
import 'package:sofawatch/features/server/domain/models/background_job.dart';

void main() {
  group('ServerHealthCubit', () {
    test('starts in initial state', () {
      final ServerHealthCubit cubit = ServerHealthCubit(
        repository: const _ServerRepository(),
      );

      addTearDown(cubit.close);

      expect(cubit.state, const ServerHealthInitial());
    });

    test('loads Server health successfully', () async {
      final ServerHealthCubit cubit = ServerHealthCubit(
        repository: _ServerRepository(health: _health),
      );

      addTearDown(cubit.close);

      final List<ServerHealthState> states = <ServerHealthState>[];

      final StreamSubscription<ServerHealthState> subscription = cubit.stream
          .listen(states.add);

      await cubit.load();

      await Future<void>.delayed(Duration.zero);

      expect(states, <ServerHealthState>[
        const ServerHealthLoading(),
        ServerHealthSuccess(_health),
      ]);

      expect(cubit.state, ServerHealthSuccess(_health));

      await subscription.cancel();
    });

    test('maps AppException failure', () async {
      const AppException error = AppException.connection();

      final ServerHealthCubit cubit = ServerHealthCubit(
        repository: const _ServerRepository(error: error),
      );

      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state, const ServerHealthFailure(error));
    });

    test('maps unexpected failure to unknown', () async {
      final ServerHealthCubit cubit = ServerHealthCubit(
        repository: const _UnexpectedServerRepository(),
      );

      addTearDown(cubit.close);

      await cubit.load();

      final ServerHealthState state = cubit.state;

      expect(state, isA<ServerHealthFailure>());

      final ServerHealthFailure failure = state as ServerHealthFailure;

      expect(failure.error.type, AppExceptionType.unknown);
    });

    test('does not start another load while already loading', () async {
      final _ControlledServerRepository repository =
          _ControlledServerRepository();

      final ServerHealthCubit cubit = ServerHealthCubit(repository: repository);

      addTearDown(cubit.close);

      final Future<void> firstLoad = cubit.load();

      await Future<void>.delayed(Duration.zero);

      expect(cubit.state, const ServerHealthLoading());

      expect(repository.calls, 1);

      await cubit.load();

      expect(repository.calls, 1);

      repository.complete(_health);

      await firstLoad;

      expect(cubit.state, ServerHealthSuccess(_health));
    });

    test('retry performs another Server health request', () async {
      final _RetryServerRepository repository = _RetryServerRepository();

      final ServerHealthCubit cubit = ServerHealthCubit(repository: repository);

      addTearDown(cubit.close);

      await cubit.load();

      expect(repository.calls, 1);

      expect(cubit.state, isA<ServerHealthFailure>());

      await cubit.retry();

      expect(repository.calls, 2);

      expect(cubit.state, ServerHealthSuccess(_health));
    });
  });
}

final ServerHealth _health = ServerHealth(
  status: ServerHealthStatus.healthy,
  checkedAt: DateTime.utc(2026, 8, 20, 15, 30),
  uptimeSeconds: 86400,
  environment: const ServerEnvironment(
    appName: 'SofaWatch',
    environment: 'test',
    debug: false,
    apiHost: '127.0.0.1',
    apiPort: 8000,
    defaultLanguage: 'en-US',
    supportedLanguages: <String>['en-US', 'pt-PT'],
    metadataRefreshDays: 7,
  ),
  storage: const ServerStorage(
    dataDirectory: './data',
    writable: true,
    totalSpaceBytes: 1_000_000,
    usedSpaceBytes: 400_000,
    freeSpaceBytes: 600_000,
    usagePercentage: 40,
    imageCache: ServerImageCache(
      totalSizeBytes: 375,
      totalFiles: 4,
      breakdown: ServerImageCacheBreakdown(
        shows: ServerImageCacheCategory(sizeBytes: 300, files: 2),
        seasons: ServerImageCacheCategory(sizeBytes: 50, files: 1),
        episodes: ServerImageCacheCategory(sizeBytes: 25, files: 1),
      ),
    ),
  ),
  runtime: ServerRuntime(
    pythonVersion: '3.12.11',
    platform: 'Linux',
    startedAt: DateTime.utc(2026, 8, 20, 14, 30),
  ),
  database: const ServerDatabaseHealth(
    status: ServerComponentStatus.healthy,
    engine: 'sqlite',
    latencyMs: 1.42,
    sizeBytes: 1_048_576,
    walSizeBytes: 8_192,
    integrityCheck: ServerDatabaseCheckStatus.ok,
    foreignKeyCheck: ServerDatabaseCheckStatus.ok,
    migration: ServerDatabaseMigration(
      revision: 'bb784a0a2cdc',
      message: 'add admin flag to users',
    ),
  ),
  tmdb: ServerTmdbHealth(
    status: ServerComponentStatus.healthy,
    configured: true,
    latencyMs: 212.5,
  ),
);

class _ServerRepository implements ServerRepository {
  const _ServerRepository({this.health, this.error});

  final ServerHealth? health;
  final AppException? error;

  @override
  Future<ServerHealth> getHealth() async {
    final AppException? failure = error;

    if (failure != null) {
      throw failure;
    }

    return health ?? _health;
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

final class _UnexpectedServerRepository extends _ServerRepository {
  const _UnexpectedServerRepository();

  @override
  Future<ServerHealth> getHealth() {
    throw StateError('Unexpected Server health failure.');
  }
}

final class _ControlledServerRepository implements ServerRepository {
  final Completer<ServerHealth> _result = Completer<ServerHealth>();

  int calls = 0;

  void complete(ServerHealth health) {
    if (_result.isCompleted) {
      return;
    }

    _result.complete(health);
  }

  @override
  Future<ServerHealth> getHealth() {
    calls += 1;

    return _result.future;
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

final class _RetryServerRepository implements ServerRepository {
  int calls = 0;

  @override
  Future<ServerHealth> getHealth() async {
    calls += 1;

    if (calls == 1) {
      throw const AppException.connection();
    }

    return _health;
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
