import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/security/data/models/security_settings_dto.dart';
import 'package:sofawatch/features/security/domain/models/security_settings.dart';

void main() {
  group('SecuritySettingsDto', () {
    test('maps valid response', () {
      final SecuritySettingsDto dto = SecuritySettingsDto.fromJson(
        <String, dynamic>{'open_registration': true},
      );

      expect(dto.openRegistration, isTrue);

      expect(dto.toDomain(), const SecuritySettings(openRegistration: true));
    });

    test('supports closed registration', () {
      final SecuritySettingsDto dto = SecuritySettingsDto.fromJson(
        <String, dynamic>{'open_registration': false},
      );

      expect(dto.openRegistration, isFalse);
    });

    test('rejects missing open registration', () {
      expect(
        () => SecuritySettingsDto.fromJson(<String, dynamic>{}),
        throwsFormatException,
      );
    });

    test('rejects invalid open registration type', () {
      expect(
        () => SecuritySettingsDto.fromJson(<String, dynamic>{
          'open_registration': 'true',
        }),
        throwsFormatException,
      );
    });
  });
}
