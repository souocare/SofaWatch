import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/data/repositories/api_auth_repository.dart';
import 'package:sofawatch/features/auth/data/storage/in_memory_access_token_store.dart';
import 'package:sofawatch/features/auth/domain/repositories/mobile_refresh_token_store.dart';

void main() {
  group('ApiAuthRepository clearLocalAuthentication', () {
    test('Web clears the access token locally', () async {
      final ApiClient apiClient = _createApiClient(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          fail('clearLocalAuthentication must not make an HTTP request.');
        },
      );

      final InMemoryAccessTokenStore accessTokenStore =
          InMemoryAccessTokenStore()..save('access-token');

      final ApiAuthRepository repository = ApiAuthRepository(
        apiClient: apiClient,
        accessTokenStore: accessTokenStore,
        isWeb: true,
      );

      await repository.clearLocalAuthentication();

      expect(accessTokenStore.token, isNull);
    });

    test('Mobile clears access and refresh credentials locally', () async {
      final ApiClient apiClient = _createApiClient(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          fail('clearLocalAuthentication must not make an HTTP request.');
        },
      );

      final InMemoryAccessTokenStore accessTokenStore =
          InMemoryAccessTokenStore()..save('access-token');

      final _FakeMobileRefreshTokenStore refreshTokenStore =
          _FakeMobileRefreshTokenStore(initialValue: 'refresh-token');

      final ApiAuthRepository repository = ApiAuthRepository(
        apiClient: apiClient,
        accessTokenStore: accessTokenStore,
        mobileRefreshTokenStore: refreshTokenStore,
        isWeb: false,
      );

      await repository.clearLocalAuthentication();

      expect(accessTokenStore.token, isNull);
      expect(refreshTokenStore.value, isNull);
      expect(refreshTokenStore.clearCalls, 1);
    });
  });

  group('ApiAuthRepository restore authentication loss', () {
    test('Mobile clears credentials when refresh token is invalid', () async {
      final ApiClient apiClient = _createApiClient(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 401,
                data: const <String, dynamic>{
                  'error': <String, dynamic>{
                    'code': 'invalid_refresh_token',
                    'message': 'The refresh token is invalid or expired.',
                  },
                },
              ),
              type: DioExceptionType.badResponse,
            ),
          );
        },
      );

      final InMemoryAccessTokenStore accessTokenStore =
          InMemoryAccessTokenStore()..save('expired-access-token');

      final _FakeMobileRefreshTokenStore refreshTokenStore =
          _FakeMobileRefreshTokenStore(initialValue: 'invalid-refresh-token');

      final ApiAuthRepository repository = ApiAuthRepository(
        apiClient: apiClient,
        accessTokenStore: accessTokenStore,
        mobileRefreshTokenStore: refreshTokenStore,
        isWeb: false,
      );

      await expectLater(
        repository.restore(),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.code,
            'code',
            'invalid_refresh_token',
          ),
        ),
      );

      expect(accessTokenStore.token, isNull);
      expect(refreshTokenStore.value, isNull);
      expect(refreshTokenStore.clearCalls, 1);
    });

    test(
      'Mobile preserves credentials when refresh fails transiently',
      () async {
        final ApiClient apiClient = _createApiClient(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    type: DioExceptionType.connectionError,
                  ),
                );
              },
        );

        final InMemoryAccessTokenStore accessTokenStore =
            InMemoryAccessTokenStore()..save('existing-access-token');

        final _FakeMobileRefreshTokenStore refreshTokenStore =
            _FakeMobileRefreshTokenStore(initialValue: 'refresh-token');

        final ApiAuthRepository repository = ApiAuthRepository(
          apiClient: apiClient,
          accessTokenStore: accessTokenStore,
          mobileRefreshTokenStore: refreshTokenStore,
          isWeb: false,
        );

        await expectLater(
          repository.restore(),
          throwsA(
            isA<AppException>().having(
              (AppException error) => error.type,
              'type',
              AppExceptionType.connection,
            ),
          ),
        );

        expect(accessTokenStore.token, 'existing-access-token');
        expect(refreshTokenStore.value, 'refresh-token');
        expect(refreshTokenStore.clearCalls, 0);
      },
    );

    test('Web clears access token when persistent session is invalid', () async {
      final ApiClient apiClient = _createApiClient(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              response: Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 401,
                data: const <String, dynamic>{
                  'error': <String, dynamic>{
                    'code': 'invalid_session',
                    'message':
                        'The authentication session is invalid or expired.',
                  },
                },
              ),
              type: DioExceptionType.badResponse,
            ),
          );
        },
      );

      final InMemoryAccessTokenStore accessTokenStore =
          InMemoryAccessTokenStore()..save('expired-access-token');

      final ApiAuthRepository repository = ApiAuthRepository(
        apiClient: apiClient,
        accessTokenStore: accessTokenStore,
        isWeb: true,
      );

      await expectLater(
        repository.restore(),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.code,
            'code',
            'invalid_session',
          ),
        ),
      );

      expect(accessTokenStore.token, isNull);
    });
  });
  group('ApiAuthRepository logout', () {
    test(
      'Web logout revokes the session and clears the access token',
      () async {
        String? requestedPath;

        final ApiClient apiClient = _createApiClient(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                requestedPath = options.path;

                handler.resolve(
                  Response<void>(requestOptions: options, statusCode: 204),
                );
              },
        );

        final InMemoryAccessTokenStore accessTokenStore =
            InMemoryAccessTokenStore()..save('access-token');

        final ApiAuthRepository repository = ApiAuthRepository(
          apiClient: apiClient,
          accessTokenStore: accessTokenStore,
          isWeb: true,
        );

        await repository.logout();

        expect(requestedPath, endsWith('/auth/logout'));
        expect(accessTokenStore.token, isNull);
      },
    );

    test(
      'Web logout clears the access token even when the backend fails',
      () async {
        final ApiClient apiClient = _createApiClient(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    response: Response<Map<String, dynamic>>(
                      requestOptions: options,
                      statusCode: 500,
                      data: const <String, dynamic>{
                        'error': <String, dynamic>{
                          'code': 'server_error',
                          'message': 'Test server failure.',
                        },
                      },
                    ),
                    type: DioExceptionType.badResponse,
                  ),
                );
              },
        );

        final InMemoryAccessTokenStore accessTokenStore =
            InMemoryAccessTokenStore()..save('access-token');

        final ApiAuthRepository repository = ApiAuthRepository(
          apiClient: apiClient,
          accessTokenStore: accessTokenStore,
          isWeb: true,
        );

        await expectLater(repository.logout(), throwsA(isA<AppException>()));

        expect(accessTokenStore.token, isNull);
      },
    );

    test(
      'Mobile logout sends the refresh token and clears local credentials',
      () async {
        String? requestedPath;
        Object? requestedData;

        final ApiClient apiClient = _createApiClient(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                requestedPath = options.path;
                requestedData = options.data;

                handler.resolve(
                  Response<void>(requestOptions: options, statusCode: 204),
                );
              },
        );

        final InMemoryAccessTokenStore accessTokenStore =
            InMemoryAccessTokenStore()..save('access-token');

        final _FakeMobileRefreshTokenStore refreshTokenStore =
            _FakeMobileRefreshTokenStore(initialValue: 'refresh-token');

        final ApiAuthRepository repository = ApiAuthRepository(
          apiClient: apiClient,
          accessTokenStore: accessTokenStore,
          mobileRefreshTokenStore: refreshTokenStore,
          isWeb: false,
        );

        await repository.logout();

        expect(requestedPath, endsWith('/auth/mobile/logout'));

        expect(requestedData, <String, dynamic>{
          'refresh_token': 'refresh-token',
        });

        expect(accessTokenStore.token, isNull);
        expect(refreshTokenStore.value, isNull);
        expect(refreshTokenStore.clearCalls, 1);
      },
    );

    test(
      'Mobile logout clears local credentials even when revocation fails',
      () async {
        final ApiClient apiClient = _createApiClient(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    response: Response<Map<String, dynamic>>(
                      requestOptions: options,
                      statusCode: 500,
                      data: const <String, dynamic>{
                        'error': <String, dynamic>{
                          'code': 'server_error',
                          'message': 'Test server failure.',
                        },
                      },
                    ),
                    type: DioExceptionType.badResponse,
                  ),
                );
              },
        );

        final InMemoryAccessTokenStore accessTokenStore =
            InMemoryAccessTokenStore()..save('access-token');

        final _FakeMobileRefreshTokenStore refreshTokenStore =
            _FakeMobileRefreshTokenStore(initialValue: 'refresh-token');

        final ApiAuthRepository repository = ApiAuthRepository(
          apiClient: apiClient,
          accessTokenStore: accessTokenStore,
          mobileRefreshTokenStore: refreshTokenStore,
          isWeb: false,
        );

        await expectLater(repository.logout(), throwsA(isA<AppException>()));

        expect(accessTokenStore.token, isNull);
        expect(refreshTokenStore.value, isNull);
        expect(refreshTokenStore.clearCalls, 1);
      },
    );

    test(
      'Mobile logout without a refresh token only clears local credentials',
      () async {
        int requestCount = 0;

        final ApiClient apiClient = _createApiClient(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                requestCount += 1;

                handler.resolve(
                  Response<void>(requestOptions: options, statusCode: 204),
                );
              },
        );

        final InMemoryAccessTokenStore accessTokenStore =
            InMemoryAccessTokenStore()..save('access-token');

        final _FakeMobileRefreshTokenStore refreshTokenStore =
            _FakeMobileRefreshTokenStore();

        final ApiAuthRepository repository = ApiAuthRepository(
          apiClient: apiClient,
          accessTokenStore: accessTokenStore,
          mobileRefreshTokenStore: refreshTokenStore,
          isWeb: false,
        );

        await repository.logout();

        expect(requestCount, 0);
        expect(accessTokenStore.token, isNull);
        expect(refreshTokenStore.value, isNull);
        expect(refreshTokenStore.clearCalls, 1);
      },
    );
  });

  group('ApiAuthRepository logoutEverywhere', () {
    test(
      'Web logout everywhere revokes all sessions and clears access token',
      () async {
        String? requestedPath;

        final ApiClient apiClient = _createApiClient(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                requestedPath = options.path;

                handler.resolve(
                  Response<void>(requestOptions: options, statusCode: 204),
                );
              },
        );

        final InMemoryAccessTokenStore accessTokenStore =
            InMemoryAccessTokenStore()..save('access-token');

        final ApiAuthRepository repository = ApiAuthRepository(
          apiClient: apiClient,
          accessTokenStore: accessTokenStore,
          isWeb: true,
        );

        await repository.logoutEverywhere();

        expect(requestedPath, endsWith('/auth/logout-all'));
        expect(accessTokenStore.token, isNull);
      },
    );

    test(
      'Web logout everywhere clears access token when the backend fails',
      () async {
        final ApiClient apiClient = _createApiClient(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    response: Response<Map<String, dynamic>>(
                      requestOptions: options,
                      statusCode: 500,
                      data: const <String, dynamic>{
                        'error': <String, dynamic>{
                          'code': 'server_error',
                          'message': 'Test server failure.',
                        },
                      },
                    ),
                    type: DioExceptionType.badResponse,
                  ),
                );
              },
        );

        final InMemoryAccessTokenStore accessTokenStore =
            InMemoryAccessTokenStore()..save('access-token');

        final ApiAuthRepository repository = ApiAuthRepository(
          apiClient: apiClient,
          accessTokenStore: accessTokenStore,
          isWeb: true,
        );

        await expectLater(
          repository.logoutEverywhere(),
          throwsA(isA<AppException>()),
        );

        expect(accessTokenStore.token, isNull);
      },
    );

    test(
      'Mobile logout everywhere clears access and refresh credentials',
      () async {
        String? requestedPath;

        final ApiClient apiClient = _createApiClient(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                requestedPath = options.path;

                handler.resolve(
                  Response<void>(requestOptions: options, statusCode: 204),
                );
              },
        );

        final InMemoryAccessTokenStore accessTokenStore =
            InMemoryAccessTokenStore()..save('access-token');

        final _FakeMobileRefreshTokenStore refreshTokenStore =
            _FakeMobileRefreshTokenStore(initialValue: 'refresh-token');

        final ApiAuthRepository repository = ApiAuthRepository(
          apiClient: apiClient,
          accessTokenStore: accessTokenStore,
          mobileRefreshTokenStore: refreshTokenStore,
          isWeb: false,
        );

        await repository.logoutEverywhere();

        expect(requestedPath, endsWith('/auth/logout-all'));
        expect(accessTokenStore.token, isNull);
        expect(refreshTokenStore.value, isNull);
        expect(refreshTokenStore.clearCalls, 1);
      },
    );

    test(
      'Mobile logout everywhere clears local credentials when backend fails',
      () async {
        final ApiClient apiClient = _createApiClient(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    response: Response<Map<String, dynamic>>(
                      requestOptions: options,
                      statusCode: 500,
                      data: const <String, dynamic>{
                        'error': <String, dynamic>{
                          'code': 'server_error',
                          'message': 'Test server failure.',
                        },
                      },
                    ),
                    type: DioExceptionType.badResponse,
                  ),
                );
              },
        );

        final InMemoryAccessTokenStore accessTokenStore =
            InMemoryAccessTokenStore()..save('access-token');

        final _FakeMobileRefreshTokenStore refreshTokenStore =
            _FakeMobileRefreshTokenStore(initialValue: 'refresh-token');

        final ApiAuthRepository repository = ApiAuthRepository(
          apiClient: apiClient,
          accessTokenStore: accessTokenStore,
          mobileRefreshTokenStore: refreshTokenStore,
          isWeb: false,
        );

        await expectLater(
          repository.logoutEverywhere(),
          throwsA(isA<AppException>()),
        );

        expect(accessTokenStore.token, isNull);
        expect(refreshTokenStore.value, isNull);
        expect(refreshTokenStore.clearCalls, 1);
      },
    );
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

  return ApiClient(baseUrl: Uri.parse('https://server.example.com'), dio: dio);
}

final class _FakeMobileRefreshTokenStore implements MobileRefreshTokenStore {
  _FakeMobileRefreshTokenStore({String? initialValue}) : value = initialValue;

  String? value;

  int clearCalls = 0;

  @override
  Future<String?> read() async {
    return value;
  }

  @override
  Future<void> save(String refreshToken) async {
    value = refreshToken;
  }

  @override
  Future<void> clear() async {
    clearCalls += 1;
    value = null;
  }
}
