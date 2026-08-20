import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/server/application/cubit/background_jobs_cubit.dart';
import 'package:sofawatch/features/server/application/cubit/background_jobs_state.dart';
import 'package:sofawatch/features/server/domain/models/background_job.dart';
import 'package:sofawatch/features/server/domain/models/server_health.dart';
import 'package:sofawatch/features/server/domain/models/server_logs.dart';
import 'package:sofawatch/features/server/domain/repositories/server_repository.dart';

void main() {
  group('BackgroundJobsCubit', () {
    test('loads background jobs', () async {
      final _BackgroundJobsRepository repository = _BackgroundJobsRepository(
        jobs: <BackgroundJob>[_successfulJob],
      );

      final BackgroundJobsCubit cubit = BackgroundJobsCubit(
        repository: repository,
      );

      await cubit.load();

      expect(
        cubit.state,
        BackgroundJobsSuccess(jobs: <BackgroundJob>[_successfulJob]),
      );

      expect(repository.getCalls, 1);

      await cubit.close();
    });

    test('emits failure when initial load fails', () async {
      final _BackgroundJobsRepository repository = _BackgroundJobsRepository(
        getError: const AppException.connection(),
      );

      final BackgroundJobsCubit cubit = BackgroundJobsCubit(
        repository: repository,
      );

      await cubit.load();

      expect(cubit.state, isA<BackgroundJobsFailure>());

      await cubit.close();
    });

    test('retries initial load after failure', () async {
      final _RetryBackgroundJobsRepository repository =
          _RetryBackgroundJobsRepository();

      final BackgroundJobsCubit cubit = BackgroundJobsCubit(
        repository: repository,
      );

      await cubit.load();

      expect(cubit.state, isA<BackgroundJobsFailure>());

      await cubit.retry();

      expect(
        cubit.state,
        BackgroundJobsSuccess(jobs: <BackgroundJob>[_successfulJob]),
      );

      expect(repository.getCalls, 2);

      await cubit.close();
    });

    test('runs a background job now', () async {
      final _BackgroundJobsRepository repository = _BackgroundJobsRepository(
        jobs: <BackgroundJob>[_successfulJob],
        runResult: _runningJob,
      );

      final BackgroundJobsCubit cubit = BackgroundJobsCubit(
        repository: repository,
        pollingInterval: const Duration(hours: 1),
      );

      await cubit.load();

      await cubit.runNow('metadata_sync');

      final BackgroundJobsSuccess state = cubit.state as BackgroundJobsSuccess;

      expect(repository.runCalls, 1);

      expect(state.jobs.single.status, BackgroundJobStatus.running);

      expect(state.runningJobKeys, isEmpty);

      await cubit.close();
    });

    test('does not run an already running job', () async {
      final _BackgroundJobsRepository repository = _BackgroundJobsRepository(
        jobs: <BackgroundJob>[_runningJob],
      );

      final BackgroundJobsCubit cubit = BackgroundJobsCubit(
        repository: repository,
        pollingInterval: const Duration(hours: 1),
      );

      await cubit.load();

      await cubit.runNow('metadata_sync');

      expect(repository.runCalls, 0);

      await cubit.close();
    });

    test('keeps jobs and exposes isolated run failure', () async {
      final _BackgroundJobsRepository repository = _BackgroundJobsRepository(
        jobs: <BackgroundJob>[_successfulJob],
        runError: const AppException.connection(),
      );

      final BackgroundJobsCubit cubit = BackgroundJobsCubit(
        repository: repository,
      );

      await cubit.load();

      await cubit.runNow('metadata_sync');

      final BackgroundJobsSuccess state = cubit.state as BackgroundJobsSuccess;

      expect(state.jobs, <BackgroundJob>[_successfulJob]);

      expect(state.isRunning('metadata_sync'), isFalse);

      expect(state.runFailure('metadata_sync'), isA<AppException>());

      await cubit.close();
    });

    test('refreshes while a job is running', () async {
      final _PollingBackgroundJobsRepository repository =
          _PollingBackgroundJobsRepository();

      final BackgroundJobsCubit cubit = BackgroundJobsCubit(
        repository: repository,
        pollingInterval: const Duration(milliseconds: 10),
      );

      await cubit.load();

      expect(repository.getCalls, 1);

      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(repository.getCalls, greaterThan(1));

      final BackgroundJobsSuccess state = cubit.state as BackgroundJobsSuccess;

      expect(state.jobs.single.status, BackgroundJobStatus.success);

      await cubit.close();
    });

    test('polling refresh failure preserves existing jobs', () async {
      final _PollingFailureRepository repository = _PollingFailureRepository();

      final BackgroundJobsCubit cubit = BackgroundJobsCubit(
        repository: repository,
        pollingInterval: const Duration(milliseconds: 10),
      );

      await cubit.load();

      await Future<void>.delayed(const Duration(milliseconds: 25));

      expect(cubit.state, isA<BackgroundJobsSuccess>());

      final BackgroundJobsSuccess state = cubit.state as BackgroundJobsSuccess;

      expect(state.jobs.single, _runningJob);

      await cubit.close();
    });
  });
}

final BackgroundJob _successfulJob = BackgroundJob(
  id: 'job-1',
  key: 'metadata_sync',
  name: 'Metadata sync',
  schedule: 'Every 8h',
  status: BackgroundJobStatus.success,
  lastStartedAt: DateTime.utc(2026, 8, 20, 12),
  lastFinishedAt: DateTime.utc(2026, 8, 20, 12, 0, 11),
  lastDurationMs: 11000,
  lastError: null,
  nextRunAt: DateTime.utc(2026, 8, 20, 20),
  lastResult: const BackgroundJobResultSummary(
    checked: 140,
    refreshed: 23,
    skipped: 117,
    failed: 0,
  ),
);

final BackgroundJob _runningJob = BackgroundJob(
  id: 'job-1',
  key: 'metadata_sync',
  name: 'Metadata sync',
  schedule: 'Every 8h',
  status: BackgroundJobStatus.running,
  lastStartedAt: DateTime.utc(2026, 8, 20, 14),
  lastFinishedAt: null,
  lastDurationMs: null,
  lastError: null,
  nextRunAt: null,
  lastResult: null,
);

class _BackgroundJobsRepository implements ServerRepository {
  _BackgroundJobsRepository({
    this.jobs = const <BackgroundJob>[],
    this.runResult,
    this.getError,
    this.runError,
  });

  final List<BackgroundJob> jobs;
  final BackgroundJob? runResult;

  final AppException? getError;
  final AppException? runError;

  int getCalls = 0;
  int runCalls = 0;

  @override
  Future<List<BackgroundJob>> getBackgroundJobs() async {
    getCalls += 1;

    final AppException? failure = getError;

    if (failure != null) {
      throw failure;
    }

    return jobs;
  }

  @override
  Future<BackgroundJob> runBackgroundJob(String jobKey) async {
    runCalls += 1;

    final AppException? failure = runError;

    if (failure != null) {
      throw failure;
    }

    return runResult ?? _runningJob;
  }

  @override
  Future<ServerLogsPage> getLogs({
    ServerLogLevel? level,
    int offset = 0,
    int limit = 50,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ServerHealth> getHealth() {
    throw UnimplementedError();
  }
}

final class _RetryBackgroundJobsRepository implements ServerRepository {
  int getCalls = 0;

  @override
  Future<List<BackgroundJob>> getBackgroundJobs() async {
    getCalls += 1;

    if (getCalls == 1) {
      throw const AppException.connection();
    }

    return <BackgroundJob>[_successfulJob];
  }

  @override
  Future<BackgroundJob> runBackgroundJob(String jobKey) {
    throw UnimplementedError();
  }

  @override
  Future<ServerHealth> getHealth() {
    throw UnimplementedError();
  }

  @override
  Future<ServerLogsPage> getLogs({
    ServerLogLevel? level,
    int offset = 0,
    int limit = 50,
  }) {
    throw UnimplementedError();
  }
}

final class _PollingBackgroundJobsRepository implements ServerRepository {
  int getCalls = 0;

  @override
  Future<List<BackgroundJob>> getBackgroundJobs() async {
    getCalls += 1;

    if (getCalls == 1) {
      return <BackgroundJob>[_runningJob];
    }

    return <BackgroundJob>[_successfulJob];
  }

  @override
  Future<BackgroundJob> runBackgroundJob(String jobKey) {
    throw UnimplementedError();
  }

  @override
  Future<ServerHealth> getHealth() {
    throw UnimplementedError();
  }

  @override
  Future<ServerLogsPage> getLogs({
    ServerLogLevel? level,
    int offset = 0,
    int limit = 50,
  }) {
    throw UnimplementedError();
  }
}

final class _PollingFailureRepository implements ServerRepository {
  int getCalls = 0;

  @override
  Future<List<BackgroundJob>> getBackgroundJobs() async {
    getCalls += 1;

    if (getCalls == 1) {
      return <BackgroundJob>[_runningJob];
    }

    throw const AppException.connection();
  }

  @override
  Future<BackgroundJob> runBackgroundJob(String jobKey) {
    throw UnimplementedError();
  }

  @override
  Future<ServerHealth> getHealth() {
    throw UnimplementedError();
  }

  @override
  Future<ServerLogsPage> getLogs({
    ServerLogLevel? level,
    int offset = 0,
    int limit = 50,
  }) {
    throw UnimplementedError();
  }
}
