import 'package:dio/dio.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/data/models/auth_handoff_response_dto.dart';
import 'package:sofawatch/features/auth/data/models/authentication_response_dto.dart';
import 'package:sofawatch/features/auth/domain/models/auth_handoff.dart';
import 'package:sofawatch/features/auth/domain/models/auth_session.dart';
import 'package:sofawatch/features/auth/domain/repositories/access_token_store.dart';
import 'package:sofawatch/features/auth/domain/repositories/auth_handoff_repository.dart';

final class ApiAuthHandoffRepository implements AuthHandoffRepository {
  const ApiAuthHandoffRepository({
    required this._apiClient,
    required this._accessTokenStore,
  });

  final ApiClient _apiClient;
  final AccessTokenStore _accessTokenStore;

  @override
  Future<AuthHandoff> create() async {
    try {
      final Response<Map<String, dynamic>> response = await _apiClient
          .post<Map<String, dynamic>>('/auth/handoff');

      final Map<String, dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException(
          'Authentication handoff response body is missing.',
        );
      }

      return AuthHandoffResponseDto.fromJson(data).toDomain();
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }

  @override
  Future<AuthSession> exchange(String token) async {
    final String normalizedToken = token.trim();

    if (normalizedToken.isEmpty) {
      throw ArgumentError.value(
        token,
        'token',
        'Authentication handoff token cannot be empty.',
      );
    }

    try {
      final Response<Map<String, dynamic>> response = await _apiClient
          .post<Map<String, dynamic>>(
            '/auth/handoff/exchange',
            data: <String, dynamic>{'handoff_token': normalizedToken},
          );

      final Map<String, dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException(
          'Authentication handoff exchange response body is missing.',
        );
      }

      final AuthenticationResponseDto dto = AuthenticationResponseDto.fromJson(
        data,
      );

      _accessTokenStore.save(dto.accessToken);

      return dto.toDomain();
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }
}
