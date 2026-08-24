import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/auth/data/models/setup_status_dto.dart';

void main() {
  group('SetupStatusDto', () {
    test('parses setup required response', () {
      final SetupStatusDto dto = SetupStatusDto.fromJson(
        const <String, dynamic>{'setup_required': true},
      );

      expect(dto.setupRequired, isTrue);

      expect(dto.toDomain().setupRequired, isTrue);
    });

    test('parses completed setup response', () {
      final SetupStatusDto dto = SetupStatusDto.fromJson(
        const <String, dynamic>{'setup_required': false},
      );

      expect(dto.setupRequired, isFalse);
    });

    test('rejects missing setup_required', () {
      expect(
        () => SetupStatusDto.fromJson(const <String, dynamic>{}),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects non-boolean setup_required', () {
      expect(
        () => SetupStatusDto.fromJson(const <String, dynamic>{
          'setup_required': 'true',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
