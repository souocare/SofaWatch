import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/profile/domain/models/data_import_result.dart';

void main() {
  group('DataImportResult', () {
    test('hasFailures is false when every import category succeeded', () {
      const DataImportResult result = DataImportResult(
        library: DataImportLibraryResult(
          shows: DataImportMediaResult(
            created: 2,
            updated: 1,
            unchanged: 3,
            failed: 0,
          ),
          movies: DataImportMediaResult(
            created: 4,
            updated: 0,
            unchanged: 1,
            failed: 0,
          ),
        ),
        history: DataImportHistoryResult(
          episodes: DataImportHistoryMediaResult(
            created: 10,
            skipped: 2,
            failed: 0,
          ),
          movies: DataImportHistoryMediaResult(
            created: 5,
            skipped: 1,
            failed: 0,
          ),
        ),
      );

      expect(result.hasFailures, isFalse);
      expect(result.library.hasFailures, isFalse);
      expect(result.history.hasFailures, isFalse);
    });

    test('hasFailures is true when a Library Show failed', () {
      const DataImportResult result = DataImportResult(
        library: DataImportLibraryResult(
          shows: DataImportMediaResult(
            created: 2,
            updated: 0,
            unchanged: 0,
            failed: 1,
          ),
          movies: DataImportMediaResult(
            created: 0,
            updated: 0,
            unchanged: 0,
            failed: 0,
          ),
        ),
        history: DataImportHistoryResult(
          episodes: DataImportHistoryMediaResult(
            created: 0,
            skipped: 0,
            failed: 0,
          ),
          movies: DataImportHistoryMediaResult(
            created: 0,
            skipped: 0,
            failed: 0,
          ),
        ),
      );

      expect(result.hasFailures, isTrue);
      expect(result.library.hasFailures, isTrue);
      expect(result.library.shows.hasFailures, isTrue);
      expect(result.history.hasFailures, isFalse);
    });

    test('hasFailures is true when an Episode History item failed', () {
      const DataImportResult result = DataImportResult(
        library: DataImportLibraryResult(
          shows: DataImportMediaResult(
            created: 0,
            updated: 0,
            unchanged: 0,
            failed: 0,
          ),
          movies: DataImportMediaResult(
            created: 0,
            updated: 0,
            unchanged: 0,
            failed: 0,
          ),
        ),
        history: DataImportHistoryResult(
          episodes: DataImportHistoryMediaResult(
            created: 8,
            skipped: 2,
            failed: 1,
          ),
          movies: DataImportHistoryMediaResult(
            created: 3,
            skipped: 0,
            failed: 0,
          ),
        ),
      );

      expect(result.hasFailures, isTrue);
      expect(result.library.hasFailures, isFalse);
      expect(result.history.hasFailures, isTrue);
      expect(result.history.episodes.hasFailures, isTrue);
    });

    test('skipped History items are not treated as failures', () {
      const DataImportHistoryMediaResult result = DataImportHistoryMediaResult(
        created: 2,
        skipped: 7,
        failed: 0,
      );

      expect(result.hasFailures, isFalse);
    });
  });
}
