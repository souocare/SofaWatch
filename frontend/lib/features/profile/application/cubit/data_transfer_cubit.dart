import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/profile/application/cubit/data_transfer_state.dart';
import 'package:sofawatch/features/profile/domain/models/data_import_preview.dart';
import 'package:sofawatch/features/profile/domain/models/data_import_run.dart';
import 'package:sofawatch/features/profile/domain/repositories/data_transfer_repository.dart';

final class DataTransferCubit extends Cubit<DataTransferState> {
  DataTransferCubit({
    required DataTransferRepository repository,
    Duration importPollInterval = const Duration(seconds: 2),
  }) : _repository = repository,
       _importPollInterval = importPollInterval,
       super(const DataTransferIdle());

  final DataTransferRepository _repository;
  final Duration _importPollInterval;

  Timer? _importPollTimer;
  DataImportRun? _activeImportRun;
  String? _polledRunId;
  bool _statusRequestInFlight = false;

  Future<void> exportData() async {
    if (state is DataTransferExporting) {
      return;
    }

    emit(const DataTransferExporting());

    try {
      final String json = await _repository.exportData();

      if (isClosed) {
        return;
      }

      emit(DataTransferExportReady(json));
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(DataTransferExportFailure(error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        DataTransferExportFailure(AppException.unknown(originalError: error)),
      );
    }
  }

  Future<void> previewImport({
    required String filename,
    required String json,
  }) async {
    if (state is DataTransferImportPreviewLoading ||
        _hasActiveImportState(state)) {
      return;
    }

    emit(DataTransferImportPreviewLoading(filename: filename));

    try {
      final DataImportPreview preview = await _repository.previewImport(json);

      if (isClosed) {
        return;
      }

      emit(
        DataTransferImportPreviewReady(
          filename: filename,
          json: json,
          preview: preview,
        ),
      );
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(DataTransferImportPreviewFailure(filename: filename, error: error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        DataTransferImportPreviewFailure(
          filename: filename,
          error: AppException.unknown(originalError: error),
        ),
      );
    }
  }

  /// Restores an import that survived a page reload or navigation cycle.
  Future<void> resumeActiveImport() async {
    if (_hasActiveImportState(state)) {
      return;
    }

    try {
      final DataImportRun? run = await _repository.getActiveImport();

      if (isClosed || run == null) {
        return;
      }

      _handleImportRun(run);
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(DataTransferImportRecoveryFailure(error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        DataTransferImportRecoveryFailure(
          AppException.unknown(originalError: error),
        ),
      );
    }
  }

  Future<void> importData(String json) async {
    if (_hasActiveImportState(state)) {
      return;
    }

    emit(const DataTransferImporting());

    try {
      final DataImportRun run = await _repository.importData(json);

      if (isClosed) {
        return;
      }

      _handleImportRun(run);
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      emit(DataTransferImportFailure(error));
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      emit(
        DataTransferImportFailure(AppException.unknown(originalError: error)),
      );
    }
  }

  /// Refreshes the currently tracked persistent import run.
  ///
  /// The periodic poller uses this method, and keeping it explicit also gives
  /// the presentation layer a safe way to request a refresh when needed.
  Future<void> refreshActiveImport() async {
    final DataImportRun? activeRun = _activeImportRun;

    if (activeRun == null || _statusRequestInFlight || isClosed) {
      return;
    }

    _statusRequestInFlight = true;

    try {
      final DataImportRun run = await _repository.getImportRun(activeRun.id);

      if (isClosed) {
        return;
      }

      _handleImportRun(run);
    } on AppException catch (error) {
      if (isClosed) {
        return;
      }

      final DataImportRun? currentRun = _activeImportRun;

      if (currentRun != null) {
        emit(DataTransferImportStatusFailure(run: currentRun, error: error));
      }
    } on Object catch (error) {
      if (isClosed) {
        return;
      }

      final DataImportRun? currentRun = _activeImportRun;

      if (currentRun != null) {
        emit(
          DataTransferImportStatusFailure(
            run: currentRun,
            error: AppException.unknown(originalError: error),
          ),
        );
      }
    } finally {
      _statusRequestInFlight = false;
    }
  }

  void reset() {
    if (state is DataTransferIdle || _hasActiveImportState(state)) {
      return;
    }

    _stopImportPolling();
    emit(const DataTransferIdle());
  }

  void _handleImportRun(DataImportRun run) {
    switch (run.status) {
      case DataImportRunStatus.queued:
      case DataImportRunStatus.running:
        _activeImportRun = run;

        emit(DataTransferImportInProgress(run));
        _startImportPolling(run.id);

      case DataImportRunStatus.completed:
        _stopImportPolling();

        final result = run.result;

        if (result == null) {
          emit(DataTransferImportFailure(const AppException.invalidData()));
          return;
        }

        emit(DataTransferImportSuccess(result));

      case DataImportRunStatus.failed:
        _stopImportPolling();
        emit(DataTransferImportRunFailure(run));
    }
  }

  void _startImportPolling(String runId) {
    if (_importPollTimer?.isActive ?? false) {
      if (_polledRunId == runId) {
        return;
      }

      _importPollTimer?.cancel();
    }

    _polledRunId = runId;

    _importPollTimer = Timer.periodic(_importPollInterval, (_) {
      unawaited(refreshActiveImport());
    });
  }

  void _stopImportPolling() {
    _importPollTimer?.cancel();
    _importPollTimer = null;
    _polledRunId = null;
    _activeImportRun = null;
  }

  bool _hasActiveImportState(DataTransferState currentState) {
    return currentState is DataTransferImporting ||
        currentState is DataTransferImportInProgress ||
        currentState is DataTransferImportStatusFailure;
  }

  @override
  Future<void> close() async {
    _stopImportPolling();
    await super.close();
  }
}
