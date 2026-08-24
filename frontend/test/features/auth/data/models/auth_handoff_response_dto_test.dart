import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/auth/data/models/auth_handoff_response_dto.dart';

void main() {
  group('AuthHandoffResponseDto', () {
    test('parses authentication handoff response', () {
      final AuthHandoffResponseDto dto = AuthHandoffResponseDto.fromJson(
        <String, dynamic>{
          'handoff_token': 'temporary-token',
          'expires_in': 120,
        },
      );

      expect(dto.handoffToken, 'temporary-token');
      expect(dto.expiresIn, 120);

      final handoff = dto.toDomain();

      expect(handoff.token, 'temporary-token');
      expect(handoff.expiresIn, const Duration(minutes: 2));
    });

    test('rejects missing handoff token', () {
      expect(
        () => AuthHandoffResponseDto.fromJson(<String, dynamic>{
          'expires_in': 120,
        }),
        throwsFormatException,
      );
    });

    test('rejects invalid expiration', () {
      expect(
        () => AuthHandoffResponseDto.fromJson(<String, dynamic>{
          'handoff_token': 'temporary-token',
          'expires_in': 0,
        }),
        throwsFormatException,
      );
    });
  });
}
