import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/data/models/authentication_response_dto.dart';
import 'package:sofawatch/features/auth/domain/models/auth_session.dart';
import 'package:sofawatch/features/auth/domain/repositories/access_token_store.dart';
import 'package:sofawatch/features/auth/domain/repositories/auth_repository.dart';
import 'package:sofawatch/features/auth/domain/repositories/mobile_refresh_token_store.dart';

final class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({
    required this._apiClient,
    required this._accessTokenStore,
    this._mobileRefreshTokenStore,
    bool? isWeb,
  }) : _isWeb = isWeb ?? kIsWeb;

  final ApiClient _apiClient;
  final AccessTokenStore _accessTokenStore;
  final MobileRefreshTokenStore? _mobileRefreshTokenStore;
  final bool _isWeb;

  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final String normalizedUsername = username.trim();

    if (normalizedUsername.isEmpty) {
      throw ArgumentError.value(
        username,
        'username',
        'Username cannot be empty.',
      );
    }

    if (password.isEmpty) {
      throw ArgumentError.value(
        password,
        'password',
        'Password cannot be empty.',
      );
    }

    final AuthenticationResponseDto response = await _authenticate(
      path: _isWeb ? '/auth/login' : '/auth/mobile/login',
      data: <String, dynamic>{
        'username': normalizedUsername,
        'password': password,
      },
    );

    return _persistAuthentication(response, requireRefreshToken: !_isWeb);
  }

  @override
  Future<AuthSession?> restore() async {
    if (_isWeb) {
      final AuthenticationResponseDto response = await _authenticate(
        path: '/auth/session',
      );

      return _persistAuthentication(response, requireRefreshToken: false);
    }

    final MobileRefreshTokenStore refreshTokenStore =
        _requireMobileRefreshTokenStore();

    final String? refreshToken = await refreshTokenStore.read();

    if (refreshToken == null) {
      _accessTokenStore.clear();

      return null;
    }

    final AuthenticationResponseDto response = await _authenticate(
      path: '/auth/refresh',
      data: <String, dynamic>{'refresh_token': refreshToken},
    );

    return _persistAuthentication(response, requireRefreshToken: true);
  }

  Future<AuthenticationResponseDto> _authenticate({
    required String path,
    Map<String, dynamic>? data,
  }) async {
    try {
      final Response<Map<String, dynamic>> response = await _apiClient
          .post<Map<String, dynamic>>(path, data: data);

      final Map<String, dynamic>? responseData = response.data;

      if (responseData == null) {
        throw const FormatException('Authentication response body is missing.');
      }

      return AuthenticationResponseDto.fromJson(responseData);
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }

  Future<AuthSession> _persistAuthentication(
    AuthenticationResponseDto response, {
    required bool requireRefreshToken,
  }) async {
    final String? refreshToken = response.refreshToken;

    if (requireRefreshToken && refreshToken == null) {
      throw AppException.invalidData(
        originalError: const FormatException(
          'Mobile authentication response is missing a refresh token.',
        ),
      );
    }

    if (refreshToken != null) {
      final MobileRefreshTokenStore refreshTokenStore =
          _requireMobileRefreshTokenStore();

      await refreshTokenStore.save(refreshToken);
    }

    _accessTokenStore.save(response.accessToken);

    return response.toDomain();
  }

  MobileRefreshTokenStore _requireMobileRefreshTokenStore() {
    final MobileRefreshTokenStore? store = _mobileRefreshTokenStore;

    if (store == null) {
      throw StateError('Mobile refresh-token storage is not configured.');
    }

    return store;
  }

  @override
  Future<void> logout() async {
    try {
      if (_isWeb) {
        await _apiClient.post<void>('/auth/logout');

        _accessTokenStore.clear();

        return;
      }

      final MobileRefreshTokenStore refreshTokenStore =
          _requireMobileRefreshTokenStore();

      final String? refreshToken = await refreshTokenStore.read();

      try {
        if (refreshToken != null) {
          await _apiClient.post<void>(
            '/auth/mobile/logout',
            data: <String, dynamic>{'refresh_token': refreshToken},
          );
        }
      } finally {
        _accessTokenStore.clear();
        await refreshTokenStore.clear();
      }
    } on AppException {
      if (_isWeb) {
        _accessTokenStore.clear();
      }

      rethrow;
    }
  }

  @override
  Future<void> logoutEverywhere() async {
    try {
      await _apiClient.post<void>('/auth/logout-all');
    } finally {
      _accessTokenStore.clear();

      if (!_isWeb) {
        await _requireMobileRefreshTokenStore().clear();
      }
    }
  }
}
