import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/data/repositories/api_registration_repository.dart';
import 'package:sofawatch/features/auth/data/storage/in_memory_access_token_store.dart';

void main() {
  group('ApiRegistrationRepository', () {
    test('returns true when registration is open', () async {
      final ApiClient apiClient = _createApiClient(
        onRequest: (options, handler) {
          expect(options.method, 'GET');
          expect(options.path, '/auth/registration');

          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: const <String, dynamic>{'open_registration': true},
            ),
          );
        },
      );

      final ApiRegistrationRepository repository = ApiRegistrationRepository(
        apiClient: apiClient,
        accessTokenStore: InMemoryAccessTokenStore(),
        isWeb: true,
      );

      expect(await repository.isRegistrationOpen(), isTrue);
    });

    test('returns false when registration is closed', () async {
      final ApiClient apiClient = _createApiClient(
        onRequest: (options, handler) {
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: const <String, dynamic>{'open_registration': false},
            ),
          );
        },
      );

      final ApiRegistrationRepository repository = ApiRegistrationRepository(
        apiClient: apiClient,
        accessTokenStore: InMemoryAccessTokenStore(),
        isWeb: true,
      );

      expect(await repository.isRegistrationOpen(), isFalse);
    });

    test('rejects an invalid registration status response', () async {
      final ApiClient apiClient = _createApiClient(
        onRequest: (options, handler) {
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: const <String, dynamic>{'open_registration': 'yes'},
            ),
          );
        },
      );

      final ApiRegistrationRepository repository = ApiRegistrationRepository(
        apiClient: apiClient,
        accessTokenStore: InMemoryAccessTokenStore(),
        isWeb: true,
      );

      await expectLater(
        repository.isRegistrationOpen(),
        throwsA(isA<AppException>()),
      );
    });

    test('registers a user and stores the access token', () async {
      final InMemoryAccessTokenStore tokenStore = InMemoryAccessTokenStore();

      final ApiClient apiClient = _createApiClient(
        onRequest: (options, handler) {
          expect(options.method, 'POST');
          expect(options.path, '/auth/register');

          final Map<String, dynamic> body = Map<String, dynamic>.from(
            options.data as Map,
          );

          expect(body, <String, dynamic>{
            'username': 'newuser',
            'display_name': 'New User',
            'email': 'new@example.com',
            'password': 'secure-password',
          });

          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 201,
              data: const <String, dynamic>{
                'access_token': 'registered-access-token',
                'token_type': 'bearer',
                'expires_in': 900,
              },
            ),
          );
        },
      );

      final ApiRegistrationRepository repository = ApiRegistrationRepository(
        apiClient: apiClient,
        accessTokenStore: tokenStore,
        isWeb: true,
      );

      final session = await repository.register(
        username: '  newuser  ',
        displayName: '  New User  ',
        email: '  new@example.com  ',
        password: 'secure-password',
      );

      expect(session.accessToken, 'registered-access-token');
      expect(session.expiresIn, const Duration(seconds: 900));
      expect(tokenStore.token, 'registered-access-token');
    });

    test('omits email when it is empty', () async {
      final ApiClient apiClient = _createApiClient(
        onRequest: (options, handler) {
          final Map<String, dynamic> body = Map<String, dynamic>.from(
            options.data as Map,
          );

          expect(body.containsKey('email'), isFalse);

          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 201,
              data: const <String, dynamic>{
                'access_token': 'access-token',
                'token_type': 'bearer',
                'expires_in': 900,
              },
            ),
          );
        },
      );

      final ApiRegistrationRepository repository = ApiRegistrationRepository(
        apiClient: apiClient,
        accessTokenStore: InMemoryAccessTokenStore(),
        isWeb: true,
      );

      await repository.register(
        username: 'newuser',
        displayName: 'New User',
        email: '  ',
        password: 'secure-password',
      );
    });

    test('propagates registration_closed from the backend', () async {
      final ApiClient apiClient = _createApiClient(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 403,
                data: const <String, dynamic>{
                  'error': <String, dynamic>{
                    'code': 'registration_closed',
                    'message': 'Account registration is currently closed.',
                  },
                },
              ),
              type: DioExceptionType.badResponse,
            ),
          );
        },
      );

      final ApiRegistrationRepository repository = ApiRegistrationRepository(
        apiClient: apiClient,
        accessTokenStore: InMemoryAccessTokenStore(),
        isWeb: true,
      );

      await expectLater(
        repository.register(
          username: 'newuser',
          displayName: 'New User',
          password: 'secure-password',
        ),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            'registration_closed',
          ),
        ),
      );
    });

    test('does not store a token from an invalid response', () async {
      final InMemoryAccessTokenStore tokenStore = InMemoryAccessTokenStore();

      final ApiClient apiClient = _createApiClient(
        onRequest: (options, handler) {
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 201,
              data: const <String, dynamic>{
                'access_token': '',
                'token_type': 'bearer',
                'expires_in': 900,
              },
            ),
          );
        },
      );

      final ApiRegistrationRepository repository = ApiRegistrationRepository(
        apiClient: apiClient,
        accessTokenStore: tokenStore,
        isWeb: true,
      );

      await expectLater(
        repository.register(
          username: 'newuser',
          displayName: 'New User',
          password: 'secure-password',
        ),
        throwsA(isA<AppException>()),
      );

      expect(tokenStore.token, isNull);
    });

    test('does not allow registration on native platforms', () async {
      final ApiClient apiClient = _createApiClient(
        onRequest: (options, handler) {
          fail('Native registration must not make an HTTP request.');
        },
      );

      final ApiRegistrationRepository repository = ApiRegistrationRepository(
        apiClient: apiClient,
        accessTokenStore: InMemoryAccessTokenStore(),
        isWeb: false,
      );

      await expectLater(
        repository.register(
          username: 'newuser',
          displayName: 'New User',
          password: 'secure-password',
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}

ApiClient _createApiClient({
  required void Function(
    RequestOptions options,
    RequestInterceptorHandler handler,
  )
  onRequest,
}) {
  final Dio dio = Dio();

  dio.interceptors.add(InterceptorsWrapper(onRequest: onRequest));

  return ApiClient(baseUrl: Uri.parse('https://sofawatch.test'), dio: dio);
}
