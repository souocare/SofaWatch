import 'package:dio/dio.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/server/data/models/server_health_dto.dart';
import 'package:sofawatch/features/server/domain/models/server_health.dart';
import 'package:sofawatch/features/server/domain/repositories/server_repository.dart';

final class ApiServerRepository implements ServerRepository {
  const ApiServerRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<ServerHealth> getHealth() async {
    try {
      final Response<Map<String, dynamic>> response = await _apiClient
          .get<Map<String, dynamic>>('/server/health');

      final Map<String, dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException(
          'The Server health response body is missing.',
        );
      }

      return ServerHealthDto.fromJson(data).toDomain();
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }
}
