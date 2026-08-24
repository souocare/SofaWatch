import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/auth/data/repositories/api_setup_status_repository.dart';
import 'package:sofawatch/features/auth/domain/models/setup_status.dart';

void main() {
  group('ApiSetupStatusRepository', () {
    test('returns setup status from API', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: const <String, dynamic>{'setup_required': true},
                  ),
                );
              },
        ),
      );

      final ApiClient apiClient = ApiClient(
        baseUrl: Uri.parse('http://localhost:8000'),
        dio: dio,
      );

      final ApiSetupStatusRepository repository = ApiSetupStatusRepository(
        apiClient,
      );

      final SetupStatus result = await repository.getStatus();

      expect(result.setupRequired, isTrue);
    });

    test('maps missing response body to invalid data', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: null,
                  ),
                );
              },
        ),
      );

      final ApiSetupStatusRepository repository = ApiSetupStatusRepository(
        ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
      );

      await expectLater(
        repository.getStatus(),
        throwsA(
          isA<AppException>().having(
            (AppException error) => error.type,
            'type',
            AppExceptionType.invalidData,
          ),
        ),
      );
    });

    test('maps invalid setup status to invalid data', () async {
      final Dio dio = Dio();

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest:
              (RequestOptions options, RequestInterceptorHandler handler) {
                handler.resolve(
                  Response<Map<String, dynamic>>(
                    requestOptions: options,
                    statusCode: 200,
                    data: const <String, dynamic>{'setup_required': 'yes'},
                  ),
                );
              },
        ),
      );

      final ApiSetupStatusRepository repository = ApiSetupStatusRepository(
        ApiClient(baseUrl: Uri.parse('http://localhost:8000'), dio: dio),
      );

      await expectLater(
        repository.getStatus(),
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
