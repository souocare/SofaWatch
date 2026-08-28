import 'package:dio/dio.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/server/data/models/background_job_dto.dart';
import 'package:sofawatch/features/server/data/models/server_health_dto.dart';
import 'package:sofawatch/features/server/data/models/server_logs_dto.dart';
import 'package:sofawatch/features/server/domain/models/background_job.dart';
import 'package:sofawatch/features/server/domain/models/server_health.dart';
import 'package:sofawatch/features/server/domain/models/server_logs.dart';
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

  @override
  Future<List<BackgroundJob>> getBackgroundJobs() async {
    try {
      final Response<List<dynamic>> response = await _apiClient
          .get<List<dynamic>>('/background-jobs');

      final List<dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException(
          'The background jobs response body is missing.',
        );
      }

      return data
          .map((dynamic item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('Invalid background job.');
            }

            return BackgroundJobDto.fromJson(item).toDomain();
          })
          .toList(growable: false);
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }

  @override
  Future<BackgroundJob> runBackgroundJob(
    String jobKey, {
    bool force = false,
  }) async {
    try {
      final String normalizedJobKey = jobKey.trim();

      if (normalizedJobKey.isEmpty) {
        throw const FormatException('The background job key is missing.');
      }

      final Response<Map<String, dynamic>> response = await _apiClient
          .post<Map<String, dynamic>>(
            '/background-jobs/$normalizedJobKey/run',
            queryParameters: force
                ? const <String, dynamic>{'force': true}
                : null,
          );

      final Map<String, dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException(
          'The background job run response body is missing.',
        );
      }

      final Object? rawJob = data['job'];

      if (rawJob is! Map<String, dynamic>) {
        throw const FormatException('Invalid background job run response.');
      }

      return BackgroundJobDto.fromJson(rawJob).toDomain();
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }

  @override
  Future<ServerLogsPage> getLogs({
    ServerLogLevel? level,
    int offset = 0,
    int limit = 50,
  }) async {
    try {
      if (offset < 0) {
        throw const FormatException(
          'The Server Logs offset cannot be negative.',
        );
      }

      if (limit <= 0 || limit > 200) {
        throw const FormatException('The Server Logs limit is invalid.');
      }

      final Map<String, dynamic> queryParameters = <String, dynamic>{
        'offset': offset,
        'limit': limit,
      };

      if (level != null) {
        queryParameters['level'] = _serverLogLevelApiValue(level);
      }

      final Response<Map<String, dynamic>> response = await _apiClient
          .get<Map<String, dynamic>>(
            '/server/logs',
            queryParameters: queryParameters,
          );

      final Map<String, dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException(
          'The Server Logs response body is missing.',
        );
      }

      return ServerLogsPageDto.fromJson(data).toDomain();
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }
}

String _serverLogLevelApiValue(ServerLogLevel level) {
  return switch (level) {
    ServerLogLevel.debug => 'DEBUG',
    ServerLogLevel.info => 'INFO',
    ServerLogLevel.warning => 'WARNING',
    ServerLogLevel.error => 'ERROR',
    ServerLogLevel.critical => 'CRITICAL',
  };
}
