import 'package:dio/dio.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/admin_users/data/models/admin_user_dto.dart';
import 'package:sofawatch/features/admin_users/data/models/admin_users_summary_dto.dart';
import 'package:sofawatch/features/admin_users/data/models/password_recovery_link_dto.dart';
import 'package:sofawatch/features/admin_users/domain/models/admin_user.dart';
import 'package:sofawatch/features/admin_users/domain/models/admin_users_summary.dart';
import 'package:sofawatch/features/admin_users/domain/models/password_recovery_link.dart';
import 'package:sofawatch/features/admin_users/domain/repositories/admin_users_repository.dart';

final class ApiAdminUsersRepository implements AdminUsersRepository {
  const ApiAdminUsersRepository({required this._apiClient});

  final ApiClient _apiClient;

  @override
  Future<PasswordRecoveryLink> startPasswordRecovery({
    required String userId,
  }) async {
    final String normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'User id cannot be empty.');
    }

    try {
      final Response<Map<String, dynamic>> response = await _apiClient
          .post<Map<String, dynamic>>(
            '/users/$normalizedUserId/password-recovery',
          );

      final Map<String, dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException(
          'Password recovery response body is missing.',
        );
      }

      return PasswordRecoveryLinkDto.fromJson(data).toDomain();
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }

  @override
  Future<List<AdminUser>> listUsers() async {
    try {
      final Response<List<dynamic>> response = await _apiClient
          .get<List<dynamic>>('/users');

      final List<dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException('Users response body is missing.');
      }

      return data
          .map((dynamic item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException(
                'Users response contains an invalid item.',
              );
            }

            return AdminUserDto.fromJson(item).toDomain();
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
  Future<AdminUsersSummary> getSummary() async {
    try {
      final Response<Map<String, dynamic>> response = await _apiClient
          .get<Map<String, dynamic>>('/users/summary');

      final Map<String, dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException('Users summary response body is missing.');
      }

      return AdminUsersSummaryDto.fromJson(data).toDomain();
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }
}
