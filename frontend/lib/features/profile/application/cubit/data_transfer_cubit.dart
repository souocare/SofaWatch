import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/profile/application/cubit/data_transfer_state.dart';
import 'package:sofawatch/features/profile/domain/models/data_import_preview.dart';
import 'package:sofawatch/features/profile/domain/repositories/data_transfer_repository.dart';
import 'package:sofawatch/features/profile/domain/models/data_import_result.dart';

final class DataTransferCubit extends Cubit<DataTransferState> {
  DataTransferCubit({required DataTransferRepository repository})
    : _repository = repository,
      super(const DataTransferIdle());

  final DataTransferRepository _repository;

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
    if (state is DataTransferImportPreviewLoading) {
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

  void reset() {
    if (state is DataTransferIdle) {
      return;
    }

    emit(const DataTransferIdle());
  }

  Future<void> importData(String json) async {
    if (state is DataTransferImporting) {
      return;
    }

    emit(const DataTransferImporting());

    try {
      final DataImportResult result = await _repository.importData(json);

      if (isClosed) {
        return;
      }

      emit(DataTransferImportSuccess(result));
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
}
