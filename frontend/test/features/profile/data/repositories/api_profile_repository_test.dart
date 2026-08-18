import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
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
                      'display_name': 'Gonçalo',
                      'is_local': true,
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
      expect(user.isLocal, isTrue);
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
                      'is_local': true,
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
  });
}
