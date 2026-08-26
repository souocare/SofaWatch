import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/profile/data/repositories/api_profile_repository.dart';
import 'package:sofawatch/features/profile/domain/models/profile_user.dart';

void main() {
  group('ApiProfileRepository', () {
    test('loads the current user', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                expect(options.path, endsWith('/users/me'));

                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: const <String, dynamic>{
                      'id': '11111111-2222-3333-4444-555555555555',
                      'username': 'souocare',
                      'email': 'goncalo@example.com',
                      'display_name': 'Gonçalo',
                      'is_active': true,
                      'is_admin': true,
                    },
                  ),
                );
              },
        ),
      );

      final ApiProfileRepository repository = ApiProfileRepository(
        ApiClient(baseUrl: Uri.parse('https://server.example.com'), dio: dio),
      );

      final ProfileUser user = await repository.getCurrentUser();

      expect(user.displayName, 'Gonçalo');
      expect(user.isAdmin, isTrue);
      expect(user.username, 'souocare');
      expect(user.email, 'goncalo@example.com');
    });

    test('loads a non-admin current user', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                expect(options.path, endsWith('/users/me'));

                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: const <String, dynamic>{
                      'id': 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
                      'username': 'regularuser',
                      'email': 'regular@example.com',
                      'display_name': 'Regular User',
                      'is_active': true,
                      'is_admin': false,
                    },
                  ),
                );
              },
        ),
      );

      final ApiProfileRepository repository = ApiProfileRepository(
        ApiClient(baseUrl: Uri.parse('https://server.example.com'), dio: dio),
      );

      final ProfileUser user = await repository.getCurrentUser();

      expect(user.id, 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee');
      expect(user.displayName, 'Regular User');
      expect(user.isAdmin, isFalse);
    });

    test('maps invalid response data to invalidData', () async {
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
                      'id': '11111111-2222-3333-4444-555555555555',
                      'display_name': 123,
                      'username': null,
                      'email': null,
                    },
                  ),
                );
              },
        ),
      );

      final ApiProfileRepository repository = ApiProfileRepository(
        ApiClient(baseUrl: Uri.parse('https://server.example.com'), dio: dio),
      );

      expect(
        repository.getCurrentUser,
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });
    test('updates the current user display name', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                expect(options.method, 'PATCH');
                expect(options.path, endsWith('/users/me'));

                expect(options.data, <String, dynamic>{
                  'display_name': 'Novo Nome',
                });

                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: const <String, dynamic>{
                      'id': '11111111-2222-3333-4444-555555555555',
                      'username': 'souocare',
                      'email': 'goncalo@example.com',
                      'display_name': 'Novo Nome',
                      'is_active': true,
                      'is_admin': true,
                    },
                  ),
                );
              },
        ),
      );

      final ApiProfileRepository repository = ApiProfileRepository(
        ApiClient(baseUrl: Uri.parse('https://server.example.com'), dio: dio),
      );

      final ProfileUser user = await repository.updateDisplayName(
        displayName: 'Novo Nome',
      );

      expect(user.displayName, 'Novo Nome');
      expect(user.username, 'souocare');
      expect(user.isAdmin, isTrue);
    });
    test('changes current user password', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                expect(options.method, 'PUT');
                expect(options.path, endsWith('/users/me/password'));

                expect(options.data, <String, dynamic>{
                  'current_password': 'old-password',
                  'new_password': 'new-password',
                });

                handler.resolve(
                  Response<void>(requestOptions: options, statusCode: 204),
                );
              },
        ),
      );

      final ApiProfileRepository repository = ApiProfileRepository(
        ApiClient(baseUrl: Uri.parse('https://server.example.com'), dio: dio),
      );

      await repository.updatePassword(
        currentPassword: 'old-password',
        newPassword: 'new-password',
      );
    });
    test('preserves current password invalid error', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    response: Response<Map<String, dynamic>>(
                      requestOptions: options,
                      statusCode: 400,
                      data: const <String, dynamic>{
                        'error': <String, dynamic>{
                          'code': 'current_password_invalid',
                          'message': 'The current password is incorrect.',
                        },
                      },
                    ),
                    type: DioExceptionType.badResponse,
                  ),
                );
              },
        ),
      );

      final ApiProfileRepository repository = ApiProfileRepository(
        ApiClient(baseUrl: Uri.parse('https://server.example.com'), dio: dio),
      );

      expect(
        () => repository.updatePassword(
          currentPassword: 'wrong-password',
          newPassword: 'new-password',
        ),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.code,
            'code',
            'current_password_invalid',
          ),
        ),
      );
    });
  });
}
