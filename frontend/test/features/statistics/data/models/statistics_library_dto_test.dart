import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/statistics/data/models/statistics_library_dto.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_library.dart';

void main() {
  group('StatisticsLibraryDto', () {
    test('maps a valid response to domain', () {
      final StatisticsLibrary result = StatisticsLibraryDto.fromJson(
        const <String, dynamic>{
          'shows_added': 18,
          'movies_added': 42,
          'shows_completed': 7,
        },
      ).toDomain();

      expect(
        result,
        const StatisticsLibrary(
          showsAdded: 18,
          moviesAdded: 42,
          showsCompleted: 7,
        ),
      );
    });

    test('accepts zero values', () {
      final StatisticsLibrary result = StatisticsLibraryDto.fromJson(
        const <String, dynamic>{
          'shows_added': 0,
          'movies_added': 0,
          'shows_completed': 0,
        },
      ).toDomain();

      expect(
        result,
        const StatisticsLibrary(
          showsAdded: 0,
          moviesAdded: 0,
          showsCompleted: 0,
        ),
      );
    });

    test('rejects a negative Shows count', () {
      expect(
        () => StatisticsLibraryDto.fromJson(const <String, dynamic>{
          'shows_added': -1,
          'movies_added': 42,
          'shows_completed': 7,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a negative Movies count', () {
      expect(
        () => StatisticsLibraryDto.fromJson(const <String, dynamic>{
          'shows_added': 18,
          'movies_added': -1,
          'shows_completed': 7,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a negative completed Shows count', () {
      expect(
        () => StatisticsLibraryDto.fromJson(const <String, dynamic>{
          'shows_added': 18,
          'movies_added': 42,
          'shows_completed': -1,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a non-integer count', () {
      expect(
        () => StatisticsLibraryDto.fromJson(const <String, dynamic>{
          'shows_added': '18',
          'movies_added': 42,
          'shows_completed': 7,
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
