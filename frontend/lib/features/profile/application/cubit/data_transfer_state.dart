import 'package:equatable/equatable.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/profile/domain/models/data_import_preview.dart';
import 'package:sofawatch/features/profile/domain/models/data_import_result.dart';
import 'package:sofawatch/features/profile/domain/models/data_import_run.dart';

sealed class DataTransferState extends Equatable {
  const DataTransferState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class DataTransferIdle extends DataTransferState {
  const DataTransferIdle();
}

final class DataTransferExporting extends DataTransferState {
  const DataTransferExporting();
}

final class DataTransferExportReady extends DataTransferState {
  const DataTransferExportReady(this.json);

  final String json;

  @override
  List<Object?> get props => <Object?>[json];
}

final class DataTransferExportFailure extends DataTransferState {
  const DataTransferExportFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => <Object?>[error];
}

final class DataTransferImportPreviewLoading extends DataTransferState {
  const DataTransferImportPreviewLoading({required this.filename});

  final String filename;

  @override
  List<Object?> get props => <Object?>[filename];
}

final class DataTransferImportPreviewReady extends DataTransferState {
  const DataTransferImportPreviewReady({
    required this.filename,
    required this.json,
    required this.preview,
  });

  final String filename;

  /// Kept until the user explicitly confirms the actual import.
  final String json;

  final DataImportPreview preview;

  @override
  List<Object?> get props => <Object?>[filename, json, preview];
}

final class DataTransferImportPreviewFailure extends DataTransferState {
  const DataTransferImportPreviewFailure({
    required this.filename,
    required this.error,
  });

  final String filename;
  final AppException error;

  @override
  List<Object?> get props => <Object?>[filename, error];
}

/// The POST request that creates the persistent import run is in progress.
final class DataTransferImporting extends DataTransferState {
  const DataTransferImporting();
}

/// A persistent import run is queued or running on the backend worker.
final class DataTransferImportInProgress extends DataTransferState {
  const DataTransferImportInProgress(this.run);

  final DataImportRun run;

  @override
  List<Object?> get props => <Object?>[run];
}

/// The import itself is still active, but its latest status could not be read.
///
/// Polling continues so a temporary connection failure does not make the
/// frontend forget an import that is still executing on the server.
final class DataTransferImportStatusFailure extends DataTransferState {
  const DataTransferImportStatusFailure({
    required this.run,
    required this.error,
  });

  final DataImportRun run;
  final AppException error;

  @override
  List<Object?> get props => <Object?>[run, error];
}

/// Looking for a pre-existing active import failed while opening the page.
final class DataTransferImportRecoveryFailure extends DataTransferState {
  const DataTransferImportRecoveryFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => <Object?>[error];
}

final class DataTransferImportSuccess extends DataTransferState {
  const DataTransferImportSuccess(this.result);

  final DataImportResult result;

  @override
  List<Object?> get props => <Object?>[result];
}

/// The persistent backend run itself ended in `failed`.
final class DataTransferImportRunFailure extends DataTransferState {
  const DataTransferImportRunFailure(this.run);

  final DataImportRun run;

  @override
  List<Object?> get props => <Object?>[run];
}

/// Creating the import run failed before the worker could own it.
final class DataTransferImportFailure extends DataTransferState {
  const DataTransferImportFailure(this.error);

  final AppException error;

  @override
  List<Object?> get props => <Object?>[error];
}
