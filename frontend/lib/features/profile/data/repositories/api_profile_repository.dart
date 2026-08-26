import 'package:dio/dio.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/profile/data/models/profile_user_dto.dart';
import 'package:sofawatch/features/profile/domain/models/profile_user.dart';
import 'package:sofawatch/features/profile/domain/repositories/profile_repository.dart';

final class ApiProfileRepository implements ProfileRepository {
  const ApiProfileRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<ProfileUser> getCurrentUser() async {
    try {
      final Response<Map<String, dynamic>> response = await _apiClient
          .get<Map<String, dynamic>>('/users/me');

      return _mapUserResponse(response.data);
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }

  @override
  Future<ProfileUser> updateDisplayName({required String displayName}) async {
    try {
      final Response<Map<String, dynamic>> response = await _apiClient
          .patch<Map<String, dynamic>>(
            '/users/me',
            data: <String, dynamic>{'display_name': displayName},
          );

      return _mapUserResponse(response.data);
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }

  ProfileUser _mapUserResponse(Map<String, dynamic>? data) {
    if (data == null) {
      throw const FormatException('The current user response body is missing.');
    }

    return ProfileUserDto.fromJson(data).toDomain();
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _apiClient.put<void>(
        '/users/me/password',
        data: <String, dynamic>{
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
    } on AppException {
      rethrow;
    }
  }
}
