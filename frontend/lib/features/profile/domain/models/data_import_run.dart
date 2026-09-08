import 'package:equatable/equatable.dart';
import 'package:sofawatch/features/profile/domain/models/data_import_result.dart';

enum DataImportRunStatus {
  queued,
  running,
  completed,
  failed;

  bool get isActive => this == queued || this == running;

  bool get isTerminal => this == completed || this == failed;
}

enum DataImportPhase {
  queued,
  libraryShows,
  libraryMovies,
  historyEpisodes,
  historyMovies,
  finalizing,
}

final class DataImportRun extends Equatable {
  const DataImportRun({
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

  final String id;
  final DataImportRunStatus status;
  final DataImportPhase phase;

  /// Number of processed items in the current phase.
  final int progressCurrent;

  /// Total number of items in the current phase.
  final int progressTotal;

  /// Present only when the import completed successfully.
  final DataImportResult? result;

  /// Safe backend error code for terminal failed imports.
  final String? errorCode;

  /// Safe backend error message for terminal failed imports.
  final String? errorMessage;

  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  bool get isActive => status.isActive;

  bool get isTerminal => status.isTerminal;

  bool get hasDeterminateProgress => progressTotal > 0;

  double? get progressFraction {
    if (!hasDeterminateProgress) {
      return null;
    }

    return (progressCurrent / progressTotal).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    status,
    phase,
    progressCurrent,
    progressTotal,
    result,
    errorCode,
    errorMessage,
    createdAt,
    startedAt,
    finishedAt,
  ];
}
