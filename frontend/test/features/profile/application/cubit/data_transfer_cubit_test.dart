import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/profile/application/cubit/data_transfer_cubit.dart';
import 'package:sofawatch/features/profile/application/cubit/data_transfer_state.dart';
import 'package:sofawatch/features/profile/domain/models/data_import_preview.dart';
import 'package:sofawatch/features/profile/domain/models/data_import_result.dart';
import 'package:sofawatch/features/profile/domain/repositories/data_transfer_repository.dart';

void main() {
  group('DataTransferCubit', () {
    group('exportData', () {
      blocTest<DataTransferCubit, DataTransferState>(
        'emits exporting then ready when export succeeds',
        build: () => DataTransferCubit(
          repository: _FakeDataTransferRepository(exportJson: _exportJson),
        ),
        act: (DataTransferCubit cubit) => cubit.exportData(),
        expect: () => <DataTransferState>[
          const DataTransferExporting(),
          const DataTransferExportReady(_exportJson),
        ],
      );

      blocTest<DataTransferCubit, DataTransferState>(
        'emits exporting then failure when export fails',
        build: () => DataTransferCubit(
          repository: const _FakeDataTransferRepository(
            exportError: AppException.connection(),
          ),
        ),
        act: (DataTransferCubit cubit) => cubit.exportData(),
        expect: () => <DataTransferState>[
          const DataTransferExporting(),
          const DataTransferExportFailure(AppException.connection()),
        ],
      );

      test('does not start a second export while one is running', () async {
        final _ControlledDataTransferRepository repository =
            _ControlledDataTransferRepository();

        final DataTransferCubit cubit = DataTransferCubit(
          repository: repository,
        );

        final Future<void> first = cubit.exportData();

        await Future<void>.delayed(Duration.zero);

        expect(cubit.state, const DataTransferExporting());
        expect(repository.exportCalls, 1);

        final Future<void> second = cubit.exportData();

        await Future<void>.delayed(Duration.zero);

        expect(repository.exportCalls, 1);

        repository.completeExport(_exportJson);

        await first;
        await second;

        expect(cubit.state, const DataTransferExportReady(_exportJson));

        await cubit.close();
      });
    });

    group('previewImport', () {
      blocTest<DataTransferCubit, DataTransferState>(
        'emits preview loading then preview ready',
        build: () => DataTransferCubit(
          repository: const _FakeDataTransferRepository(preview: _preview),
        ),
        act: (DataTransferCubit cubit) {
          return cubit.previewImport(
            filename: 'backup.json',
            json: _exportJson,
          );
        },
        expect: () => <DataTransferState>[
          const DataTransferImportPreviewLoading(filename: 'backup.json'),
          const DataTransferImportPreviewReady(
            filename: 'backup.json',
            json: _exportJson,
            preview: _preview,
          ),
        ],
      );

      blocTest<DataTransferCubit, DataTransferState>(
        'preserves filename when preview fails',
        build: () => DataTransferCubit(
          repository: const _FakeDataTransferRepository(
            previewError: AppException.invalidData(),
          ),
        ),
        act: (DataTransferCubit cubit) {
          return cubit.previewImport(filename: 'broken.json', json: '{}');
        },
        expect: () => <DataTransferState>[
          const DataTransferImportPreviewLoading(filename: 'broken.json'),
          const DataTransferImportPreviewFailure(
            filename: 'broken.json',
            error: AppException.invalidData(),
          ),
        ],
      );

      test('does not start another preview while validating', () async {
        final _ControlledDataTransferRepository repository =
            _ControlledDataTransferRepository();

        final DataTransferCubit cubit = DataTransferCubit(
          repository: repository,
        );

        final Future<void> first = cubit.previewImport(
          filename: 'first.json',
          json: _exportJson,
        );

        await Future<void>.delayed(Duration.zero);

        expect(repository.previewCalls, 1);

        final Future<void> second = cubit.previewImport(
          filename: 'second.json',
          json: _exportJson,
        );

        await Future<void>.delayed(Duration.zero);

        expect(repository.previewCalls, 1);

        repository.completePreview(_preview);

        await first;
        await second;

        expect(
          cubit.state,
          const DataTransferImportPreviewReady(
            filename: 'first.json',
            json: _exportJson,
            preview: _preview,
          ),
        );

        await cubit.close();
      });
    });

    group('importData', () {
      blocTest<DataTransferCubit, DataTransferState>(
        'emits importing then success when import succeeds',
        build: () => DataTransferCubit(
          repository: const _FakeDataTransferRepository(
            importResult: _successfulImportResult,
          ),
        ),
        act: (DataTransferCubit cubit) {
          return cubit.importData(_exportJson);
        },
        expect: () => <DataTransferState>[
          const DataTransferImporting(),
          const DataTransferImportSuccess(_successfulImportResult),
        ],
      );

      blocTest<DataTransferCubit, DataTransferState>(
        'keeps partial import result as success',
        build: () => DataTransferCubit(
          repository: const _FakeDataTransferRepository(
            importResult: _partialImportResult,
          ),
        ),
        act: (DataTransferCubit cubit) {
          return cubit.importData(_exportJson);
        },
        expect: () => <DataTransferState>[
          const DataTransferImporting(),
          const DataTransferImportSuccess(_partialImportResult),
        ],
      );

      blocTest<DataTransferCubit, DataTransferState>(
        'emits importing then failure when request fails',
        build: () => DataTransferCubit(
          repository: const _FakeDataTransferRepository(
            importError: AppException.connection(),
          ),
        ),
        act: (DataTransferCubit cubit) {
          return cubit.importData(_exportJson);
        },
        expect: () => <DataTransferState>[
          const DataTransferImporting(),
          const DataTransferImportFailure(AppException.connection()),
        ],
      );

      test('does not start another import while importing', () async {
        final _ControlledDataTransferRepository repository =
            _ControlledDataTransferRepository();

        final DataTransferCubit cubit = DataTransferCubit(
          repository: repository,
        );

        final Future<void> first = cubit.importData(_exportJson);

        await Future<void>.delayed(Duration.zero);

        expect(repository.importCalls, 1);

        final Future<void> second = cubit.importData(_exportJson);

        await Future<void>.delayed(Duration.zero);

        expect(repository.importCalls, 1);

        repository.completeImport(_successfulImportResult);

        await first;
        await second;

        expect(
          cubit.state,
          const DataTransferImportSuccess(_successfulImportResult),
        );

        await cubit.close();
      });
    });

    group('reset', () {
      blocTest<DataTransferCubit, DataTransferState>(
        'returns to idle',
        build: () => DataTransferCubit(
          repository: const _FakeDataTransferRepository(preview: _preview),
        ),
        seed: () => const DataTransferImportPreviewReady(
          filename: 'backup.json',
          json: _exportJson,
          preview: _preview,
        ),
        act: (DataTransferCubit cubit) => cubit.reset(),
        expect: () => const <DataTransferState>[DataTransferIdle()],
      );

      blocTest<DataTransferCubit, DataTransferState>(
        'does nothing when already idle',
        build: () =>
            DataTransferCubit(repository: const _FakeDataTransferRepository()),
        act: (DataTransferCubit cubit) => cubit.reset(),
        expect: () => const <DataTransferState>[],
      );
    });
  });
}

const String _exportJson = '''
{
  "format": "sofawatch-export",
  "version": 1
}
''';

const DataImportPreview _preview = DataImportPreview(
  format: 'sofawatch-export',
  version: 1,
  userDisplayName: 'Test User',
  libraryShows: 12,
  libraryMovies: 8,
  episodeWatchEvents: 125,
  movieWatchEvents: 20,
);

const DataImportResult _successfulImportResult = DataImportResult(
  library: DataImportLibraryResult(
    shows: DataImportMediaResult(
      created: 2,
      updated: 1,
      unchanged: 3,
      failed: 0,
    ),
    movies: DataImportMediaResult(
      created: 1,
      updated: 0,
      unchanged: 2,
      failed: 0,
    ),
  ),
  history: DataImportHistoryResult(
    episodes: DataImportHistoryMediaResult(created: 15, skipped: 4, failed: 0),
    movies: DataImportHistoryMediaResult(created: 5, skipped: 2, failed: 0),
  ),
);

const DataImportResult _partialImportResult = DataImportResult(
  library: DataImportLibraryResult(
    shows: DataImportMediaResult(
      created: 2,
      updated: 0,
      unchanged: 1,
      failed: 1,
    ),
    movies: DataImportMediaResult(
      created: 1,
      updated: 0,
      unchanged: 0,
      failed: 0,
    ),
  ),
  history: DataImportHistoryResult(
    episodes: DataImportHistoryMediaResult(created: 7, skipped: 2, failed: 1),
    movies: DataImportHistoryMediaResult(created: 3, skipped: 1, failed: 0),
  ),
);

final class _FakeDataTransferRepository implements DataTransferRepository {
  const _FakeDataTransferRepository({
    this.exportJson,
    this.exportError,
    this.preview,
    this.previewError,
    this.importResult,
    this.importError,
  });

  final String? exportJson;
  final AppException? exportError;

  final DataImportPreview? preview;
  final AppException? previewError;

  final DataImportResult? importResult;
  final AppException? importError;

  @override
  Future<String> exportData() async {
    final AppException? error = exportError;

    if (error != null) {
      throw error;
    }

    return exportJson ?? _exportJson;
  }

  @override
  Future<DataImportPreview> previewImport(String json) async {
    final AppException? error = previewError;

    if (error != null) {
      throw error;
    }

    return preview ?? _preview;
  }

  @override
  Future<DataImportResult> importData(String json) async {
    final AppException? error = importError;

    if (error != null) {
      throw error;
    }

    return importResult ?? _successfulImportResult;
  }
}

final class _ControlledDataTransferRepository
    implements DataTransferRepository {
  final Completer<String> _exportCompleter = Completer<String>();

  final Completer<DataImportPreview> _previewCompleter =
      Completer<DataImportPreview>();

  final Completer<DataImportResult> _importCompleter =
      Completer<DataImportResult>();

  int exportCalls = 0;
  int previewCalls = 0;
  int importCalls = 0;

  void completeExport(String json) {
    _exportCompleter.complete(json);
  }

  void completePreview(DataImportPreview preview) {
    _previewCompleter.complete(preview);
  }

  void completeImport(DataImportResult result) {
    _importCompleter.complete(result);
  }

  @override
  Future<String> exportData() {
    exportCalls += 1;

    return _exportCompleter.future;
  }

  @override
  Future<DataImportPreview> previewImport(String json) {
    previewCalls += 1;

    return _previewCompleter.future;
  }

  @override
  Future<DataImportResult> importData(String json) {
    importCalls += 1;

    return _importCompleter.future;
  }
}
