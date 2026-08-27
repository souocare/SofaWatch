import 'package:dio/dio.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/history/data/models/history_page_dto.dart';
import 'package:sofawatch/features/history/data/models/history_preview_dto.dart';
import 'package:sofawatch/features/history/domain/models/history_page.dart';
import 'package:sofawatch/features/history/domain/models/history_preview.dart';
import 'package:sofawatch/features/history/domain/repositories/history_repository.dart';

final class ApiHistoryRepository implements HistoryRepository {
  const ApiHistoryRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<HistoryPreview> getPreview() async {
    try {
      final Response<Map<String, dynamic>> response = await _apiClient
          .get<Map<String, dynamic>>('/library/history/preview');

      final Map<String, dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException(
          'The History preview response body is missing.',
        );
      }

      return HistoryPreviewDto.fromJson(data).toDomain(resolveUrl: _resolveUrl);
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }

  @override
  Future<HistoryPage> getHistory({int limit = 30, String? cursor}) async {
    try {
      final Response<Map<String, dynamic>> response = await _apiClient
          .get<Map<String, dynamic>>(
            '/library/history',
            queryParameters: <String, dynamic>{
              'limit': limit,
              'cursor': ?cursor,
            },
          );

      final Map<String, dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException('The History response body is missing.');
      }

      return HistoryPageDto.fromJson(data).toDomain(resolveUrl: _resolveUrl);
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }

  String _resolveUrl(String path) {
    return _apiClient.resolveServerUrl(path) ?? path;
  }
}
