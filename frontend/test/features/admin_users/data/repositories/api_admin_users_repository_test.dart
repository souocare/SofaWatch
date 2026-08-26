import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/admin_users/data/repositories/api_admin_users_repository.dart';
import 'package:sofawatch/features/admin_users/domain/models/password_recovery_link.dart';

void main() {
  group('ApiAdminUsersRepository', () {
    test('starts password recovery for user', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                expect(
                  options.path,
                  endsWith('/users/user-123/password-recovery'),
                );

                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: const <String, dynamic>{
                      'token': 'reset-token',
                      'expires_at': '2026-08-26T10:00:00Z',
                    },
                  ),
                );
              },
        ),
      );

      final ApiAdminUsersRepository repository = ApiAdminUsersRepository(
        apiClient: ApiClient(
          baseUrl: Uri.parse('https://server.example.com'),
          dio: dio,
        ),
      );

      final PasswordRecoveryLink result = await repository
          .startPasswordRecovery(userId: 'user-123');

      expect(result.token, 'reset-token');

      expect(result.expiresAt, DateTime.parse('2026-08-26T10:00:00Z'));
    });

    test('rejects empty user id', () async {
      final ApiAdminUsersRepository repository = ApiAdminUsersRepository(
        apiClient: ApiClient(
          baseUrl: Uri.parse('https://server.example.com'),
          dio: Dio(),
        ),
      );

      expect(() {
        return repository.startPasswordRecovery(userId: '   ');
      }, throwsArgumentError);
    });

    test('maps invalid response to invalidData', () async {
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
                      'token': '',
                      'expires_at': 'invalid-date',
                    },
                  ),
                );
              },
        ),
      );

      final ApiAdminUsersRepository repository = ApiAdminUsersRepository(
        apiClient: ApiClient(
          baseUrl: Uri.parse('https://server.example.com'),
          dio: dio,
        ),
      );

      expect(
        () {
          return repository.startPasswordRecovery(userId: 'user-123');
        },
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });
    test('lists users', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                expect(options.path, endsWith('/users'));

                handler.resolve(
                  Response<List<dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: const <dynamic>[
                      <String, dynamic>{
                        'id': 'admin-1',
                        'username': 'administrator',
                        'email': 'admin@example.com',
                        'display_name': 'Administrator',
                        'is_active': true,
                        'is_local': true,
                        'is_admin': true,
                      },
                      <String, dynamic>{
                        'id': 'user-1',
                        'username': 'regular-user',
                        'email': null,
                        'display_name': 'Regular User',
                        'is_active': true,
                        'is_local': false,
                        'is_admin': false,
                      },
                    ],
                  ),
                );
              },
        ),
      );

      final ApiAdminUsersRepository repository = ApiAdminUsersRepository(
        apiClient: ApiClient(
          baseUrl: Uri.parse('https://server.example.com'),
          dio: dio,
        ),
      );

      final users = await repository.listUsers();

      expect(users, hasLength(2));

      expect(users[0].username, 'administrator');
      expect(users[0].isAdmin, isTrue);

      expect(users[1].displayName, 'Regular User');
      expect(users[1].email, isNull);
      expect(users[1].isAdmin, isFalse);
    });
  });
}
