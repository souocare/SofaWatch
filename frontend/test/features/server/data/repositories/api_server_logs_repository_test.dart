import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/server/data/repositories/api_server_repository.dart';
import 'package:sofawatch/features/server/domain/models/server_logs.dart';

void main() {
  group('ApiServerRepository Logs', () {
    test('loads paginated Server Logs', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                expect(options.path, endsWith('/server/logs'));

                expect(options.queryParameters, <String, dynamic>{
                  'offset': 0,
                  'limit': 50,
                });

                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: const <String, dynamic>{
                      'items': <Map<String, dynamic>>[
                        <String, dynamic>{
                          'timestamp': '2026-08-20T15:30:00Z',
                          'level': 'ERROR',
                          'logger': 'app.jobs.executor',
                          'message': 'Metadata sync failed.',
                          'component': 'worker',
                        },
                        <String, dynamic>{
                          'timestamp': '2026-08-20T15:00:00Z',
                          'level': 'INFO',
                          'logger': 'app.main',
                          'message': 'SofaWatch API starting',
                          'component': 'api',
                        },
                      ],
                      'offset': 0,
                      'limit': 50,
                      'total': 2,
                      'has_next': false,
                    },
                  ),
                );
              },
        ),
      );

      final ApiServerRepository repository = ApiServerRepository(
        ApiClient(baseUrl: Uri.parse('https://server.example.com'), dio: dio),
      );

      final ServerLogsPage page = await repository.getLogs();

      expect(page.items, hasLength(2));

      expect(page.offset, 0);

      expect(page.limit, 50);

      expect(page.total, 2);

      expect(page.hasNext, isFalse);

      expect(page.items.first.level, ServerLogLevel.error);

      expect(page.items.first.logger, 'app.jobs.executor');

      expect(page.items.first.message, 'Metadata sync failed.');

      expect(page.items.first.component, ServerLogComponent.worker);
    });

    test('passes log level and pagination', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                expect(options.queryParameters, <String, dynamic>{
                  'offset': 50,
                  'limit': 25,
                  'level': 'WARNING',
                });

                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: const <String, dynamic>{
                      'items': <dynamic>[],
                      'offset': 50,
                      'limit': 25,
                      'total': 100,
                      'has_next': true,
                    },
                  ),
                );
              },
        ),
      );

      final ApiServerRepository repository = ApiServerRepository(
        ApiClient(baseUrl: Uri.parse('https://server.example.com'), dio: dio),
      );

      final ServerLogsPage page = await repository.getLogs(
        level: ServerLogLevel.warning,
        offset: 50,
        limit: 25,
      );

      expect(page.offset, 50);

      expect(page.limit, 25);

      expect(page.hasNext, isTrue);
    });

    test('maps invalid Server Log entry to invalid data', () async {
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
                      'items': <Map<String, dynamic>>[
                        <String, dynamic>{
                          'timestamp': '2026-08-20T15:30:00Z',
                          'level': 'BROKEN',
                          'logger': 'app.main',
                          'message': 'Invalid.',
                          'component': 'api',
                        },
                      ],
                      'offset': 0,
                      'limit': 50,
                      'total': 1,
                      'has_next': false,
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
        repository.getLogs(),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('maps missing Server Logs body to invalid data', () async {
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
        repository.getLogs(),
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
