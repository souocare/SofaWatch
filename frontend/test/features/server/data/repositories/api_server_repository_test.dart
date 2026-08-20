import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/server/data/repositories/api_server_repository.dart';
import 'package:sofawatch/features/server/domain/models/server_health.dart';

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
                      'database': <String, dynamic>{
                        'status': 'healthy',
                        'latency_ms': 1.42,
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
                      'database': <String, dynamic>{
                        'status': 'healthy',
                        'latency_ms': 0.8,
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
                      'database': <String, dynamic>{
                        'status': 'healthy',
                        'latency_ms': 1,
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
                      'database': <String, dynamic>{
                        'status': 'healthy',
                        'latency_ms': 1,
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
                      'database': <String, dynamic>{
                        'status': 'healthy',
                        'latency_ms': -1,
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
