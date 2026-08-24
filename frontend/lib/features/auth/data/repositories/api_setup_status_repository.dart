import 'package:dio/dio.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/data/models/setup_status_dto.dart';
import 'package:sofawatch/features/auth/domain/models/setup_status.dart';
import 'package:sofawatch/features/auth/domain/repositories/setup_status_repository.dart';

final class ApiSetupStatusRepository implements SetupStatusRepository {
  const ApiSetupStatusRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<SetupStatus> getStatus() async {
    try {
      final Response<Map<String, dynamic>> response = await _apiClient
          .get<Map<String, dynamic>>('/auth/setup');

      final Map<String, dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException(
          'The setup status response body is missing.',
        );
      }

      return SetupStatusDto.fromJson(data).toDomain();
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }
}
