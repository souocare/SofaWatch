import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/profile/application/cubit/data_transfer_cubit.dart';
import 'package:sofawatch/features/profile/application/cubit/data_transfer_state.dart';
import 'package:sofawatch/features/profile/domain/models/data_import_preview.dart';
import 'package:sofawatch/features/profile/domain/models/data_import_result.dart';
import 'package:sofawatch/features/profile/domain/models/data_import_run.dart';
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
    });

    group('importData', () {
      blocTest<DataTransferCubit, DataTransferState>(
        'emits queued persistent run after submission',
        build: () => DataTransferCubit(
          repository: _FakeDataTransferRepository(importRun: _queuedImportRun),
        ),
        act: (DataTransferCubit cubit) {
          return cubit.importData(_exportJson);
        },
        expect: () => <DataTransferState>[
          const DataTransferImporting(),
          DataTransferImportInProgress(_queuedImportRun),
        ],
      );

      blocTest<DataTransferCubit, DataTransferState>(
        'maps immediately completed run to existing success state',
        build: () => DataTransferCubit(
          repository: _FakeDataTransferRepository(
            importRun: _completedImportRun,
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
        'keeps partial completed import as success',
        build: () => DataTransferCubit(
          repository: _FakeDataTransferRepository(
            importRun: _completedPartialImportRun,
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
        'maps terminal failed run separately from request failure',
        build: () => DataTransferCubit(
          repository: _FakeDataTransferRepository(importRun: _failedImportRun),
        ),
        act: (DataTransferCubit cubit) {
          return cubit.importData(_exportJson);
        },
        expect: () => <DataTransferState>[
          const DataTransferImporting(),
          DataTransferImportRunFailure(_failedImportRun),
        ],
      );

      blocTest<DataTransferCubit, DataTransferState>(
        'emits request failure when creating run fails',
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

      test('does not submit a second import while POST is pending', () async {
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

        repository.completeImport(_queuedImportRun);

        await first;
        await second;

        expect(cubit.state, DataTransferImportInProgress(_queuedImportRun));

        await cubit.close();
      });
    });

    group('resumeActiveImport', () {
      blocTest<DataTransferCubit, DataTransferState>(
        'restores queued import after page recreation',
        build: () => DataTransferCubit(
          repository: _FakeDataTransferRepository(
            activeImport: _queuedImportRun,
          ),
        ),
        act: (DataTransferCubit cubit) {
          return cubit.resumeActiveImport();
        },
        expect: () => <DataTransferState>[
          DataTransferImportInProgress(_queuedImportRun),
        ],
      );

      blocTest<DataTransferCubit, DataTransferState>(
        'does nothing when no import is active',
        build: () =>
            DataTransferCubit(repository: const _FakeDataTransferRepository()),
        act: (DataTransferCubit cubit) {
          return cubit.resumeActiveImport();
        },
        expect: () => const <DataTransferState>[],
      );

      blocTest<DataTransferCubit, DataTransferState>(
        'emits separate recovery failure when active lookup fails',
        build: () => DataTransferCubit(
          repository: const _FakeDataTransferRepository(
            activeImportError: AppException.connection(),
          ),
        ),
        act: (DataTransferCubit cubit) {
          return cubit.resumeActiveImport();
        },
        expect: () => <DataTransferState>[
          const DataTransferImportRecoveryFailure(AppException.connection()),
        ],
      );
    });

    group('refreshActiveImport', () {
      test('refreshes active run and emits progress update', () async {
        final _ControlledDataTransferRepository repository =
            _ControlledDataTransferRepository();

        final DataTransferCubit cubit = DataTransferCubit(
          repository: repository,
          importPollInterval: const Duration(days: 1),
        );

        repository.completeActiveImport(_queuedImportRun);

        await cubit.resumeActiveImport();

        repository.completeStatus(_runningImportRun);

        await cubit.refreshActiveImport();

        expect(repository.statusCalls, 1);
        expect(cubit.state, DataTransferImportInProgress(_runningImportRun));

        await cubit.close();
      });

      test('completed status stops tracking and exposes result', () async {
        final _ControlledDataTransferRepository repository =
            _ControlledDataTransferRepository();

        final DataTransferCubit cubit = DataTransferCubit(
          repository: repository,
          importPollInterval: const Duration(days: 1),
        );

        repository.completeActiveImport(_runningImportRun);

        await cubit.resumeActiveImport();

        repository.completeStatus(_completedImportRun);

        await cubit.refreshActiveImport();

        expect(
          cubit.state,
          const DataTransferImportSuccess(_successfulImportResult),
        );

        await cubit.close();
      });

      test(
        'temporary status error does not convert active import into failure',
        () async {
          final _ControlledDataTransferRepository repository =
              _ControlledDataTransferRepository();

          final DataTransferCubit cubit = DataTransferCubit(
            repository: repository,
            importPollInterval: const Duration(days: 1),
          );

          repository.completeActiveImport(_runningImportRun);

          await cubit.resumeActiveImport();

          repository.failStatus(const AppException.connection());

          await cubit.refreshActiveImport();

          expect(
            cubit.state,
            DataTransferImportStatusFailure(
              run: _runningImportRun,
              error: const AppException.connection(),
            ),
          );

          await cubit.close();
        },
      );
    });

    group('reset', () {
      blocTest<DataTransferCubit, DataTransferState>(
        'returns terminal state to idle',
        build: () =>
            DataTransferCubit(repository: const _FakeDataTransferRepository()),
        seed: () => const DataTransferImportSuccess(_successfulImportResult),
        act: (DataTransferCubit cubit) => cubit.reset(),
        expect: () => const <DataTransferState>[DataTransferIdle()],
      );

      blocTest<DataTransferCubit, DataTransferState>(
        'does not forget an active import',
        build: () =>
            DataTransferCubit(repository: const _FakeDataTransferRepository()),
        seed: () => DataTransferImportInProgress(_runningImportRun),
        act: (DataTransferCubit cubit) => cubit.reset(),
        expect: () => const <DataTransferState>[],
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

final DataImportRun _queuedImportRun = DataImportRun(
  id: '11111111-1111-1111-1111-111111111111',
  status: DataImportRunStatus.queued,
  phase: DataImportPhase.queued,
  progressCurrent: 0,
  progressTotal: 0,
  result: null,
  errorCode: null,
  errorMessage: null,
  createdAt: DateTime.utc(2026, 9, 8, 5),
  startedAt: null,
  finishedAt: null,
);

final DataImportRun _runningImportRun = DataImportRun(
  id: _queuedImportRun.id,
  status: DataImportRunStatus.running,
  phase: DataImportPhase.historyEpisodes,
  progressCurrent: 25,
  progressTotal: 100,
  result: null,
  errorCode: null,
  errorMessage: null,
  createdAt: _queuedImportRun.createdAt,
  startedAt: DateTime.utc(2026, 9, 8, 5, 0, 2),
  finishedAt: null,
);

final DataImportRun _completedImportRun = DataImportRun(
  id: _queuedImportRun.id,
  status: DataImportRunStatus.completed,
  phase: DataImportPhase.finalizing,
  progressCurrent: 0,
  progressTotal: 0,
  result: _successfulImportResult,
  errorCode: null,
  errorMessage: null,
  createdAt: _queuedImportRun.createdAt,
  startedAt: DateTime.utc(2026, 9, 8, 5, 0, 2),
  finishedAt: DateTime.utc(2026, 9, 8, 5, 1),
);

final DataImportRun _completedPartialImportRun = DataImportRun(
  id: _queuedImportRun.id,
  status: DataImportRunStatus.completed,
  phase: DataImportPhase.finalizing,
  progressCurrent: 0,
  progressTotal: 0,
  result: _partialImportResult,
  errorCode: null,
  errorMessage: null,
  createdAt: _queuedImportRun.createdAt,
  startedAt: DateTime.utc(2026, 9, 8, 5, 0, 2),
  finishedAt: DateTime.utc(2026, 9, 8, 5, 1),
);

final DataImportRun _failedImportRun = DataImportRun(
  id: _queuedImportRun.id,
  status: DataImportRunStatus.failed,
  phase: DataImportPhase.historyEpisodes,
  progressCurrent: 25,
  progressTotal: 100,
  result: null,
  errorCode: 'data_import_interrupted',
  errorMessage: 'The import was interrupted before it could complete.',
  createdAt: _queuedImportRun.createdAt,
  startedAt: DateTime.utc(2026, 9, 8, 5, 0, 2),
  finishedAt: DateTime.utc(2026, 9, 8, 5, 45),
);

final class _FakeDataTransferRepository implements DataTransferRepository {
  const _FakeDataTransferRepository({
    this.exportJson,
    this.exportError,
    this.preview,
    this.previewError,
    this.importRun,
    this.importError,
    this.activeImport,
    this.activeImportError,
  });

  final String? exportJson;
  final AppException? exportError;

  final DataImportPreview? preview;
  final AppException? previewError;

  final DataImportRun? importRun;
  final AppException? importError;

  final DataImportRun? activeImport;
  final AppException? activeImportError;

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
  Future<DataImportRun> importData(String json) async {
    final AppException? error = importError;

    if (error != null) {
      throw error;
    }

    return importRun ?? _completedImportRun;
  }

  @override
  Future<DataImportRun?> getActiveImport() async {
    final AppException? error = activeImportError;

    if (error != null) {
      throw error;
    }

    return activeImport;
  }

  @override
  Future<DataImportRun> getImportRun(String id) {
    throw UnimplementedError();
  }
}

final class _ControlledDataTransferRepository
    implements DataTransferRepository {
  final Completer<String> _exportCompleter = Completer<String>();
  final Completer<DataImportRun> _importCompleter = Completer<DataImportRun>();
  final Completer<DataImportRun?> _activeImportCompleter =
      Completer<DataImportRun?>();

  Completer<DataImportRun> _statusCompleter = Completer<DataImportRun>();

  int exportCalls = 0;
  int importCalls = 0;
  int statusCalls = 0;

  void completeExport(String json) {
    _exportCompleter.complete(json);
  }

  void completeImport(DataImportRun run) {
    _importCompleter.complete(run);
  }

  void completeActiveImport(DataImportRun? run) {
    _activeImportCompleter.complete(run);
  }

  void completeStatus(DataImportRun run) {
    _statusCompleter.complete(run);
  }

  void failStatus(AppException error) {
    _statusCompleter.completeError(error);
  }

  @override
  Future<String> exportData() {
    exportCalls += 1;
    return _exportCompleter.future;
  }

  @override
  Future<DataImportPreview> previewImport(String json) {
    throw UnimplementedError();
  }

  @override
  Future<DataImportRun> importData(String json) {
    importCalls += 1;
    return _importCompleter.future;
  }

  @override
  Future<DataImportRun?> getActiveImport() {
    return _activeImportCompleter.future;
  }

  @override
  Future<DataImportRun> getImportRun(String id) async {
    statusCalls += 1;

    final Completer<DataImportRun> completer = _statusCompleter;

    try {
      return await completer.future;
    } finally {
      if (identical(completer, _statusCompleter)) {
        _statusCompleter = Completer<DataImportRun>();
      }
    }
  }
}
