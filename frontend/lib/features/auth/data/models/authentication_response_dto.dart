import 'package:sofawatch/features/auth/domain/models/auth_session.dart';

final class AuthenticationResponseDto {
  const AuthenticationResponseDto({
    required this.accessToken,
    required this.tokenType,
    required this.expiresInSeconds,
    this.refreshToken,
  });

  factory AuthenticationResponseDto.fromJson(Map<String, dynamic> json) {
    final Object? accessTokenValue = json['access_token'];
    final Object? tokenTypeValue = json['token_type'];
    final Object? expiresInValue = json['expires_in'];
    final Object? refreshTokenValue = json['refresh_token'];

    if (accessTokenValue is! String || accessTokenValue.trim().isEmpty) {
      throw const FormatException(
        'Authentication response contains an invalid access token.',
      );
    }

    if (tokenTypeValue is! String ||
        tokenTypeValue.trim().toLowerCase() != 'bearer') {
      throw const FormatException(
        'Authentication response contains an invalid token type.',
      );
    }

    if (expiresInValue is! int || expiresInValue <= 0) {
      throw const FormatException(
        'Authentication response contains an invalid expiration.',
      );
    }

    String? refreshToken;

    if (refreshTokenValue != null) {
      if (refreshTokenValue is! String || refreshTokenValue.trim().isEmpty) {
        throw const FormatException(
          'Authentication response contains an invalid refresh token.',
        );
      }

      refreshToken = refreshTokenValue.trim();
    }

    return AuthenticationResponseDto(
      accessToken: accessTokenValue.trim(),
      tokenType: tokenTypeValue.trim().toLowerCase(),
      expiresInSeconds: expiresInValue,
      refreshToken: refreshToken,
    );
  }

  final String accessToken;
  final String tokenType;
  final int expiresInSeconds;
  final String? refreshToken;

  AuthSession toDomain() {
    return AuthSession(
      accessToken: accessToken,
      expiresIn: Duration(seconds: expiresInSeconds),
    );
  }
}
