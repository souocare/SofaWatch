import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/data/models/authentication_response_dto.dart';
import 'package:sofawatch/features/auth/domain/models/auth_session.dart';
import 'package:sofawatch/features/auth/domain/repositories/access_token_store.dart';
import 'package:sofawatch/features/auth/domain/repositories/registration_repository.dart';

final class ApiRegistrationRepository implements RegistrationRepository {
  ApiRegistrationRepository({
    required ApiClient apiClient,
    required AccessTokenStore accessTokenStore,
    bool? isWeb,
  }) : _apiClient = apiClient,
       _accessTokenStore = accessTokenStore,
       _isWeb = isWeb ?? kIsWeb;

  final ApiClient _apiClient;
  final AccessTokenStore _accessTokenStore;
  final bool _isWeb;

  @override
  Future<bool> isRegistrationOpen() async {
    final Response<Map<String, dynamic>> response = await _apiClient
        .get<Map<String, dynamic>>('/auth/registration');

    final Map<String, dynamic>? data = response.data;

    if (data == null || data['open_registration'] is! bool) {
      throw AppException.invalidData(
        originalError: const FormatException(
          'Registration status response is invalid.',
        ),
      );
    }

    return data['open_registration'] as bool;
  }

  @override
  Future<AuthSession> register({
    required String username,
    required String displayName,
    required String password,
    String? email,
  }) async {
    if (!_isWeb) {
      throw UnsupportedError(
        'Public registration is currently supported only on Web.',
      );
    }

    final String normalizedUsername = username.trim();
    final String normalizedDisplayName = displayName.trim();
    final String? normalizedEmail = email?.trim();

    final Response<Map<String, dynamic>> response = await _apiClient
        .post<Map<String, dynamic>>(
          '/auth/register',
          data: <String, dynamic>{
            'username': normalizedUsername,
            'display_name': normalizedDisplayName,
            'password': password,
            if (normalizedEmail != null && normalizedEmail.isNotEmpty)
              'email': normalizedEmail,
          },
        );

    final Map<String, dynamic>? data = response.data;

    if (data == null) {
      throw AppException.invalidData(
        originalError: const FormatException(
          'Registration response body is missing.',
        ),
      );
    }

    late final AuthenticationResponseDto authentication;

    try {
      authentication = AuthenticationResponseDto.fromJson(data);
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }

    _accessTokenStore.save(authentication.accessToken);

    return authentication.toDomain();
  }
}
