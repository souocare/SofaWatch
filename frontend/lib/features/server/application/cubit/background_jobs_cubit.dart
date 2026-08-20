import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/server/application/cubit/background_jobs_state.dart';
import 'package:sofawatch/features/server/domain/models/background_job.dart';
import 'package:sofawatch/features/server/domain/repositories/server_repository.dart';

final class BackgroundJobsCubit extends Cubit<BackgroundJobsState> {
  BackgroundJobsCubit({
    required ServerRepository repository,
    Duration pollingInterval = const Duration(seconds: 3),
  }) : _repository = repository,
       _pollingInterval = pollingInterval,
       super(const BackgroundJobsInitial());

  final ServerRepository _repository;
  final Duration _pollingInterval;

  Timer? _pollingTimer;

  Future<void> load() async {
    if (state is BackgroundJobsLoading) {
      return;
    }

    emit(const BackgroundJobsLoading());

    try {
      final List<BackgroundJob> jobs = await _repository.getBackgroundJobs();

      if (isClosed) {
        return;
      }

      emit(BackgroundJobsSuccess(jobs: jobs));

      _updatePolling(jobs);
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      _stopPolling();

      emit(BackgroundJobsFailure(error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      _stopPolling();

      emit(BackgroundJobsFailure(AppException.unknown(originalError: error)));
    }
  }

  Future<void> retry() {
    return load();
  }

  Future<void> runNow(String jobKey) async {
    final BackgroundJobsState currentState = state;

    if (currentState is! BackgroundJobsSuccess) {
      return;
    }

    if (currentState.isRunning(jobKey)) {
      return;
    }

    final BackgroundJob? currentJob = _findJob(currentState.jobs, jobKey);

    if (currentJob == null || currentJob.isRunning) {
      return;
    }

    final Set<String> runningJobKeys = Set<String>.from(
      currentState.runningJobKeys,
    )..add(jobKey);

    final Map<String, AppException> runFailures =
        Map<String, AppException>.from(currentState.runFailures)
          ..remove(jobKey);

    emit(
      currentState.copyWith(
        runningJobKeys: runningJobKeys,
        runFailures: runFailures,
      ),
    );

    try {
      final BackgroundJob updatedJob = await _repository.runBackgroundJob(
        jobKey,
      );

      if (isClosed) {
        return;
      }

      final BackgroundJobsState latestState = state;

      if (latestState is! BackgroundJobsSuccess) {
        return;
      }

      final List<BackgroundJob> jobs = _replaceJob(
        latestState.jobs,
        updatedJob,
      );

      final Set<String> updatedRunningKeys = Set<String>.from(
        latestState.runningJobKeys,
      )..remove(jobKey);

      emit(
        latestState.copyWith(jobs: jobs, runningJobKeys: updatedRunningKeys),
      );

      _updatePolling(jobs);
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      _emitRunFailure(jobKey: jobKey, error: error);
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      _emitRunFailure(
        jobKey: jobKey,
        error: AppException.unknown(originalError: error),
      );
    }
  }

  Future<void> refresh() async {
    final BackgroundJobsState currentState = state;

    if (currentState is! BackgroundJobsSuccess) {
      return;
    }

    try {
      final List<BackgroundJob> jobs = await _repository.getBackgroundJobs();

      if (isClosed) {
        return;
      }

      final BackgroundJobsState latestState = state;

      if (latestState is! BackgroundJobsSuccess) {
        return;
      }

      emit(latestState.copyWith(jobs: jobs));

      _updatePolling(jobs);
    } on Object {
      // Polling refresh failures should not replace usable job data.
    }
  }

  void _emitRunFailure({required String jobKey, required AppException error}) {
    final BackgroundJobsState currentState = state;

    if (currentState is! BackgroundJobsSuccess) {
      return;
    }

    final Set<String> runningJobKeys = Set<String>.from(
      currentState.runningJobKeys,
    )..remove(jobKey);

    final Map<String, AppException> runFailures =
        Map<String, AppException>.from(currentState.runFailures)
          ..[jobKey] = error;

    emit(
      currentState.copyWith(
        runningJobKeys: runningJobKeys,
        runFailures: runFailures,
      ),
    );
  }

  void _updatePolling(List<BackgroundJob> jobs) {
    final bool hasRunningJob = jobs.any((BackgroundJob job) => job.isRunning);

    if (!hasRunningJob) {
      _stopPolling();
      return;
    }

    if (_pollingTimer?.isActive ?? false) {
      return;
    }

    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      unawaited(refresh());
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  static BackgroundJob? _findJob(List<BackgroundJob> jobs, String jobKey) {
    for (final BackgroundJob job in jobs) {
      if (job.key == jobKey) {
        return job;
      }
    }

    return null;
  }

  static List<BackgroundJob> _replaceJob(
    List<BackgroundJob> jobs,
    BackgroundJob updatedJob,
  ) {
    return jobs
        .map(
          (BackgroundJob job) => job.key == updatedJob.key ? updatedJob : job,
        )
        .toList(growable: false);
  }

  @override
  Future<void> close() async {
    _stopPolling();

    return super.close();
  }
}
