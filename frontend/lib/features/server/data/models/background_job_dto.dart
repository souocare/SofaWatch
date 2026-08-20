import 'package:sofawatch/features/server/domain/models/background_job.dart';

final class BackgroundJobDto {
  const BackgroundJobDto({
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

  factory BackgroundJobDto.fromJson(Map<String, dynamic> json) {
    return BackgroundJobDto(
      id: _requiredString(json, 'id'),
      key: _requiredString(json, 'key'),
      name: _requiredString(json, 'name'),
      schedule: _requiredString(json, 'schedule'),
      status: _parseBackgroundJobStatus(_requiredString(json, 'status')),
      lastStartedAt: _optionalDateTime(
        json['last_started_at'],
        fieldName: 'last_started_at',
      ),
      lastFinishedAt: _optionalDateTime(
        json['last_finished_at'],
        fieldName: 'last_finished_at',
      ),
      lastDurationMs: _optionalNonNegativeInt(
        json['last_duration_ms'],
        fieldName: 'last_duration_ms',
      ),
      lastError: _optionalString(json['last_error'], fieldName: 'last_error'),
      nextRunAt: _optionalDateTime(
        json['next_run_at'],
        fieldName: 'next_run_at',
      ),
      lastResult: _optionalResultSummary(json['last_result']),
    );
  }

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

  final BackgroundJobResultSummaryDto? lastResult;

  BackgroundJob toDomain() {
    return BackgroundJob(
      id: id,
      key: key,
      name: name,
      schedule: schedule,
      status: status,
      lastStartedAt: lastStartedAt,
      lastFinishedAt: lastFinishedAt,
      lastDurationMs: lastDurationMs,
      lastError: lastError,
      nextRunAt: nextRunAt,
      lastResult: lastResult?.toDomain(),
    );
  }
}

final class BackgroundJobResultSummaryDto {
  const BackgroundJobResultSummaryDto({
    required this.checked,
    required this.refreshed,
    required this.skipped,
    required this.failed,
  });

  factory BackgroundJobResultSummaryDto.fromJson(Map<String, dynamic> json) {
    return BackgroundJobResultSummaryDto(
      checked: _requiredNonNegativeInt(json, 'checked'),
      refreshed: _requiredNonNegativeInt(json, 'refreshed'),
      skipped: _requiredNonNegativeInt(json, 'skipped'),
      failed: _requiredNonNegativeInt(json, 'failed'),
    );
  }

  final int checked;
  final int refreshed;
  final int skipped;
  final int failed;

  BackgroundJobResultSummary toDomain() {
    return BackgroundJobResultSummary(
      checked: checked,
      refreshed: refreshed,
      skipped: skipped,
      failed: failed,
    );
  }
}

BackgroundJobResultSummaryDto? _optionalResultSummary(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is! Map<String, dynamic>) {
    throw const FormatException('Invalid last_result.');
  }

  return BackgroundJobResultSummaryDto.fromJson(value);
}

String _requiredString(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Invalid $key.');
  }

  return value.trim();
}

String? _optionalString(Object? value, {required String fieldName}) {
  if (value == null) {
    return null;
  }

  if (value is! String) {
    throw FormatException('Invalid $fieldName.');
  }

  final String normalized = value.trim();

  return normalized.isEmpty ? null : normalized;
}

int _requiredNonNegativeInt(Map<String, dynamic> json, String key) {
  final Object? value = json[key];

  if (value is! int || value < 0) {
    throw FormatException('Invalid $key.');
  }

  return value;
}

int? _optionalNonNegativeInt(Object? value, {required String fieldName}) {
  if (value == null) {
    return null;
  }

  if (value is! int || value < 0) {
    throw FormatException('Invalid $fieldName.');
  }

  return value;
}

DateTime? _optionalDateTime(Object? value, {required String fieldName}) {
  if (value == null) {
    return null;
  }

  if (value is! String) {
    throw FormatException('Invalid $fieldName.');
  }

  final DateTime? parsed = DateTime.tryParse(value);

  if (parsed == null) {
    throw FormatException('Invalid $fieldName.');
  }

  return parsed;
}

BackgroundJobStatus _parseBackgroundJobStatus(String value) {
  return switch (value) {
    'idle' => BackgroundJobStatus.idle,
    'running' => BackgroundJobStatus.running,
    'success' => BackgroundJobStatus.success,
    'failed' => BackgroundJobStatus.failed,
    _ => throw FormatException('Invalid background job status: $value.'),
  };
}
