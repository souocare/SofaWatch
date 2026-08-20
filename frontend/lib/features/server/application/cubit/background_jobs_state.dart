import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/server/domain/models/background_job.dart';

sealed class BackgroundJobsState extends Equatable {
  const BackgroundJobsState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class BackgroundJobsInitial extends BackgroundJobsState {
  const BackgroundJobsInitial();
}

final class BackgroundJobsLoading extends BackgroundJobsState {
  const BackgroundJobsLoading();
}

final class BackgroundJobsSuccess extends BackgroundJobsState {
  const BackgroundJobsSuccess({
    required this.jobs,
    this.runningJobKeys = const <String>{},
    this.runFailures = const <String, AppException>{},
  });

  final List<BackgroundJob> jobs;

  final Set<String> runningJobKeys;

  final Map<String, AppException> runFailures;

  BackgroundJobsSuccess copyWith({
    List<BackgroundJob>? jobs,
    Set<String>? runningJobKeys,
    Map<String, AppException>? runFailures,
  }) {
    return BackgroundJobsSuccess(
      jobs: jobs ?? this.jobs,
      runningJobKeys: runningJobKeys ?? this.runningJobKeys,
      runFailures: runFailures ?? this.runFailures,
    );
  }

  bool isRunning(String jobKey) {
    return runningJobKeys.contains(jobKey);
  }

  AppException? runFailure(String jobKey) {
    return runFailures[jobKey];
  }

  @override
  List<Object?> get props => <Object?>[jobs, runningJobKeys, runFailures];
}

final class BackgroundJobsFailure extends BackgroundJobsState {
  const BackgroundJobsFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => <Object?>[error];
}
