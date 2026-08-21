import 'package:sofawatch/features/profile/domain/models/data_import_preview.dart';
import 'package:sofawatch/features/profile/domain/models/data_import_result.dart';

abstract interface class DataTransferRepository {
  Future<String> exportData();

  Future<DataImportPreview> previewImport(String json);

  Future<DataImportResult> importData(String json);
}
