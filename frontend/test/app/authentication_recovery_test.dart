import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/app/app_bootstrap_data.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_cubit.dart';
import 'package:sofawatch/features/auth/application/cubit/auth_state.dart';
import 'package:sofawatch/features/auth/data/repositories/api_auth_handoff_repository.dart';
import 'package:sofawatch/features/auth/data/repositories/api_auth_repository.dart';
import 'package:sofawatch/features/auth/data/repositories/api_setup_status_repository.dart';
import 'package:sofawatch/features/auth/data/services/authenticated_request_recovery_service.dart';
import 'package:sofawatch/features/auth/data/storage/in_memory_access_token_store.dart';
import 'package:sofawatch/features/auth/domain/repositories/access_token_store.dart';
import 'package:sofawatch/features/auth/domain/repositories/mobile_refresh_token_store.dart';

import '../fakes/fake_search_repository.dart';
import '../fakes/fake_server_configuration_repository.dart';
import '../fakes/fake_server_connection_tester.dart';
import '../fixtures/server_configuration_fixture.dart';
import '../helpers/test_app.dart';
import '../helpers/test_bootstrap_data.dart';

void main() {
  testWidgets('redirects to Login when an authenticated request cannot restore '
      'the session', (WidgetTester tester) async {
    var setupRequestCount = 0;
    bool sessionIsValid = true;

    final Dio dio = Dio();

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          final String path = options.path;

          if (path.endsWith('/auth/session')) {
            if (sessionIsValid) {
              handler.resolve(
                Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 200,
                  data: const <String, dynamic>{
                    'access_token': 'test-access-token',
                    'token_type': 'bearer',
                    'expires_in': 900,
                  },
                ),
              );

              return;
            }

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

            return;
          }

          if (path.endsWith('/auth/setup')) {
            setupRequestCount++;

            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: const <String, dynamic>{'setup_required': false},
              ),
            );

            return;
          }

          if (path.endsWith('/test/protected')) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 401,
                  data: const <String, dynamic>{
                    'error': <String, dynamic>{
                      'code': 'invalid_access_token',
                      'message': 'The access token is invalid or expired.',
                    },
                  },
                ),
                type: DioExceptionType.badResponse,
              ),
            );

            return;
          }

          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 500,
              data: const <String, dynamic>{
                'error': <String, dynamic>{
                  'code': 'test_unhandled_request',
                  'message':
                      'Unhandled request in authentication recovery test.',
                },
              },
            ),
          );
        },
      ),
    );

    final ApiClient apiClient = ApiClient(
      baseUrl: Uri.parse('https://server.example.com'),
      dio: dio,
    );

    final AppBootstrapData bootstrapData = createTestBootstrapData(
      apiClient: apiClient,
    );

    await tester.pumpSofaWatchApp(bootstrapData: bootstrapData, settle: false);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const ValueKey<String>('home-page')), findsOneWidget);

    expect(bootstrapData.accessTokenStore.token, 'test-access-token');
    expect(setupRequestCount, 0);

    sessionIsValid = false;

    final BuildContext homeContext = tester.element(
      find.byKey(const ValueKey<String>('home-page')),
    );

    final AuthCubit authCubit = homeContext.read<AuthCubit>();

    expect(authCubit.state, isA<AuthAuthenticated>());

    Object? requestError;

    final Future<void> protectedRequest = apiClient
        .get<void>('/test/protected')
        .then<void>(
          (_) {},
          onError: (Object error, StackTrace stackTrace) {
            requestError = error;
          },
        );

    //
    // Keep the widget-test event loop moving while the protected request,
    // authentication recovery, and authentication-loss notification run.
    //
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    await protectedRequest;

    //
    // Authentication loss must be published before the failed protected
    // request is returned to the feature that initiated it.
    //
    expect(authCubit.state, isA<AuthUnauthenticated>());

    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('authentication-transition-guard')),
      findsOneWidget,
    );

    expect(requestError, isA<AppException>());
    expect((requestError! as AppException).code, 'invalid_access_token');

    expect(bootstrapData.accessTokenStore.token, isNull);
    expect(setupRequestCount, 0);

    //
    // Authentication recovery and routing are separate asynchronous chains.
    //
    // The recovery contract guarantees that authentication loss is published
    // before the failed protected request is returned. The router tests cover
    // the exact AuthUnauthenticated -> Login redirect independently.
    //
    // StatefulShellRoute keeps its branch navigators alive after Login is
    // presented by the root navigator. The protected shell, including its
    // authentication transition guard, can therefore remain mounted
    // underneath Login. The integration contract is that Login becomes the
    // active auth UI.
    //
    for (var attempt = 0; attempt < 10; attempt++) {
      if (find
          .byKey(const ValueKey<String>('auth-login-page-title'))
          .evaluate()
          .isNotEmpty) {
        break;
      }

      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(
      find.byKey(const ValueKey<String>('auth-login-page-title')),
      findsOneWidget,
    );
  });

  testWidgets(
    'refreshes mobile authentication and retries the protected request',
    (WidgetTester tester) async {
      var refreshRequestCount = 0;
      var protectedRequestCount = 0;

      final List<String?> refreshTokensReceived = <String?>[];

      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
            final String path = options.path;

            if (path.endsWith('/auth/refresh')) {
              refreshRequestCount++;

              final Map<String, dynamic>? data =
                  options.data as Map<String, dynamic>?;

              refreshTokensReceived.add(data?['refresh_token'] as String?);

              final String accessToken;
              final String refreshToken;

              if (refreshRequestCount == 1) {
                accessToken = 'access-token-1';
                refreshToken = 'refresh-token-2';
              } else {
                accessToken = 'access-token-2';
                refreshToken = 'refresh-token-3';
              }

              handler.resolve(
                Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 200,
                  data: <String, dynamic>{
                    'access_token': accessToken,
                    'token_type': 'bearer',
                    'expires_in': 900,
                    'refresh_token': refreshToken,
                  },
                ),
              );

              return;
            }

            if (path.endsWith('/auth/setup')) {
              handler.resolve(
                Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 200,
                  data: const <String, dynamic>{'setup_required': false},
                ),
              );

              return;
            }

            if (path.endsWith('/test/protected')) {
              protectedRequestCount++;

              if (protectedRequestCount == 1) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    response: Response<Map<String, dynamic>>(
                      requestOptions: options,
                      statusCode: 401,
                      data: const <String, dynamic>{
                        'error': <String, dynamic>{
                          'code': 'invalid_access_token',
                          'message': 'The access token is invalid or expired.',
                        },
                      },
                    ),
                    type: DioExceptionType.badResponse,
                  ),
                );

                return;
              }

              handler.resolve(
                Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 200,
                  data: const <String, dynamic>{'ok': true},
                ),
              );

              return;
            }

            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 500,
                data: const <String, dynamic>{
                  'error': <String, dynamic>{
                    'code': 'test_unhandled_request',
                    'message':
                        'Unhandled request in mobile authentication recovery '
                        'test.',
                  },
                },
              ),
            );
          },
        ),
      );

      final ApiClient apiClient = ApiClient(
        baseUrl: Uri.parse('https://server.example.com'),
        dio: dio,
      );

      final _FakeMobileRefreshTokenStore refreshTokenStore =
          _FakeMobileRefreshTokenStore(initialValue: 'refresh-token-1');

      final AppBootstrapData bootstrapData = _createMobileBootstrapData(
        apiClient: apiClient,
        refreshTokenStore: refreshTokenStore,
      );

      await tester.pumpSofaWatchApp(
        bootstrapData: bootstrapData,
        settle: false,
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const ValueKey<String>('home-page')), findsOneWidget);

      final BuildContext homeContext = tester.element(
        find.byKey(const ValueKey<String>('home-page')),
      );

      final AuthCubit authCubit = homeContext.read<AuthCubit>();

      expect(authCubit.state, isA<AuthAuthenticated>());
      expect(bootstrapData.accessTokenStore.token, 'access-token-1');
      expect(refreshTokenStore.value, 'refresh-token-2');

      Response<Map<String, dynamic>>? protectedResponse;
      Object? requestError;

      final Future<void> protectedRequest = apiClient
          .get<Map<String, dynamic>>('/test/protected')
          .then<void>(
            (Response<Map<String, dynamic>> response) {
              protectedResponse = response;
            },
            onError: (Object error, StackTrace stackTrace) {
              requestError = error;
            },
          );

      //
      // Keep the widget-test event loop moving while the 401 recovery,
      // refresh-token rotation, and protected-request retry complete.
      //
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      await protectedRequest;

      expect(requestError, isNull);
      expect(protectedResponse, isNotNull);
      expect(protectedResponse!.statusCode, 200);
      expect(protectedResponse!.data, const <String, dynamic>{'ok': true});

      expect(authCubit.state, isA<AuthAuthenticated>());

      expect(refreshRequestCount, 2);
      expect(refreshTokensReceived, <String?>[
        'refresh-token-1',
        'refresh-token-2',
      ]);

      expect(protectedRequestCount, 2);

      expect(bootstrapData.accessTokenStore.token, 'access-token-2');
      expect(refreshTokenStore.value, 'refresh-token-3');
      expect(refreshTokenStore.clearCalls, 0);

      expect(
        find.byKey(const ValueKey<String>('auth-login-page-title')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'redirects mobile authentication to Login when the refresh token is '
    'invalid',
    (WidgetTester tester) async {
      var refreshRequestCount = 0;
      var protectedRequestCount = 0;
      var setupRequestCount = 0;

      final List<String?> refreshTokensReceived = <String?>[];

      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
            final String path = options.path;

            if (path.endsWith('/auth/refresh')) {
              refreshRequestCount++;

              final Map<String, dynamic>? data =
                  options.data as Map<String, dynamic>?;

              refreshTokensReceived.add(data?['refresh_token'] as String?);

              if (refreshRequestCount == 1) {
                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: const <String, dynamic>{
                      'access_token': 'access-token-1',
                      'token_type': 'bearer',
                      'expires_in': 900,
                      'refresh_token': 'refresh-token-2',
                    },
                  ),
                );

                return;
              }

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

              return;
            }

            if (path.endsWith('/auth/setup')) {
              setupRequestCount++;

              handler.resolve(
                Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 200,
                  data: const <String, dynamic>{'setup_required': false},
                ),
              );

              return;
            }

            if (path.endsWith('/test/protected')) {
              protectedRequestCount++;

              handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 401,
                    data: const <String, dynamic>{
                      'error': <String, dynamic>{
                        'code': 'invalid_access_token',
                        'message': 'The access token is invalid or expired.',
                      },
                    },
                  ),
                  type: DioExceptionType.badResponse,
                ),
              );

              return;
            }

            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 500,
                data: const <String, dynamic>{
                  'error': <String, dynamic>{
                    'code': 'test_unhandled_request',
                    'message':
                        'Unhandled request in mobile authentication recovery '
                        'test.',
                  },
                },
              ),
            );
          },
        ),
      );

      final ApiClient apiClient = ApiClient(
        baseUrl: Uri.parse('https://server.example.com'),
        dio: dio,
      );

      final _FakeMobileRefreshTokenStore refreshTokenStore =
          _FakeMobileRefreshTokenStore(initialValue: 'refresh-token-1');

      final AppBootstrapData bootstrapData = _createMobileBootstrapData(
        apiClient: apiClient,
        refreshTokenStore: refreshTokenStore,
      );

      await tester.pumpSofaWatchApp(
        bootstrapData: bootstrapData,
        settle: false,
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const ValueKey<String>('home-page')), findsOneWidget);

      expect(bootstrapData.accessTokenStore.token, 'access-token-1');
      expect(refreshTokenStore.value, 'refresh-token-2');
      expect(setupRequestCount, 0);

      final BuildContext homeContext = tester.element(
        find.byKey(const ValueKey<String>('home-page')),
      );

      final AuthCubit authCubit = homeContext.read<AuthCubit>();

      expect(authCubit.state, isA<AuthAuthenticated>());

      Object? requestError;

      final Future<void> protectedRequest = apiClient
          .get<void>('/test/protected')
          .then<void>(
            (_) {},
            onError: (Object error, StackTrace stackTrace) {
              requestError = error;
            },
          );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      await protectedRequest;

      //
      // Definitive refresh failure must invalidate authentication before the
      // original protected-request error reaches the feature.
      //
      expect(authCubit.state, isA<AuthUnauthenticated>());

      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('authentication-transition-guard')),
        findsOneWidget,
      );

      expect(requestError, isA<AppException>());
      expect((requestError! as AppException).code, 'invalid_access_token');

      expect(refreshRequestCount, 2);
      expect(refreshTokensReceived, <String?>[
        'refresh-token-1',
        'refresh-token-2',
      ]);

      expect(protectedRequestCount, 1);

      expect(bootstrapData.accessTokenStore.token, isNull);
      expect(refreshTokenStore.value, isNull);
      expect(refreshTokenStore.clearCalls, 1);

      expect(setupRequestCount, 0);

      for (var attempt = 0; attempt < 10; attempt++) {
        if (find
            .byKey(const ValueKey<String>('auth-login-page-title'))
            .evaluate()
            .isNotEmpty) {
          break;
        }

        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(
        find.byKey(const ValueKey<String>('auth-login-page-title')),
        findsOneWidget,
      );
    },
  );
}

AppBootstrapData _createMobileBootstrapData({
  required ApiClient apiClient,
  required MobileRefreshTokenStore refreshTokenStore,
}) {
  final serverConfiguration = createServerConfigurationFixture();

  final AccessTokenStore accessTokenStore = InMemoryAccessTokenStore();

  final ApiAuthRepository authRepository = ApiAuthRepository(
    apiClient: apiClient,
    accessTokenStore: accessTokenStore,
    mobileRefreshTokenStore: refreshTokenStore,
    isWeb: false,
  );

  final AuthenticatedRequestRecoveryService authenticatedRequestRecovery =
      AuthenticatedRequestRecoveryService(repository: authRepository);

  apiClient.configureAuthenticatedRequestRecovery(authenticatedRequestRecovery);

  return AppBootstrapData(
    serverConfigurationRepository: FakeServerConfigurationRepository(
      initialConfiguration: serverConfiguration,
    ),
    apiClient: apiClient,
    serverConnectionTester: FakeServerConnectionTester(),
    initialServerConfiguration: serverConfiguration,
    searchRepository: FakeSearchRepository(),
    accessTokenStore: accessTokenStore,
    authRepository: authRepository,
    authenticatedRequestRecovery: authenticatedRequestRecovery,
    setupStatusRepository: ApiSetupStatusRepository(apiClient),
    authHandoffRepository: ApiAuthHandoffRepository(
      apiClient: apiClient,
      accessTokenStore: accessTokenStore,
    ),
  );
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
    clearCalls++;
    value = null;
  }
}
