import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/server/data/repositories/api_server_repository.dart';
import 'package:sofawatch/features/server/domain/models/server_health.dart';

const Map<String, dynamic> _environmentJson = <String, dynamic>{
  'app_name': 'SofaWatch',
  'environment': 'test',
  'debug': false,
  'api_host': '127.0.0.1',
  'api_port': 8000,
  'default_language': 'en-US',
  'supported_languages': <String>['en-US', 'pt-PT'],
  'metadata_refresh_days': 7,
};

const Map<String, dynamic> _storageJson = <String, dynamic>{
  'data_directory': './data',
  'writable': true,
  'total_space_bytes': 1000000,
  'used_space_bytes': 400000,
  'free_space_bytes': 600000,
  'usage_percentage': 40.0,
  'image_cache': <String, dynamic>{
    'total_size_bytes': 375,
    'total_files': 4,
    'breakdown': <String, dynamic>{
      'shows': <String, dynamic>{'size_bytes': 300, 'files': 2},
      'seasons': <String, dynamic>{'size_bytes': 50, 'files': 1},
      'episodes': <String, dynamic>{'size_bytes': 25, 'files': 1},
    },
  },
};

const Map<String, dynamic> _runtimeJson = <String, dynamic>{
  'python_version': '3.12.11',
  'platform': 'Linux',
  'started_at': '2026-08-20T14:30:00Z',
};

void main() {
  group('ApiServerRepository', () {
    test('loads Server health', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                expect(options.path, endsWith('/server/health'));

                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: const <String, dynamic>{
                      'status': 'healthy',
                      'checked_at': '2026-08-20T15:30:00+00:00',
                      'uptime_seconds': 86400,
                      'environment': _environmentJson,
                      'storage': _storageJson,
                      'runtime': _runtimeJson,
                      'database': <String, dynamic>{
                        'status': 'healthy',
                        'engine': 'sqlite',
                        'latency_ms': 1.42,
                        'size_bytes': 1048576,
                        'wal_size_bytes': 8192,
                        'integrity_check': 'ok',
                        'foreign_key_check': 'ok',
                        'migration': <String, dynamic>{
                          'revision': 'bb784a0a2cdc',
                          'message': 'add admin flag to users',
                        },
                      },
                      'tmdb': <String, dynamic>{
                        'status': 'healthy',
                        'configured': true,
                        'latency_ms': 212.5,
                      },
                    },
                  ),
                );
              },
        ),
      );

      final ApiServerRepository repository = ApiServerRepository(
        ApiClient(baseUrl: Uri.parse('https://server.example.com'), dio: dio),
      );

      final ServerHealth health = await repository.getHealth();

      expect(health.status, ServerHealthStatus.healthy);

      expect(health.checkedAt, DateTime.parse('2026-08-20T15:30:00+00:00'));

      expect(health.uptimeSeconds, 86400);

      expect(health.database.status, ServerComponentStatus.healthy);

      expect(health.database.latencyMs, 1.42);

      expect(health.tmdb.status, ServerComponentStatus.healthy);

      expect(health.tmdb.configured, isTrue);

      expect(health.tmdb.latencyMs, 212.5);

      expect(health.isHealthy, isTrue);

      expect(health.database.engine, 'sqlite');
      expect(health.database.sizeBytes, 1048576);
      expect(health.database.walSizeBytes, 8192);
      expect(health.database.integrityCheck, ServerDatabaseCheckStatus.ok);
      expect(health.database.foreignKeyCheck, ServerDatabaseCheckStatus.ok);
      expect(health.database.migration.revision, 'bb784a0a2cdc');
      expect(health.database.migration.message, 'add admin flag to users');

      expect(health.environment.appName, 'SofaWatch');
      expect(health.environment.environment, 'test');
      expect(health.environment.debug, isFalse);
      expect(health.environment.apiHost, '127.0.0.1');
      expect(health.environment.apiPort, 8000);
      expect(health.environment.defaultLanguage, 'en-US');
      expect(health.environment.supportedLanguages, <String>['en-US', 'pt-PT']);
      expect(health.environment.metadataRefreshDays, 7);

      expect(health.storage.dataDirectory, './data');
      expect(health.storage.writable, isTrue);
      expect(health.storage.totalSpaceBytes, 1000000);
      expect(health.storage.usedSpaceBytes, 400000);
      expect(health.storage.freeSpaceBytes, 600000);
      expect(health.storage.usagePercentage, 40.0);

      expect(health.storage.imageCache.totalSizeBytes, 375);
      expect(health.storage.imageCache.totalFiles, 4);

      expect(health.storage.imageCache.breakdown.shows.sizeBytes, 300);
      expect(health.storage.imageCache.breakdown.shows.files, 2);

      expect(health.storage.imageCache.breakdown.seasons.sizeBytes, 50);
      expect(health.storage.imageCache.breakdown.seasons.files, 1);

      expect(health.storage.imageCache.breakdown.episodes.sizeBytes, 25);
      expect(health.storage.imageCache.breakdown.episodes.files, 1);

      expect(health.runtime.pythonVersion, '3.12.11');
      expect(health.runtime.platform, 'Linux');
      expect(health.runtime.startedAt, DateTime.parse('2026-08-20T14:30:00Z'));
    });

    test('loads degraded Server health', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: const <String, dynamic>{
                      'status': 'degraded',
                      'checked_at': '2026-08-20T15:30:00Z',
                      'uptime_seconds': 120,
                      'environment': _environmentJson,
                      'storage': _storageJson,
                      'runtime': _runtimeJson,
                      'database': <String, dynamic>{
                        'status': 'healthy',
                        'engine': 'sqlite',
                        'latency_ms': 0.8,
                        'size_bytes': null,
                        'wal_size_bytes': null,
                        'integrity_check': 'ok',
                        'foreign_key_check': 'ok',
                        'migration': <String, dynamic>{
                          'revision': null,
                          'message': null,
                        },
                      },
                      'tmdb': <String, dynamic>{
                        'status': 'unavailable',
                        'configured': true,
                        'latency_ms': null,
                      },
                    },
                  ),
                );
              },
        ),
      );

      final ApiServerRepository repository = ApiServerRepository(
        ApiClient(baseUrl: Uri.parse('https://server.example.com'), dio: dio),
      );

      final ServerHealth health = await repository.getHealth();

      expect(health.status, ServerHealthStatus.degraded);

      expect(health.isHealthy, isFalse);

      expect(health.database.isHealthy, isTrue);

      expect(health.tmdb.isHealthy, isFalse);

      expect(health.tmdb.configured, isTrue);

      expect(health.tmdb.latencyMs, isNull);
    });

    test('loads unconfigured TMDB status', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: const <String, dynamic>{
                      'status': 'degraded',
                      'checked_at': '2026-08-20T15:30:00Z',
                      'uptime_seconds': 30,
                      'environment': _environmentJson,
                      'storage': _storageJson,
                      'runtime': _runtimeJson,
                      'database': <String, dynamic>{
                        'status': 'healthy',
                        'engine': 'sqlite',
                        'latency_ms': 1,
                        'size_bytes': null,
                        'wal_size_bytes': null,
                        'integrity_check': 'ok',
                        'foreign_key_check': 'ok',
                        'migration': <String, dynamic>{
                          'revision': null,
                          'message': null,
                        },
                      },
                      'tmdb': <String, dynamic>{
                        'status': 'unavailable',
                        'configured': false,
                        'latency_ms': null,
                      },
                    },
                  ),
                );
              },
        ),
      );

      final ApiServerRepository repository = ApiServerRepository(
        ApiClient(baseUrl: Uri.parse('https://server.example.com'), dio: dio),
      );

      final ServerHealth health = await repository.getHealth();

      expect(health.tmdb.configured, isFalse);

      expect(health.tmdb.status, ServerComponentStatus.unavailable);
    });

    test('maps missing response body to invalid data', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: null,
                  ),
                );
              },
        ),
      );

      final ApiServerRepository repository = ApiServerRepository(
        ApiClient(baseUrl: Uri.parse('https://server.example.com'), dio: dio),
      );

      expect(
        repository.getHealth(),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('maps invalid Server health status to invalid data', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: const <String, dynamic>{
                      'status': 'broken',
                      'checked_at': '2026-08-20T15:30:00Z',
                      'uptime_seconds': 30,
                      'environment': _environmentJson,
                      'storage': _storageJson,
                      'runtime': _runtimeJson,
                      'database': <String, dynamic>{
                        'status': 'healthy',
                        'engine': 'sqlite',
                        'latency_ms': 1,
                        'size_bytes': null,
                        'wal_size_bytes': null,
                        'integrity_check': 'ok',
                        'foreign_key_check': 'ok',
                        'migration': <String, dynamic>{
                          'revision': null,
                          'message': null,
                        },
                      },
                      'tmdb': <String, dynamic>{
                        'status': 'healthy',
                        'configured': true,
                        'latency_ms': 200,
                      },
                    },
                  ),
                );
              },
        ),
      );

      final ApiServerRepository repository = ApiServerRepository(
        ApiClient(baseUrl: Uri.parse('https://server.example.com'), dio: dio),
      );

      expect(
        repository.getHealth(),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('maps invalid component latency to invalid data', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: const <String, dynamic>{
                      'status': 'healthy',
                      'checked_at': '2026-08-20T15:30:00Z',
                      'uptime_seconds': 30,
                      'environment': _environmentJson,
                      'storage': _storageJson,
                      'runtime': _runtimeJson,
                      'database': <String, dynamic>{
                        'status': 'healthy',
                        'engine': 'sqlite',
                        'latency_ms': -1,
                        'size_bytes': null,
                        'wal_size_bytes': null,
                        'integrity_check': 'ok',
                        'foreign_key_check': 'ok',
                        'migration': <String, dynamic>{
                          'revision': null,
                          'message': null,
                        },
                      },
                      'tmdb': <String, dynamic>{
                        'status': 'healthy',
                        'configured': true,
                        'latency_ms': 200,
                      },
                    },
                  ),
                );
              },
        ),
      );

      final ApiServerRepository repository = ApiServerRepository(
        ApiClient(baseUrl: Uri.parse('https://server.example.com'), dio: dio),
      );

      expect(
        repository.getHealth(),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });
    test('loads failed Database checks', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: const <String, dynamic>{
                      'status': 'degraded',
                      'checked_at': '2026-08-20T15:30:00Z',
                      'uptime_seconds': 30,
                      'environment': _environmentJson,
                      'storage': _storageJson,
                      'runtime': _runtimeJson,
                      'database': <String, dynamic>{
                        'status': 'healthy',
                        'engine': 'sqlite',
                        'latency_ms': 1,
                        'size_bytes': 1024,
                        'wal_size_bytes': 0,
                        'integrity_check': 'failed',
                        'foreign_key_check': 'unavailable',
                        'migration': <String, dynamic>{
                          'revision': null,
                          'message': null,
                        },
                      },
                      'tmdb': <String, dynamic>{
                        'status': 'healthy',
                        'configured': true,
                        'latency_ms': 200,
                      },
                    },
                  ),
                );
              },
        ),
      );

      final ApiServerRepository repository = ApiServerRepository(
        ApiClient(baseUrl: Uri.parse('https://server.example.com'), dio: dio),
      );

      final ServerHealth health = await repository.getHealth();

      expect(health.database.integrityCheck, ServerDatabaseCheckStatus.failed);

      expect(
        health.database.foreignKeyCheck,
        ServerDatabaseCheckStatus.unavailable,
      );
    });
    test('maps invalid Database check status to invalid data', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: const <String, dynamic>{
                      'status': 'healthy',
                      'checked_at': '2026-08-20T15:30:00Z',
                      'uptime_seconds': 30,
                      'environment': _environmentJson,
                      'storage': _storageJson,
                      'runtime': _runtimeJson,
                      'database': <String, dynamic>{
                        'status': 'healthy',
                        'engine': 'sqlite',
                        'latency_ms': 1,
                        'size_bytes': null,
                        'wal_size_bytes': null,
                        'integrity_check': 'broken',
                        'foreign_key_check': 'ok',
                        'migration': <String, dynamic>{
                          'revision': null,
                          'message': null,
                        },
                      },
                      'tmdb': <String, dynamic>{
                        'status': 'healthy',
                        'configured': true,
                        'latency_ms': 200,
                      },
                    },
                  ),
                );
              },
        ),
      );

      final ApiServerRepository repository = ApiServerRepository(
        ApiClient(baseUrl: Uri.parse('https://server.example.com'), dio: dio),
      );

      expect(
        repository.getHealth(),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });
    test('maps invalid storage usage percentage to invalid data', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, dynamic>{
                      'status': 'healthy',
                      'checked_at': '2026-08-20T15:30:00Z',
                      'uptime_seconds': 30,
                      'environment': _environmentJson,
                      'storage': <String, dynamic>{
                        ..._storageJson,
                        'usage_percentage': 101,
                      },
                      'runtime': _runtimeJson,
                      'database': <String, dynamic>{
                        'status': 'healthy',
                        'engine': 'sqlite',
                        'latency_ms': 1,
                        'size_bytes': null,
                        'wal_size_bytes': null,
                        'integrity_check': 'ok',
                        'foreign_key_check': 'ok',
                        'migration': <String, dynamic>{
                          'revision': null,
                          'message': null,
                        },
                      },
                      'tmdb': <String, dynamic>{
                        'status': 'healthy',
                        'configured': true,
                        'latency_ms': 200,
                      },
                    },
                  ),
                );
              },
        ),
      );

      final ApiServerRepository repository = ApiServerRepository(
        ApiClient(baseUrl: Uri.parse('https://server.example.com'), dio: dio),
      );

      expect(
        repository.getHealth(),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });
    test('maps invalid supported languages to invalid data', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <String, dynamic>{
                      'status': 'healthy',
                      'checked_at': '2026-08-20T15:30:00Z',
                      'uptime_seconds': 30,
                      'environment': <String, dynamic>{
                        ..._environmentJson,
                        'supported_languages': <Object?>['en-US', 123],
                      },
                      'storage': _storageJson,
                      'runtime': _runtimeJson,
                      'database': <String, dynamic>{
                        'status': 'healthy',
                        'engine': 'sqlite',
                        'latency_ms': 1,
                        'size_bytes': null,
                        'wal_size_bytes': null,
                        'integrity_check': 'ok',
                        'foreign_key_check': 'ok',
                        'migration': <String, dynamic>{
                          'revision': null,
                          'message': null,
                        },
                      },
                      'tmdb': <String, dynamic>{
                        'status': 'healthy',
                        'configured': true,
                        'latency_ms': 200,
                      },
                    },
                  ),
                );
              },
        ),
      );

      final ApiServerRepository repository = ApiServerRepository(
        ApiClient(baseUrl: Uri.parse('https://server.example.com'), dio: dio),
      );

      expect(
        repository.getHealth(),
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
