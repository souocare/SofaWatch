import 'package:equatable/equatable.dart';

enum BackgroundJobStatus { idle, running, success, failed }

final class BackgroundJobResultSummary extends Equatable {
  const BackgroundJobResultSummary({
    required this.checked,
    required this.refreshed,
    required this.skipped,
    required this.failed,
  });

  final int checked;
  final int refreshed;
  final int skipped;
  final int failed;

  @override
  List<Object?> get props => <Object?>[checked, refreshed, skipped, failed];
}

final class BackgroundJob extends Equatable {
  const BackgroundJob({
    required this.id,
    required this.key,
    required this.name,
    required this.schedule,
    required this.status,
    required this.lastStartedAt,
    required this.lastFinishedAt,
    required this.lastDurationMs,
    required this.lastError,
    required this.nextRunAt,
    required this.lastResult,
  });

  final String id;
  final String key;
  final String name;
  final String schedule;
  final BackgroundJobStatus status;

  final DateTime? lastStartedAt;
  final DateTime? lastFinishedAt;
  final int? lastDurationMs;
  final String? lastError;
  final DateTime? nextRunAt;

  final BackgroundJobResultSummary? lastResult;

  bool get isRunning {
    return status == BackgroundJobStatus.running;
  }

  bool get isHealthy {
    return status == BackgroundJobStatus.idle ||
        status == BackgroundJobStatus.success;
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    key,
    name,
    schedule,
    status,
    lastStartedAt,
    lastFinishedAt,
    lastDurationMs,
    lastError,
    nextRunAt,
    lastResult,
  ];
}
