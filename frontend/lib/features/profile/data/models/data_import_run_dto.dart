import 'package:sofawatch/features/profile/data/models/data_import_result_dto.dart';
import 'package:sofawatch/features/profile/domain/models/data_import_run.dart';
import 'package:sofawatch/features/profile/domain/models/data_import_result.dart';

final class DataImportRunDto {
  const DataImportRunDto({
    required this.id,
    required this.status,
    required this.phase,
    required this.progressCurrent,
    required this.progressTotal,
    required this.result,
    required this.errorCode,
    required this.errorMessage,
    required this.createdAt,
    required this.startedAt,
    required this.finishedAt,
  });

  factory DataImportRunDto.fromJson(Map<String, dynamic> json) {
    final Object? resultJson = json['result'];

    return DataImportRunDto(
      id: json['id'] as String,
      status: _parseStatus(json['status'] as String),
      phase: _parsePhase(json['phase'] as String),
      progressCurrent: json['progress_current'] as int,
      progressTotal: json['progress_total'] as int,
      result: switch (resultJson) {
        null => null,
        final Map<String, dynamic> value => DataImportResultDto.fromJson(
          value,
        ).toDomain(),
        _ => throw const FormatException(
          'The data import result has an invalid format.',
        ),
      },
      errorCode: json['error_code'] as String?,
      errorMessage: json['error_message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      startedAt: _parseNullableDateTime(json['started_at']),
      finishedAt: _parseNullableDateTime(json['finished_at']),
    );
  }

  final String id;
  final DataImportRunStatus status;
  final DataImportPhase phase;
  final int progressCurrent;
  final int progressTotal;
  final DataImportResult? result;
  final String? errorCode;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  DataImportRun toDomain() {
    return DataImportRun(
      id: id,
      status: status,
      phase: phase,
      progressCurrent: progressCurrent,
      progressTotal: progressTotal,
      result: result,
      errorCode: errorCode,
      errorMessage: errorMessage,
      createdAt: createdAt,
      startedAt: startedAt,
      finishedAt: finishedAt,
    );
  }

  static DateTime? _parseNullableDateTime(Object? value) {
    return switch (value) {
      null => null,
      final String text => DateTime.parse(text),
      _ => throw const FormatException(
        'The data import timestamp has an invalid format.',
      ),
    };
  }

  static DataImportRunStatus _parseStatus(String value) {
    return switch (value) {
      'queued' => DataImportRunStatus.queued,
      'running' => DataImportRunStatus.running,
      'completed' => DataImportRunStatus.completed,
      'failed' => DataImportRunStatus.failed,
      _ => throw FormatException('Unsupported data import status: $value'),
    };
  }

  static DataImportPhase _parsePhase(String value) {
    return switch (value) {
      'queued' => DataImportPhase.queued,
      'library_shows' => DataImportPhase.libraryShows,
      'library_movies' => DataImportPhase.libraryMovies,
      'history_episodes' => DataImportPhase.historyEpisodes,
      'history_movies' => DataImportPhase.historyMovies,
      'finalizing' => DataImportPhase.finalizing,
      _ => throw FormatException('Unsupported data import phase: $value'),
    };
  }
}
