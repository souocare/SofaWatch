import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/profile/data/repositories/api_data_transfer_repository.dart';
import 'package:sofawatch/features/profile/domain/models/data_import_preview.dart';
import 'package:sofawatch/features/profile/domain/models/data_import_result.dart';

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

    test('imports data and parses complete import result', () async {
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
          expect(options.path, endsWith('/users/me/import'));
          expect(options.data, jsonDecode(json));

          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: const <String, dynamic>{
                'library': <String, dynamic>{
                  'shows': <String, dynamic>{
                    'created': 4,
                    'updated': 2,
                    'unchanged': 6,
                    'failed': 1,
                  },
                  'movies': <String, dynamic>{
                    'created': 3,
                    'updated': 1,
                    'unchanged': 3,
                    'failed': 0,
                  },
                },
                'history': <String, dynamic>{
                  'episodes': <String, dynamic>{
                    'created': 130,
                    'skipped': 10,
                    'failed': 5,
                  },
                  'movies': <String, dynamic>{
                    'created': 15,
                    'skipped': 4,
                    'failed': 0,
                  },
                },
              },
            ),
          );
        },
      );

      final DataImportResult result = await repository.importData(json);

      expect(result.library.shows.created, 4);
      expect(result.library.shows.updated, 2);
      expect(result.library.shows.unchanged, 6);
      expect(result.library.shows.failed, 1);

      expect(result.library.movies.created, 3);
      expect(result.library.movies.updated, 1);
      expect(result.library.movies.unchanged, 3);
      expect(result.library.movies.failed, 0);

      expect(result.history.episodes.created, 130);
      expect(result.history.episodes.skipped, 10);
      expect(result.history.episodes.failed, 5);

      expect(result.history.movies.created, 15);
      expect(result.history.movies.skipped, 4);
      expect(result.history.movies.failed, 0);

      expect(result.hasFailures, isTrue);
    });

    test('parses a successful import without failures', () async {
      final ApiDataTransferRepository repository = _createRepository(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: const <String, dynamic>{
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
                    'created': 2,
                    'skipped': 0,
                    'failed': 0,
                  },
                  'movies': <String, dynamic>{
                    'created': 1,
                    'skipped': 0,
                    'failed': 0,
                  },
                },
              },
            ),
          );
        },
      );

      final DataImportResult result = await repository.importData(
        '{"format":"sofawatch-export","version":1}',
      );

      expect(result.hasFailures, isFalse);
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

    test('rejects malformed import result response', () async {
      final ApiDataTransferRepository repository = _createRepository(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: const <String, dynamic>{
                'library': <String, dynamic>{
                  'shows': <String, dynamic>{
                    'created': 'invalid',
                    'updated': 0,
                    'unchanged': 0,
                    'failed': 0,
                  },
                  'movies': <String, dynamic>{
                    'created': 0,
                    'updated': 0,
                    'unchanged': 0,
                    'failed': 0,
                  },
                },
                'history': <String, dynamic>{
                  'episodes': <String, dynamic>{
                    'created': 0,
                    'skipped': 0,
                    'failed': 0,
                  },
                  'movies': <String, dynamic>{
                    'created': 0,
                    'skipped': 0,
                    'failed': 0,
                  },
                },
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
