import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/data/repositories/api_auth_handoff_repository.dart';
import 'package:sofawatch/features/auth/data/storage/in_memory_access_token_store.dart';
import 'package:sofawatch/features/auth/domain/models/auth_handoff.dart';
import 'package:sofawatch/features/auth/domain/models/auth_session.dart';

void main() {
  group('ApiAuthHandoffRepository', () {
    late ApiClient apiClient;
    late DioAdapter dioAdapter;
    late InMemoryAccessTokenStore accessTokenStore;
    late ApiAuthHandoffRepository repository;

    setUp(() {
      accessTokenStore = InMemoryAccessTokenStore();

      apiClient = ApiClient(
        baseUrl: Uri.parse('http://localhost:8000'),
        accessTokenProvider: () => accessTokenStore.token,
      );

      dioAdapter = DioAdapter(dio: apiClient.dio, printLogs: false);

      repository = ApiAuthHandoffRepository(
        apiClient: apiClient,
        accessTokenStore: accessTokenStore,
      );
    });

    group('create', () {
      test('creates and maps an authentication handoff', () async {
        dioAdapter.onPost('/auth/handoff', (server) {
          server.reply(200, <String, dynamic>{
            'handoff_token': 'handoff-token',
            'expires_in': 120,
          });
        });

        final AuthHandoff result = await repository.create();

        expect(result.token, 'handoff-token');
        expect(result.expiresIn, const Duration(minutes: 2));
      });

      test('maps missing response body to invalidData', () async {
        dioAdapter.onPost('/auth/handoff', (server) {
          server.reply(200, null);
        });

        expect(
          repository.create(),
          throwsA(
            isA<AppException>().having(
              (AppException error) => error.type,
              'type',
              AppExceptionType.invalidData,
            ),
          ),
        );
      });

      test('maps malformed response to invalidData', () async {
        dioAdapter.onPost('/auth/handoff', (server) {
          server.reply(200, <String, dynamic>{
            'handoff_token': '',
            'expires_in': 120,
          });
        });

        expect(
          repository.create(),
          throwsA(
            isA<AppException>().having(
              (AppException error) => error.type,
              'type',
              AppExceptionType.invalidData,
            ),
          ),
        );
      });

      test('propagates API errors unchanged', () async {
        dioAdapter.onPost('/auth/handoff', (server) {
          server.reply(401, <String, dynamic>{
            'error': <String, dynamic>{
              'code': 'authentication_required',
              'message': 'Authentication is required.',
            },
          });
        });

        expect(
          repository.create(),
          throwsA(
            isA<AppException>().having(
              (AppException error) => error.type,
              'type',
              AppExceptionType.unauthorized,
            ),
          ),
        );
      });
    });

    group('exchange', () {
      test('exchanges handoff and stores returned access token', () async {
        dioAdapter.onPost(
          '/auth/handoff/exchange',
          data: <String, dynamic>{'handoff_token': 'handoff-token'},
          (server) {
            server.reply(200, <String, dynamic>{
              'access_token': 'web-access-token',
              'token_type': 'bearer',
              'expires_in': 900,
            });
          },
        );

        final AuthSession result = await repository.exchange('handoff-token');

        expect(result.accessToken, 'web-access-token');
        expect(result.expiresIn, const Duration(minutes: 15));
        expect(accessTokenStore.token, 'web-access-token');
      });

      test('normalizes handoff token before exchange', () async {
        dioAdapter.onPost(
          '/auth/handoff/exchange',
          data: <String, dynamic>{'handoff_token': 'handoff-token'},
          (server) {
            server.reply(200, <String, dynamic>{
              'access_token': 'web-access-token',
              'token_type': 'bearer',
              'expires_in': 900,
            });
          },
        );

        await repository.exchange('  handoff-token  ');

        expect(accessTokenStore.token, 'web-access-token');
      });

      test('rejects an empty handoff token', () {
        expect(() => repository.exchange('   '), throwsArgumentError);
      });

      test('maps missing response body to invalidData', () async {
        dioAdapter.onPost(
          '/auth/handoff/exchange',
          data: <String, dynamic>{'handoff_token': 'handoff-token'},
          (server) {
            server.reply(200, null);
          },
        );

        expect(
          repository.exchange('handoff-token'),
          throwsA(
            isA<AppException>().having(
              (AppException error) => error.type,
              'type',
              AppExceptionType.invalidData,
            ),
          ),
        );
      });

      test('maps malformed authentication response to invalidData', () async {
        dioAdapter.onPost(
          '/auth/handoff/exchange',
          data: <String, dynamic>{'handoff_token': 'handoff-token'},
          (server) {
            server.reply(200, <String, dynamic>{
              'access_token': '',
              'token_type': 'bearer',
              'expires_in': 900,
            });
          },
        );

        expect(
          repository.exchange('handoff-token'),
          throwsA(
            isA<AppException>().having(
              (AppException error) => error.type,
              'type',
              AppExceptionType.invalidData,
            ),
          ),
        );
      });

      test('propagates invalid handoff API error unchanged', () async {
        dioAdapter.onPost(
          '/auth/handoff/exchange',
          data: <String, dynamic>{'handoff_token': 'handoff-token'},
          (server) {
            server.reply(401, <String, dynamic>{
              'error': <String, dynamic>{
                'code': 'invalid_auth_handoff',
                'message': 'The authentication handoff is invalid or expired.',
              },
            });
          },
        );

        expect(
          repository.exchange('handoff-token'),
          throwsA(
            isA<AppException>()
                .having(
                  (AppException error) => error.type,
                  'type',
                  AppExceptionType.unauthorized,
                )
                .having(
                  (AppException error) => error.code,
                  'code',
                  'invalid_auth_handoff',
                ),
          ),
        );
      });
    });
  });
}
