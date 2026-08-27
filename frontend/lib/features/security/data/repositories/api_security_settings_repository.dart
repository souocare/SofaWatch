import 'package:dio/dio.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/security/data/models/security_settings_dto.dart';
import 'package:sofawatch/features/security/domain/models/security_settings.dart';
import 'package:sofawatch/features/security/domain/repositories/security_settings_repository.dart';

final class ApiSecuritySettingsRepository
    implements SecuritySettingsRepository {
  const ApiSecuritySettingsRepository({required this._apiClient});

  final ApiClient _apiClient;

  @override
  Future<SecuritySettings> getSettings() async {
    try {
      final Response<Map<String, dynamic>> response = await _apiClient
          .get<Map<String, dynamic>>('/security');

      final Map<String, dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException(
          'Security settings response body is missing.',
        );
      }

      return SecuritySettingsDto.fromJson(data).toDomain();
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }

  @override
  Future<SecuritySettings> updateOpenRegistration({
    required bool enabled,
  }) async {
    try {
      final Response<Map<String, dynamic>> response = await _apiClient
          .patch<Map<String, dynamic>>(
            '/security',
            data: <String, dynamic>{'open_registration': enabled},
          );

      final Map<String, dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException(
          'Security settings response body is missing.',
        );
      }

      return SecuritySettingsDto.fromJson(data).toDomain();
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }
}
