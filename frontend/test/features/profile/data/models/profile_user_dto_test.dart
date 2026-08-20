import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/profile/data/models/profile_user_dto.dart';

void main() {
  group('ProfileUserDto', () {
    test('maps current user response to domain', () {
      final ProfileUserDto dto =
          ProfileUserDto.fromJson(const <String, dynamic>{
            'id': '11111111-2222-3333-4444-555555555555',
            'display_name': 'Gonçalo',
            'is_local': true,
            'is_admin': false,
          });

      final user = dto.toDomain();

      expect(user.id, '11111111-2222-3333-4444-555555555555');
      expect(user.displayName, 'Gonçalo');
      expect(user.isLocal, isTrue);
    });

    test('rejects missing display name', () {
      expect(
        () => ProfileUserDto.fromJson(const <String, dynamic>{
          'id': '11111111-2222-3333-4444-555555555555',
          'is_local': true,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects invalid local-user flag', () {
      expect(
        () => ProfileUserDto.fromJson(const <String, dynamic>{
          'id': '11111111-2222-3333-4444-555555555555',
          'display_name': 'Gonçalo',
          'is_local': 'true',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
