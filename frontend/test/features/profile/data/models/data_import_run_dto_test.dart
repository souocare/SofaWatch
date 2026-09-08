import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/features/profile/data/models/data_import_run_dto.dart';
import 'package:sofawatch/features/profile/domain/models/data_import_run.dart';

void main() {
  group('DataImportRunDto', () {
    test('parses queued import run', () {
      final DataImportRun run =
          DataImportRunDto.fromJson(const <String, dynamic>{
            'id': '11111111-1111-1111-1111-111111111111',
            'status': 'queued',
            'phase': 'queued',
            'progress_current': 0,
            'progress_total': 0,
            'result': null,
            'error_code': null,
            'error_message': null,
            'created_at': '2026-09-08T05:00:00Z',
            'started_at': null,
            'finished_at': null,
          }).toDomain();

      expect(run.id, '11111111-1111-1111-1111-111111111111');
      expect(run.status, DataImportRunStatus.queued);
      expect(run.phase, DataImportPhase.queued);
      expect(run.progressCurrent, 0);
      expect(run.progressTotal, 0);
      expect(run.result, isNull);
      expect(run.startedAt, isNull);
      expect(run.finishedAt, isNull);
      expect(run.isActive, isTrue);
      expect(run.isTerminal, isFalse);
      expect(run.progressFraction, isNull);
    });

    test('parses running phase progress', () {
      final DataImportRun run =
          DataImportRunDto.fromJson(const <String, dynamic>{
            'id': '22222222-2222-2222-2222-222222222222',
            'status': 'running',
            'phase': 'history_episodes',
            'progress_current': 25,
            'progress_total': 100,
            'result': null,
            'error_code': null,
            'error_message': null,
            'created_at': '2026-09-08T05:00:00Z',
            'started_at': '2026-09-08T05:00:02Z',
            'finished_at': null,
          }).toDomain();

      expect(run.status, DataImportRunStatus.running);
      expect(run.phase, DataImportPhase.historyEpisodes);
      expect(run.progressCurrent, 25);
      expect(run.progressTotal, 100);
      expect(run.progressFraction, 0.25);
      expect(run.startedAt, DateTime.parse('2026-09-08T05:00:02Z'));
    });

    test('parses completed run and nested import result', () {
      final DataImportRun run = DataImportRunDto.fromJson(
        const <String, dynamic>{
          'id': '33333333-3333-3333-3333-333333333333',
          'status': 'completed',
          'phase': 'finalizing',
          'progress_current': 0,
          'progress_total': 0,
          'result': <String, dynamic>{
            'library': <String, dynamic>{
              'shows': <String, dynamic>{
                'created': 2,
                'updated': 1,
                'unchanged': 3,
                'failed': 0,
              },
              'movies': <String, dynamic>{
                'created': 1,
                'updated': 0,
                'unchanged': 2,
                'failed': 0,
              },
            },
            'history': <String, dynamic>{
              'episodes': <String, dynamic>{
                'created': 15,
                'skipped': 4,
                'failed': 0,
              },
              'movies': <String, dynamic>{
                'created': 5,
                'skipped': 2,
                'failed': 0,
              },
            },
          },
          'error_code': null,
          'error_message': null,
          'created_at': '2026-09-08T05:00:00Z',
          'started_at': '2026-09-08T05:00:02Z',
          'finished_at': '2026-09-08T05:01:00Z',
        },
      ).toDomain();

      expect(run.status, DataImportRunStatus.completed);
      expect(run.phase, DataImportPhase.finalizing);
      expect(run.isTerminal, isTrue);
      expect(run.result, isNotNull);
      expect(run.result!.library.shows.created, 2);
      expect(run.result!.history.episodes.created, 15);
      expect(run.finishedAt, DateTime.parse('2026-09-08T05:01:00Z'));
    });

    test('parses failed run with safe backend error', () {
      final DataImportRun run =
          DataImportRunDto.fromJson(const <String, dynamic>{
            'id': '44444444-4444-4444-4444-444444444444',
            'status': 'failed',
            'phase': 'history_movies',
            'progress_current': 8,
            'progress_total': 10,
            'result': null,
            'error_code': 'data_import_interrupted',
            'error_message':
                'The import was interrupted before it could complete.',
            'created_at': '2026-09-08T05:00:00Z',
            'started_at': '2026-09-08T05:00:02Z',
            'finished_at': '2026-09-08T05:45:00Z',
          }).toDomain();

      expect(run.status, DataImportRunStatus.failed);
      expect(run.errorCode, 'data_import_interrupted');
      expect(
        run.errorMessage,
        'The import was interrupted before it could complete.',
      );
      expect(run.isTerminal, isTrue);
    });

    test('rejects unknown status', () {
      expect(
        () => DataImportRunDto.fromJson(const <String, dynamic>{
          'id': '55555555-5555-5555-5555-555555555555',
          'status': 'cancelled',
          'phase': 'queued',
          'progress_current': 0,
          'progress_total': 0,
          'result': null,
          'error_code': null,
          'error_message': null,
          'created_at': '2026-09-08T05:00:00Z',
          'started_at': null,
          'finished_at': null,
        }),
        throwsFormatException,
      );
    });

    test('rejects unknown phase', () {
      expect(
        () => DataImportRunDto.fromJson(const <String, dynamic>{
          'id': '66666666-6666-6666-6666-666666666666',
          'status': 'running',
          'phase': 'unknown_phase',
          'progress_current': 0,
          'progress_total': 0,
          'result': null,
          'error_code': null,
          'error_message': null,
          'created_at': '2026-09-08T05:00:00Z',
          'started_at': null,
          'finished_at': null,
        }),
        throwsFormatException,
      );
    });
  });
}
