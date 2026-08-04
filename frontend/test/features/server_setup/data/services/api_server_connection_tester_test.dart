import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/server_setup/data/services/api_server_connection_tester.dart';

void main() {
  group('ApiServerConnectionTester', () {
    late Dio dio;
    late DioAdapter adapter;
    late ApiServerConnectionTester connectionTester;

    setUp(() {
      dio = Dio();

      adapter = DioAdapter(dio: dio);

      connectionTester = ApiServerConnectionTester(dio: dio);
    });

    test('accepts a healthy SofaWatch server', () async {
      adapter.onGet(
        'https://server.example.com/api/v1/health',
        (server) => server.reply(200, <String, dynamic>{'status': 'healthy'}),
      );

      await expectLater(
        connectionTester.testConnection(
          Uri.parse('https://server.example.com'),
        ),
        completes,
      );
    });

    test('preserves the configured server base path', () async {
      adapter.onGet(
        'https://server.example.com/sofawatch/api/v1/health',
        (server) => server.reply(200, <String, dynamic>{'status': 'healthy'}),
      );

      await expectLater(
        connectionTester.testConnection(
          Uri.parse('https://server.example.com/sofawatch/'),
        ),
        completes,
      );
    });

    test('rejects a non-healthy server', () async {
      adapter.onGet(
        'https://server.example.com/api/v1/health',
        (server) => server.reply(200, <String, dynamic>{'status': 'starting'}),
      );

      await expectLater(
        connectionTester.testConnection(
          Uri.parse('https://server.example.com'),
        ),
        throwsA(
          isA<AppException>()
              .having(
                (AppException exception) => exception.type,
                'type',
                AppExceptionType.server,
              )
              .having(
                (AppException exception) => exception.code,
                'code',
                'server_unhealthy',
              ),
        ),
      );
    });

    test('rejects an invalid health response body', () async {
      adapter.onGet(
        'https://server.example.com/api/v1/health',
        (server) => server.reply(200, <String>['unexpected']),
      );

      await expectLater(
        connectionTester.testConnection(
          Uri.parse('https://server.example.com'),
        ),
        throwsA(
          isA<AppException>().having(
            (AppException exception) => exception.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('rejects a health response without a valid status', () async {
      adapter.onGet(
        'https://server.example.com/api/v1/health',
        (server) => server.reply(200, <String, dynamic>{'status': 123}),
      );

      await expectLater(
        connectionTester.testConnection(
          Uri.parse('https://server.example.com'),
        ),
        throwsA(
          isA<AppException>().having(
            (AppException exception) => exception.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('maps connection failures to AppException', () async {
      adapter.onGet(
        'https://server.example.com/api/v1/health',
        (server) => server.throws(
          503,
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/health'),
            type: DioExceptionType.connectionError,
          ),
        ),
      );

      await expectLater(
        connectionTester.testConnection(
          Uri.parse('https://server.example.com'),
        ),
        throwsA(
          isA<AppException>().having(
            (AppException exception) => exception.type,
            'type',
            AppExceptionType.connection,
          ),
        ),
      );
    });

    test('maps connection timeouts to AppException', () async {
      adapter.onGet(
        'https://server.example.com/api/v1/health',
        (server) => server.throws(
          408,
          DioException(
            requestOptions: RequestOptions(path: '/api/v1/health'),
            type: DioExceptionType.connectionTimeout,
          ),
        ),
      );

      await expectLater(
        connectionTester.testConnection(
          Uri.parse('https://server.example.com'),
        ),
        throwsA(
          isA<AppException>().having(
            (AppException exception) => exception.type,
            'type',
            AppExceptionType.connectionTimeout,
          ),
        ),
      );
    });

    test('maps standardized server errors to AppException', () async {
      adapter.onGet(
        'https://server.example.com/api/v1/health',
        (server) => server.reply(503, <String, dynamic>{
          'error': <String, dynamic>{
            'code': 'service_unavailable',
            'message': 'The service is unavailable.',
          },
        }),
      );

      await expectLater(
        connectionTester.testConnection(
          Uri.parse('https://server.example.com'),
        ),
        throwsA(
          isA<AppException>()
              .having(
                (AppException exception) => exception.type,
                'type',
                AppExceptionType.server,
              )
              .having(
                (AppException exception) => exception.code,
                'code',
                'service_unavailable',
              )
              .having(
                (AppException exception) => exception.statusCode,
                'statusCode',
                503,
              ),
        ),
      );
    });
  });
}
