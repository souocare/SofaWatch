import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/profile/data/models/data_import_result_dto.dart';

void main() {
  group('DataImportResultDto', () {
    test('parses complete import result including partial failures', () {
      final DataImportResultDto dto = DataImportResultDto.fromJson(
        <String, dynamic>{
          'library': <String, dynamic>{
            'shows': <String, dynamic>{
              'created': 2,
              'updated': 1,
              'unchanged': 3,
              'failed': 1,
            },
            'movies': <String, dynamic>{
              'created': 4,
              'updated': 0,
              'unchanged': 2,
              'failed': 0,
            },
          },
          'history': <String, dynamic>{
            'episodes': <String, dynamic>{
              'created': 10,
              'skipped': 3,
              'failed': 2,
            },
            'movies': <String, dynamic>{
              'created': 5,
              'skipped': 1,
              'failed': 0,
            },
          },
        },
      );

      final result = dto.toDomain();

      expect(result.library.shows.created, 2);
      expect(result.library.shows.updated, 1);
      expect(result.library.shows.unchanged, 3);
      expect(result.library.shows.failed, 1);

      expect(result.library.movies.created, 4);
      expect(result.library.movies.failed, 0);

      expect(result.history.episodes.created, 10);
      expect(result.history.episodes.skipped, 3);
      expect(result.history.episodes.failed, 2);

      expect(result.history.movies.created, 5);
      expect(result.history.movies.skipped, 1);
      expect(result.history.movies.failed, 0);

      expect(result.hasFailures, isTrue);
    });

    test('parses successful import result with no failures', () {
      final DataImportResultDto dto = DataImportResultDto.fromJson(
        <String, dynamic>{
          'library': <String, dynamic>{
            'shows': <String, dynamic>{
              'created': 1,
              'updated': 0,
              'unchanged': 0,
              'failed': 0,
            },
            'movies': <String, dynamic>{
              'created': 1,
              'updated': 0,
              'unchanged': 0,
              'failed': 0,
            },
          },
          'history': <String, dynamic>{
            'episodes': <String, dynamic>{
              'created': 4,
              'skipped': 1,
              'failed': 0,
            },
            'movies': <String, dynamic>{
              'created': 2,
              'skipped': 0,
              'failed': 0,
            },
          },
        },
      );

      expect(dto.toDomain().hasFailures, isFalse);
    });
  });
}
