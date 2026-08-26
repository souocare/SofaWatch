import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/features/auth/data/repositories/api_password_recovery_repository.dart';

void main() {
  group('ApiPasswordRecoveryRepository', () {
    test('completes password recovery', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                expect(
                  options.path,
                  endsWith('/auth/password-recovery/complete'),
                );

                expect(options.data, <String, dynamic>{
                  'token': 'reset-token',
                  'new_password': 'new-password',
                });

                handler.resolve(
                  Response<void>(requestOptions: options, statusCode: 204),
                );
              },
        ),
      );

      final ApiPasswordRecoveryRepository repository =
          ApiPasswordRecoveryRepository(
            apiClient: ApiClient(
              baseUrl: Uri.parse('https://server.example.com'),
              dio: dio,
            ),
          );

      await repository.complete(
        token: 'reset-token',
        newPassword: 'new-password',
      );
    });
  });
}
