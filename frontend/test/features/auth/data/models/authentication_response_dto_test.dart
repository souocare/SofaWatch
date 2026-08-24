import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/auth/data/models/authentication_response_dto.dart';

void main() {
  group('AuthenticationResponseDto', () {
    test('parses Web authentication response', () {
      final AuthenticationResponseDto dto = AuthenticationResponseDto.fromJson(
        <String, dynamic>{
          'access_token': 'access-token',
          'token_type': 'bearer',
          'expires_in': 900,
        },
      );

      expect(dto.accessToken, 'access-token');
      expect(dto.tokenType, 'bearer');
      expect(dto.expiresInSeconds, 900);
      expect(dto.refreshToken, isNull);

      final session = dto.toDomain();

      expect(session.accessToken, 'access-token');
      expect(session.expiresIn, const Duration(seconds: 900));
    });

    test('parses Mobile authentication response', () {
      final AuthenticationResponseDto dto =
          AuthenticationResponseDto.fromJson(<String, dynamic>{
            'access_token': 'access-token',
            'token_type': 'bearer',
            'expires_in': 900,
            'refresh_token': 'refresh-token',
          });

      expect(dto.refreshToken, 'refresh-token');
    });

    test('rejects missing access token', () {
      expect(
        () => AuthenticationResponseDto.fromJson(<String, dynamic>{
          'token_type': 'bearer',
          'expires_in': 900,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects invalid token type', () {
      expect(
        () => AuthenticationResponseDto.fromJson(<String, dynamic>{
          'access_token': 'access-token',
          'token_type': 'basic',
          'expires_in': 900,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects invalid expiration', () {
      expect(
        () => AuthenticationResponseDto.fromJson(<String, dynamic>{
          'access_token': 'access-token',
          'token_type': 'bearer',
          'expires_in': 0,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects empty refresh token when present', () {
      expect(
        () => AuthenticationResponseDto.fromJson(<String, dynamic>{
          'access_token': 'access-token',
          'token_type': 'bearer',
          'expires_in': 900,
          'refresh_token': '   ',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
