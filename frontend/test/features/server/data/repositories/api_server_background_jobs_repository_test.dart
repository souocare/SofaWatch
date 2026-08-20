import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/server/data/repositories/api_server_repository.dart';
import 'package:sofawatch/features/server/domain/models/background_job.dart';

void main() {
  group('ApiServerRepository background jobs', () {
    test('loads background jobs', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                expect(options.path, endsWith('/background-jobs'));

                handler.resolve(
                  Response<List<dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <dynamic>[
                      <String, dynamic>{
                        'id': 'job-1',
                        'key': 'metadata_sync',
                        'name': 'Metadata sync',
                        'schedule': 'Every 8h',
                        'status': 'success',
                        'last_started_at': '2026-08-20T12:00:00Z',
                        'last_finished_at': '2026-08-20T12:00:11Z',
                        'last_duration_ms': 11000,
                        'last_error': null,
                        'next_run_at': '2026-08-20T20:00:00Z',
                        'last_result': <String, dynamic>{
                          'checked': 140,
                          'refreshed': 23,
                          'skipped': 117,
                          'failed': 0,
                        },
                      },
                    ],
                  ),
                );
              },
        ),
      );

      final ApiServerRepository repository = ApiServerRepository(
        ApiClient(baseUrl: Uri.parse('https://server.example.com'), dio: dio),
      );

      final List<BackgroundJob> jobs = await repository.getBackgroundJobs();

      expect(jobs, hasLength(1));

      final BackgroundJob job = jobs.single;

      expect(job.id, 'job-1');
      expect(job.key, 'metadata_sync');
      expect(job.name, 'Metadata sync');
      expect(job.schedule, 'Every 8h');
      expect(job.status, BackgroundJobStatus.success);

      expect(job.lastStartedAt, DateTime.parse('2026-08-20T12:00:00Z'));

      expect(job.lastFinishedAt, DateTime.parse('2026-08-20T12:00:11Z'));

      expect(job.lastDurationMs, 11000);
      expect(job.lastError, isNull);

      expect(job.nextRunAt, DateTime.parse('2026-08-20T20:00:00Z'));

      expect(job.lastResult, isNotNull);
      expect(job.lastResult!.checked, 140);
      expect(job.lastResult!.refreshed, 23);
      expect(job.lastResult!.skipped, 117);
      expect(job.lastResult!.failed, 0);

      expect(job.isRunning, isFalse);
      expect(job.isHealthy, isTrue);
    });

    test('loads background job without previous run', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.resolve(
                  Response<List<dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <dynamic>[
                      <String, dynamic>{
                        'id': 'job-1',
                        'key': 'metadata_sync',
                        'name': 'Metadata sync',
                        'schedule': 'Every 8h',
                        'status': 'idle',
                        'last_started_at': null,
                        'last_finished_at': null,
                        'last_duration_ms': null,
                        'last_error': null,
                        'next_run_at': null,
                        'last_result': null,
                      },
                    ],
                  ),
                );
              },
        ),
      );

      final ApiServerRepository repository = ApiServerRepository(
        ApiClient(baseUrl: Uri.parse('https://server.example.com'), dio: dio),
      );

      final BackgroundJob job = (await repository.getBackgroundJobs()).single;

      expect(job.status, BackgroundJobStatus.idle);
      expect(job.lastStartedAt, isNull);
      expect(job.lastFinishedAt, isNull);
      expect(job.lastDurationMs, isNull);
      expect(job.nextRunAt, isNull);
      expect(job.lastResult, isNull);
      expect(job.isHealthy, isTrue);
    });

    test('runs background job now', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                expect(options.method, 'POST');

                expect(
                  options.path,
                  endsWith('/background-jobs/metadata_sync/run'),
                );

                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 202,
                    data: <String, dynamic>{
                      'job': <String, dynamic>{
                        'id': 'job-1',
                        'key': 'metadata_sync',
                        'name': 'Metadata sync',
                        'schedule': 'Every 8h',
                        'status': 'running',
                        'last_started_at': '2026-08-20T12:00:00Z',
                        'last_finished_at': null,
                        'last_duration_ms': null,
                        'last_error': null,
                        'next_run_at': null,
                        'last_result': null,
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

      final BackgroundJob job = await repository.runBackgroundJob(
        'metadata_sync',
      );

      expect(job.status, BackgroundJobStatus.running);

      expect(job.isRunning, isTrue);
      expect(job.key, 'metadata_sync');
    });

    test('maps invalid background job status to invalid data', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.resolve(
                  Response<List<dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <dynamic>[
                      <String, dynamic>{
                        'id': 'job-1',
                        'key': 'metadata_sync',
                        'name': 'Metadata sync',
                        'schedule': 'Every 8h',
                        'status': 'broken',
                        'last_started_at': null,
                        'last_finished_at': null,
                        'last_duration_ms': null,
                        'last_error': null,
                        'next_run_at': null,
                        'last_result': null,
                      },
                    ],
                  ),
                );
              },
        ),
      );

      final ApiServerRepository repository = ApiServerRepository(
        ApiClient(baseUrl: Uri.parse('https://server.example.com'), dio: dio),
      );

      expect(
        repository.getBackgroundJobs(),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('maps invalid background job result to invalid data', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.resolve(
                  Response<List<dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: <dynamic>[
                      <String, dynamic>{
                        'id': 'job-1',
                        'key': 'metadata_sync',
                        'name': 'Metadata sync',
                        'schedule': 'Every 8h',
                        'status': 'success',
                        'last_started_at': null,
                        'last_finished_at': null,
                        'last_duration_ms': null,
                        'last_error': null,
                        'next_run_at': null,
                        'last_result': <String, dynamic>{
                          'checked': -1,
                          'refreshed': 0,
                          'skipped': 0,
                          'failed': 0,
                        },
                      },
                    ],
                  ),
                );
              },
        ),
      );

      final ApiServerRepository repository = ApiServerRepository(
        ApiClient(baseUrl: Uri.parse('https://server.example.com'), dio: dio),
      );

      expect(
        repository.getBackgroundJobs(),
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
