import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/profile/data/models/data_import_preview_dto.dart';
import 'package:sofawatch/features/profile/data/models/data_import_result_dto.dart';
import 'package:sofawatch/features/profile/domain/models/data_import_preview.dart';
import 'package:sofawatch/features/profile/domain/models/data_import_result.dart';
import 'package:sofawatch/features/profile/domain/repositories/data_transfer_repository.dart';

final class ApiDataTransferRepository implements DataTransferRepository {
  const ApiDataTransferRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<String> exportData() async {
    try {
      final Response<String> response = await _apiClient.get<String>(
        '/users/me/export',
        options: Options(responseType: ResponseType.plain),
      );

      final String? data = response.data;

      if (data == null || data.trim().isEmpty) {
        throw const FormatException('The export response body is missing.');
      }

      return data;
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on Object catch (error) {
      throw AppException.unknown(originalError: error);
    }
  }

  @override
  Future<DataImportPreview> previewImport(String json) async {
    try {
      final Object? decoded = jsonDecode(json);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          'The selected file does not contain a valid SofaWatch export.',
        );
      }

      final Response<Map<String, dynamic>> response = await _apiClient
          .post<Map<String, dynamic>>(
            '/users/me/import/preview',
            data: decoded,
          );

      final Map<String, dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException(
          'The import preview response body is missing.',
        );
      }

      return DataImportPreviewDto.fromJson(data).toDomain();
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    } on Object catch (error) {
      throw AppException.unknown(originalError: error);
    }
  }

  @override
  Future<DataImportResult> importData(String json) async {
    try {
      final Object? decoded = jsonDecode(json);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          'The import file must contain a JSON object.',
        );
      }

      final Response<Map<String, dynamic>> response = await _apiClient
          .post<Map<String, dynamic>>('/users/me/import', data: decoded);

      final Map<String, dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException('The import response body is missing.');
      }

      return DataImportResultDto.fromJson(data).toDomain();
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    } on Object catch (error) {
      throw AppException.unknown(originalError: error);
    }
  }
}
