import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/api/api_config.dart';
import 'package:sofawatch/core/api/api_logging_interceptor.dart';
import 'package:sofawatch/core/errors/app_exception.dart';

void main() {
  ApiClient createClientWithAdapter(Dio dio) {
    return ApiClient(
      baseUrl: Uri.parse('https://server.example.com'),
      dio: dio,
    );
  }

  group('ApiClient', () {
    test('configures the API base URL', () {
      final ApiClient client = ApiClient(
        baseUrl: Uri.parse('https://example.com'),
      );

      expect(client.baseUrl, 'https://example.com/api/v1');
    });

    test('removes a trailing slash before adding the API prefix', () {
      final ApiClient client = ApiClient(
        baseUrl: Uri.parse('https://example.com/'),
      );

      expect(client.baseUrl, 'https://example.com/api/v1');
    });

    test('can update the configured server URL', () {
      final ApiClient client = ApiClient(
        baseUrl: Uri.parse('https://example.com'),
      );

      client.configureBaseUrl(Uri.parse('https://second.example.com/'));

      expect(client.baseUrl, 'https://second.example.com/api/v1');
    });

    test('configures request timeouts', () {
      final ApiClient client = ApiClient(
        baseUrl: Uri.parse('https://example.com'),
      );

      expect(client.dio.options.connectTimeout, ApiConfig.connectTimeout);

      expect(client.dio.options.sendTimeout, ApiConfig.sendTimeout);

      expect(client.dio.options.receiveTimeout, ApiConfig.receiveTimeout);
    });

    test('configures default JSON headers', () {
      final ApiClient client = ApiClient(
        baseUrl: Uri.parse('https://example.com'),
      );

      expect(client.dio.options.headers['Accept'], 'application/json');

      expect(client.dio.options.headers['Content-Type'], 'application/json');
    });

    test('supports adding and removing headers', () {
      final ApiClient client = ApiClient(
        baseUrl: Uri.parse('https://example.com'),
      );

      client.setHeader('Authorization', 'Bearer token');

      expect(client.dio.options.headers['Authorization'], 'Bearer token');

      client.removeHeader('Authorization');

      expect(client.dio.options.headers.containsKey('Authorization'), isFalse);
    });

    test('registers the API logging interceptor', () {
      final ApiClient client = ApiClient(
        baseUrl: Uri.parse('https://example.com'),
      );

      expect(
        client.dio.interceptors.whereType<ApiLoggingInterceptor>(),
        hasLength(1),
      );
    });

    test('uses an injected Dio instance', () {
      final Dio dio = Dio();

      final ApiClient client = ApiClient(
        baseUrl: Uri.parse('https://example.com'),
        dio: dio,
      );

      expect(identical(client.dio, dio), isTrue);
    });

    test('can be created without a server URL', () {
      final ApiClient client = ApiClient();

      expect(client.isConfigured, isFalse);

      expect(client.baseUrl, isEmpty);
    });

    test('reports when a server URL is configured', () {
      final ApiClient client = ApiClient(
        baseUrl: Uri.parse('https://example.com'),
      );

      expect(client.isConfigured, isTrue);
    });

    test('clears the configured server URL', () {
      final ApiClient client = ApiClient(
        baseUrl: Uri.parse('https://example.com'),
      );

      client.clearBaseUrl();

      expect(client.isConfigured, isFalse);

      expect(client.baseUrl, isEmpty);
    });

    test('rejects requests when no server URL is configured', () async {
      final ApiClient client = ApiClient();

      await expectLater(
        client.get<dynamic>('/shows'),
        throwsA(isA<StateError>()),
      );
    });

    test('returns successful responses', () async {
      final ApiClient client = ApiClient(
        baseUrl: Uri.parse('https://server.example.com'),
        dio: Dio(),
      );

      final DioAdapter adapter = DioAdapter(dio: client.dio, printLogs: false);

      adapter.onGet(
        '/health',
        (server) => server.reply(200, <String, dynamic>{'status': 'healthy'}),
      );

      final Response<Map<String, dynamic>> response = await client
          .get<Map<String, dynamic>>('/health');

      expect(response.statusCode, 200);

      expect(response.data, <String, dynamic>{'status': 'healthy'});
    });

    test('maps standardized API errors to AppException', () async {
      final ApiClient client = ApiClient(
        baseUrl: Uri.parse('https://server.example.com'),
        dio: Dio(),
      );

      final DioAdapter adapter = DioAdapter(dio: client.dio, printLogs: false);

      adapter.onGet(
        '/shows/missing',
        (server) => server.reply(404, <String, dynamic>{
          'error': <String, dynamic>{
            'code': 'show_not_found',
            'message': 'The show was not found.',
          },
        }),
      );

      await expectLater(
        client.get<Map<String, dynamic>>('/shows/missing'),
        throwsA(
          isA<AppException>()
              .having(
                (AppException error) => error.type,
                'type',
                AppExceptionType.notFound,
              )
              .having(
                (AppException error) => error.code,
                'code',
                'show_not_found',
              )
              .having(
                (AppException error) => error.statusCode,
                'statusCode',
                404,
              ),
        ),
      );
    });

    test('maps malformed server errors to a fallback AppException', () async {
      final ApiClient client = ApiClient(
        baseUrl: Uri.parse('https://server.example.com'),
        dio: Dio(),
      );

      final DioAdapter adapter = DioAdapter(dio: client.dio, printLogs: false);

      adapter.onGet(
        '/shows',
        (server) => server.reply(500, 'unexpected response'),
      );

      await expectLater(
        client.get<dynamic>('/shows'),
        throwsA(
          isA<AppException>()
              .having(
                (AppException error) => error.type,
                'type',
                AppExceptionType.server,
              )
              .having(
                (AppException error) => error.message,
                'message',
                'The server encountered an error.',
              ),
        ),
      );
    });

    test('executes POST requests', () async {
      final Dio dio = Dio();

      final ApiClient client = createClientWithAdapter(dio);

      final DioAdapter adapter = DioAdapter(dio: client.dio);

      adapter.onPost(
        '/shows',
        (server) => server.reply(201, <String, dynamic>{'id': 'show-1'}),
        data: <String, dynamic>{'title': 'Test Show'},
      );

      final Response<Map<String, dynamic>> response = await client
          .post<Map<String, dynamic>>(
            '/shows',
            data: <String, dynamic>{'title': 'Test Show'},
          );

      expect(response.statusCode, 201);

      expect(response.data?['id'], 'show-1');
    });

    test('executes PUT requests', () async {
      final Dio dio = Dio();

      final ApiClient client = createClientWithAdapter(dio);

      final DioAdapter adapter = DioAdapter(dio: client.dio);

      adapter.onPut(
        '/shows/show-1',
        (server) => server.reply(200, <String, dynamic>{'updated': true}),
        data: <String, dynamic>{'title': 'Updated Show'},
      );

      final Response<Map<String, dynamic>> response = await client
          .put<Map<String, dynamic>>(
            '/shows/show-1',
            data: <String, dynamic>{'title': 'Updated Show'},
          );

      expect(response.data?['updated'], isTrue);
    });

    test('executes PATCH requests', () async {
      final Dio dio = Dio();

      final ApiClient client = createClientWithAdapter(dio);

      final DioAdapter adapter = DioAdapter(dio: client.dio);

      adapter.onPatch(
        '/shows/show-1',
        (server) => server.reply(200, <String, dynamic>{'updated': true}),
        data: <String, dynamic>{'status': 'watching'},
      );

      final Response<Map<String, dynamic>> response = await client
          .patch<Map<String, dynamic>>(
            '/shows/show-1',
            data: <String, dynamic>{'status': 'watching'},
          );

      expect(response.data?['updated'], isTrue);
    });

    test('executes DELETE requests', () async {
      final Dio dio = Dio();

      final ApiClient client = createClientWithAdapter(dio);

      final DioAdapter adapter = DioAdapter(dio: client.dio);

      adapter.onDelete('/shows/show-1', (server) => server.reply(204, null));

      final Response<void> response = await client.delete<void>(
        '/shows/show-1',
      );

      expect(response.statusCode, 204);
    });

    test('maps Dio errors for every HTTP method', () async {
      final List<Future<Response<dynamic>> Function(ApiClient)> requests =
          <Future<Response<dynamic>> Function(ApiClient)>[
            (ApiClient client) => client.get<dynamic>('/resource'),
            (ApiClient client) => client.post<dynamic>('/resource'),
            (ApiClient client) => client.put<dynamic>('/resource'),
            (ApiClient client) => client.patch<dynamic>('/resource'),
            (ApiClient client) => client.delete<dynamic>('/resource'),
          ];

      for (final Future<Response<dynamic>> Function(ApiClient) request
          in requests) {
        final Dio dio = Dio();

        final ApiClient client = ApiClient(
          baseUrl: Uri.parse('https://server.example.com'),
          dio: dio,
        );

        dio.httpClientAdapter = _ThrowingHttpClientAdapter();

        await expectLater(
          request(client),
          throwsA(
            isA<AppException>().having(
              (AppException exception) => exception.type,
              'type',
              AppExceptionType.connection,
            ),
          ),
        );
      }
    });
    group('authentication', () {
      test('adds current Bearer access token to requests', () async {
        String? accessToken = 'first-access-token';

        final Dio dio = Dio();

        late RequestOptions capturedRequest;

        dio.httpClientAdapter = _CapturingHttpClientAdapter(
          onRequest: (RequestOptions options) {
            capturedRequest = options;
          },
        );

        final ApiClient client = ApiClient(
          baseUrl: Uri.parse('http://localhost:8000'),
          dio: dio,
          accessTokenProvider: () => accessToken,
        );

        await client.get<void>('/users/me');

        expect(
          capturedRequest.headers['Authorization'],
          'Bearer first-access-token',
        );
      });

      test('uses latest access token for every request', () async {
        String? accessToken = 'first-access-token';

        final Dio dio = Dio();

        final List<RequestOptions> requests = <RequestOptions>[];

        dio.httpClientAdapter = _CapturingHttpClientAdapter(
          onRequest: requests.add,
        );

        final ApiClient client = ApiClient(
          baseUrl: Uri.parse('http://localhost:8000'),
          dio: dio,
          accessTokenProvider: () => accessToken,
        );

        await client.get<void>('/users/me');

        accessToken = 'second-access-token';

        await client.get<void>('/users/me');

        expect(
          requests[0].headers['Authorization'],
          'Bearer first-access-token',
        );

        expect(
          requests[1].headers['Authorization'],
          'Bearer second-access-token',
        );
      });

      test('does not send Authorization when no access token exists', () async {
        final Dio dio = Dio();

        late RequestOptions capturedRequest;

        dio.httpClientAdapter = _CapturingHttpClientAdapter(
          onRequest: (RequestOptions options) {
            capturedRequest = options;
          },
        );

        final ApiClient client = ApiClient(
          baseUrl: Uri.parse('http://localhost:8000'),
          dio: dio,
          accessTokenProvider: () => null,
        );

        await client.get<void>('/auth/setup');

        expect(capturedRequest.headers.containsKey('Authorization'), isFalse);
      });

      test(
        'removes stale Authorization header after access token is cleared',
        () async {
          String? accessToken = 'access-token';

          final Dio dio = Dio();

          final List<RequestOptions> requests = <RequestOptions>[];

          dio.httpClientAdapter = _CapturingHttpClientAdapter(
            onRequest: requests.add,
          );

          final ApiClient client = ApiClient(
            baseUrl: Uri.parse('http://localhost:8000'),
            dio: dio,
            accessTokenProvider: () => accessToken,
          );

          await client.get<void>('/users/me');

          accessToken = null;

          await client.get<void>('/auth/setup');

          expect(
            requests.first.headers['Authorization'],
            'Bearer access-token',
          );

          expect(requests.last.headers.containsKey('Authorization'), isFalse);
        },
      );
    });
  });
}

class _ThrowingHttpClientAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
    );
  }

  @override
  void close({bool force = false}) {}
}

final class _CapturingHttpClientAdapter implements HttpClientAdapter {
  _CapturingHttpClientAdapter({required this.onRequest});

  final void Function(RequestOptions options) onRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    onRequest(options);

    return ResponseBody.fromString(
      '{}',
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
