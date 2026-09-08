import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/profile/data/repositories/api_data_transfer_repository.dart';
import 'package:sofawatch/features/profile/domain/models/data_import_preview.dart';
import 'package:sofawatch/features/profile/domain/models/data_import_run.dart';

void main() {
  group('ApiDataTransferRepository', () {
    test('exports portable SofaWatch JSON data', () async {
      const String exportJson = '''
{
  "format": "sofawatch-export",
  "version": 1,
  "exported_at": "2026-08-21T12:00:00Z",
  "user": {
    "display_name": "Test User"
  },
  "library": {
    "shows": [],
    "movies": []
  },
  "history": {
    "episodes": [],
    "movies": []
  }
}
''';

      final ApiDataTransferRepository repository = _createRepository(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          expect(options.method, 'GET');
          expect(options.path, endsWith('/users/me/export'));
          expect(options.responseType, ResponseType.plain);

          handler.resolve(
            Response<String>(
              requestOptions: options,
              statusCode: 200,
              data: exportJson,
            ),
          );
        },
      );

      final String result = await repository.exportData();

      expect(result, exportJson);
    });

    test('rejects an empty export response', () async {
      final ApiDataTransferRepository repository = _createRepository(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          handler.resolve(
            Response<String>(
              requestOptions: options,
              statusCode: 200,
              data: '',
            ),
          );
        },
      );

      await expectLater(
        repository.exportData(),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('preserves mapped API error during export', () async {
      final ApiDataTransferRepository repository = _createRepository(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          handler.reject(
            DioException.badResponse(
              statusCode: 500,
              requestOptions: options,
              response: Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 500,
                data: const <String, dynamic>{
                  'error': <String, dynamic>{
                    'code': 'export_failed',
                    'message': 'Export failed.',
                  },
                },
              ),
            ),
          );
        },
      );

      await expectLater(
        repository.exportData(),
        throwsA(
          isA<AppException>()
              .having(
                (AppException error) => error.type,
                'type',
                AppExceptionType.server,
              )
              .having(
                (AppException error) => error.code,
                'code',
                'export_failed',
              ),
        ),
      );
    });

    test('validates import and parses preview', () async {
      const String json = '''
{
  "format": "sofawatch-export",
  "version": 1,
  "exported_at": "2026-08-21T12:00:00Z",
  "user": {
    "display_name": "Backup User"
  },
  "library": {
    "shows": [],
    "movies": []
  },
  "history": {
    "episodes": [],
    "movies": []
  }
}
''';

      final ApiDataTransferRepository repository = _createRepository(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          expect(options.method, 'POST');
          expect(options.path, endsWith('/users/me/import/preview'));

          expect(options.data, jsonDecode(json));

          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: const <String, dynamic>{
                'format': 'sofawatch-export',
                'version': 1,
                'user_display_name': 'Backup User',
                'summary': <String, dynamic>{
                  'library_shows': 12,
                  'library_movies': 7,
                  'episode_watch_events': 145,
                  'movie_watch_events': 19,
                },
              },
            ),
          );
        },
      );

      final DataImportPreview result = await repository.previewImport(json);

      expect(result.format, 'sofawatch-export');
      expect(result.version, 1);
      expect(result.userDisplayName, 'Backup User');
      expect(result.libraryShows, 12);
      expect(result.libraryMovies, 7);
      expect(result.episodeWatchEvents, 145);
      expect(result.movieWatchEvents, 19);
    });

    test('rejects malformed JSON before preview request', () async {
      final ApiDataTransferRepository repository = _createRepository(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          fail('The API request must not be made for malformed JSON.');
        },
      );

      await expectLater(
        repository.previewImport('{invalid-json'),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('rejects preview JSON whose root is not an object', () async {
      final ApiDataTransferRepository repository = _createRepository(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          fail('The API request must not be made for a non-object root.');
        },
      );

      await expectLater(
        repository.previewImport('["not", "an", "object"]'),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('rejects an invalid preview response', () async {
      final ApiDataTransferRepository repository = _createRepository(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: const <String, dynamic>{
                'format': 'sofawatch-export',
                'version': 1,
                'user_display_name': 'Backup User',
                'summary': <String, dynamic>{
                  'library_shows': 'invalid',
                  'library_movies': 0,
                  'episode_watch_events': 0,
                  'movie_watch_events': 0,
                },
              },
            ),
          );
        },
      );

      await expectLater(
        repository.previewImport('{"format":"sofawatch-export","version":1}'),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('preserves mapped API error during preview', () async {
      final ApiDataTransferRepository repository = _createRepository(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          handler.reject(
            DioException.badResponse(
              statusCode: 422,
              requestOptions: options,
              response: Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 422,
                data: const <String, dynamic>{
                  'error': <String, dynamic>{
                    'code': 'invalid_request',
                    'message': 'The request data is invalid.',
                  },
                },
              ),
            ),
          );
        },
      );

      await expectLater(
        repository.previewImport('{"format":"sofawatch-export","version":99}'),
        throwsA(
          isA<AppException>()
              .having(
                (AppException error) => error.type,
                'type',
                AppExceptionType.validation,
              )
              .having(
                (AppException error) => error.code,
                'code',
                'invalid_request',
              ),
        ),
      );
    });

    test('rejects malformed JSON before import request', () async {
      final ApiDataTransferRepository repository = _createRepository(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          fail('The API request must not be made for malformed JSON.');
        },
      );

      await expectLater(
        repository.importData('not json'),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('rejects import JSON whose root is not an object', () async {
      final ApiDataTransferRepository repository = _createRepository(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          fail('The API request must not be made for a non-object root.');
        },
      );

      await expectLater(
        repository.importData('[]'),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('preserves mapped API error during import', () async {
      final ApiDataTransferRepository repository = _createRepository(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          handler.reject(
            DioException.badResponse(
              statusCode: 503,
              requestOptions: options,
              response: Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 503,
                data: const <String, dynamic>{
                  'error': <String, dynamic>{
                    'code': 'provider_unavailable',
                    'message':
                        'The metadata provider is temporarily unavailable.',
                  },
                },
              ),
            ),
          );
        },
      );

      await expectLater(
        repository.importData('{"format":"sofawatch-export","version":1}'),
        throwsA(
          isA<AppException>()
              .having(
                (AppException error) => error.type,
                'type',
                AppExceptionType.server,
              )
              .having(
                (AppException error) => error.code,
                'code',
                'provider_unavailable',
              ),
        ),
      );
    });
    test('submits import and parses queued persistent run', () async {
      const String json = '''
{
  "format": "sofawatch-export",
  "version": 1
}
''';

      final ApiDataTransferRepository repository = _createRepository(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          expect(options.method, 'POST');
          expect(options.path, endsWith('/users/me/import'));
          expect(options.data, jsonDecode(json));

          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 202,
              data: const <String, dynamic>{
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
              },
            ),
          );
        },
      );

      final DataImportRun result = await repository.importData(json);

      expect(result.id, '11111111-1111-1111-1111-111111111111');
      expect(result.status, DataImportRunStatus.queued);
      expect(result.phase, DataImportPhase.queued);
      expect(result.result, isNull);
    });

    test('returns active import run', () async {
      final ApiDataTransferRepository repository = _createRepository(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          expect(options.method, 'GET');
          expect(options.path, endsWith('/users/me/imports/active'));

          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: const <String, dynamic>{
                'id': '22222222-2222-2222-2222-222222222222',
                'status': 'running',
                'phase': 'library_movies',
                'progress_current': 7,
                'progress_total': 20,
                'result': null,
                'error_code': null,
                'error_message': null,
                'created_at': '2026-09-08T05:00:00Z',
                'started_at': '2026-09-08T05:00:02Z',
                'finished_at': null,
              },
            ),
          );
        },
      );

      final DataImportRun? result = await repository.getActiveImport();

      expect(result, isNotNull);
      expect(result!.status, DataImportRunStatus.running);
      expect(result.phase, DataImportPhase.libraryMovies);
      expect(result.progressCurrent, 7);
      expect(result.progressTotal, 20);
    });

    test('returns null when there is no active import', () async {
      final ApiDataTransferRepository repository = _createRepository(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          expect(options.method, 'GET');
          expect(options.path, endsWith('/users/me/imports/active'));

          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: null,
            ),
          );
        },
      );

      final DataImportRun? result = await repository.getActiveImport();

      expect(result, isNull);
    });

    test('gets import run by id', () async {
      const String runId = '33333333-3333-3333-3333-333333333333';

      final ApiDataTransferRepository repository = _createRepository(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          expect(options.method, 'GET');
          expect(options.path, endsWith('/users/me/imports/$runId'));

          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: const <String, dynamic>{
                'id': runId,
                'status': 'running',
                'phase': 'history_episodes',
                'progress_current': 125,
                'progress_total': 500,
                'result': null,
                'error_code': null,
                'error_message': null,
                'created_at': '2026-09-08T05:00:00Z',
                'started_at': '2026-09-08T05:00:02Z',
                'finished_at': null,
              },
            ),
          );
        },
      );

      final DataImportRun result = await repository.getImportRun(runId);

      expect(result.id, runId);
      expect(result.phase, DataImportPhase.historyEpisodes);
      expect(result.progressCurrent, 125);
    });

    test('rejects malformed persistent import response', () async {
      final ApiDataTransferRepository repository = _createRepository(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 202,
              data: const <String, dynamic>{
                'id': '11111111-1111-1111-1111-111111111111',
                'status': 'not-a-real-status',
                'phase': 'queued',
                'progress_current': 0,
                'progress_total': 0,
                'result': null,
                'error_code': null,
                'error_message': null,
                'created_at': '2026-09-08T05:00:00Z',
                'started_at': null,
                'finished_at': null,
              },
            ),
          );
        },
      );

      await expectLater(
        repository.importData('{"format":"sofawatch-export","version":1}'),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });
  });
}

ApiDataTransferRepository _createRepository({
  required void Function(
    RequestOptions options,
    RequestInterceptorHandler handler,
  )
  onRequest,
}) {
  final Dio dio = Dio();

  dio.interceptors.add(InterceptorsWrapper(onRequest: onRequest));

  return ApiDataTransferRepository(
    ApiClient(baseUrl: Uri.parse('https://server.example.com'), dio: dio),
  );
}
