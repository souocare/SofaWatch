import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/data/repositories/api_auth_repository.dart';
import 'package:sofawatch/features/auth/data/storage/in_memory_access_token_store.dart';
import 'package:sofawatch/features/auth/domain/repositories/mobile_refresh_token_store.dart';

void main() {
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
