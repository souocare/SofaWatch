import 'package:sofawatch/features/profile/domain/models/data_import_preview.dart';
import 'package:sofawatch/features/profile/domain/models/data_import_run.dart';

abstract interface class DataTransferRepository {
  Future<String> exportData();

  Future<DataImportPreview> previewImport(String json);

  Future<DataImportRun> importData(String json);

  Future<DataImportRun?> getActiveImport();

  Future<DataImportRun> getImportRun(String id);
}
