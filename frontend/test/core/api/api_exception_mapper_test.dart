import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/api/api_exception_mapper.dart';
import 'package:sofawatch/core/api/models/api_error_response.dart';
import 'package:sofawatch/core/errors/app_exception.dart';

void main() {
  group('ApiExceptionMapper', () {
    test('maps connection errors', () {
      final DioException dioException = DioException(
        requestOptions: RequestOptions(path: '/shows'),
        type: DioExceptionType.connectionError,
      );

      final AppException exception = ApiExceptionMapper.map(dioException);

      expect(exception.type, AppExceptionType.connection);

      expect(exception.canRetry, isTrue);
    });

    test('maps receive timeouts', () {
      final DioException dioException = DioException(
        requestOptions: RequestOptions(path: '/shows'),
        type: DioExceptionType.receiveTimeout,
      );

      final AppException exception = ApiExceptionMapper.map(dioException);

      expect(exception.type, AppExceptionType.receiveTimeout);

      expect(exception.isTimeout, isTrue);
    });

    test('parses a standardized not-found response', () {
      final DioException dioException = DioException.badResponse(
        statusCode: 404,
        requestOptions: RequestOptions(path: '/shows/123'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/shows/123'),
          statusCode: 404,
          data: <String, dynamic>{
            'error': <String, dynamic>{
              'code': 'show_not_found',
              'message': 'The show was not found.',
            },
          },
        ),
      );

      final AppException exception = ApiExceptionMapper.map(dioException);

      expect(exception.type, AppExceptionType.notFound);

      expect(exception.code, 'show_not_found');

      expect(exception.message, 'The show was not found.');

      expect(exception.statusCode, 404);
    });

    test('preserves validation details', () {
      final RequestOptions requestOptions = RequestOptions(path: '/shows');

      final DioException dioException = DioException.badResponse(
        statusCode: 422,
        requestOptions: requestOptions,
        response: Response<dynamic>(
          requestOptions: requestOptions,
          statusCode: 422,
          data: <String, dynamic>{
            'error': <String, dynamic>{
              'code': 'validation_error',
              'message': 'The request contains invalid data.',
              'details': <Map<String, dynamic>>[
                <String, dynamic>{
                  'field': 'query',
                  'message': 'Invalid value.',
                },
              ],
            },
          },
        ),
      );

      final AppException exception = ApiExceptionMapper.map(dioException);

      expect(exception.type, AppExceptionType.validation);

      expect(exception.code, 'validation_error');

      expect(exception.details, isA<List<ApiErrorDetail>>());

      expect(
        (exception.details! as List<ApiErrorDetail>).single.field,
        'query',
      );
    });

    test('uses a fallback for malformed response bodies', () {
      final RequestOptions requestOptions = RequestOptions(path: '/shows');

      final DioException dioException = DioException.badResponse(
        statusCode: 500,
        requestOptions: requestOptions,
        response: Response<dynamic>(
          requestOptions: requestOptions,
          statusCode: 500,
          data: 'unexpected',
        ),
      );

      final AppException exception = ApiExceptionMapper.map(dioException);

      expect(exception.type, AppExceptionType.server);

      expect(exception.code, isNull);

      expect(exception.message, 'The server encountered an error.');
    });

    test('maps cancelled requests', () {
      final DioException dioException = DioException(
        requestOptions: RequestOptions(path: '/shows'),
        type: DioExceptionType.cancel,
      );

      final AppException exception = ApiExceptionMapper.map(dioException);

      expect(exception.type, AppExceptionType.cancelled);

      expect(exception.canRetry, isFalse);
    });

    test('maps connection timeouts', () {
      final DioException dioException = DioException(
        requestOptions: RequestOptions(path: '/shows'),
        type: DioExceptionType.connectionTimeout,
      );

      final AppException exception = ApiExceptionMapper.map(dioException);

      expect(exception.type, AppExceptionType.connectionTimeout);

      expect(exception.isTimeout, isTrue);

      expect(exception.canRetry, isTrue);
    });

    test('maps send timeouts', () {
      final DioException dioException = DioException(
        requestOptions: RequestOptions(path: '/shows'),
        type: DioExceptionType.sendTimeout,
      );

      final AppException exception = ApiExceptionMapper.map(dioException);

      expect(exception.type, AppExceptionType.sendTimeout);

      expect(exception.isTimeout, isTrue);
    });

    test('maps transform timeouts', () {
      final DioException dioException = DioException(
        requestOptions: RequestOptions(path: '/shows'),
        type: DioExceptionType.transformTimeout,
      );

      final AppException exception = ApiExceptionMapper.map(dioException);

      expect(exception.type, AppExceptionType.receiveTimeout);

      expect(exception.isTimeout, isTrue);
    });

    test('maps invalid certificates', () {
      final DioException dioException = DioException(
        requestOptions: RequestOptions(path: '/shows'),
        type: DioExceptionType.badCertificate,
      );

      final AppException exception = ApiExceptionMapper.map(dioException);

      expect(exception.type, AppExceptionType.badCertificate);

      expect(exception.canRetry, isFalse);
    });

    test('maps format exceptions to invalid data', () {
      final DioException dioException = DioException(
        requestOptions: RequestOptions(path: '/shows'),
        type: DioExceptionType.unknown,
        error: const FormatException('Invalid JSON'),
      );

      final AppException exception = ApiExceptionMapper.map(dioException);

      expect(exception.type, AppExceptionType.invalidData);
    });

    test('maps unknown technical errors', () {
      final DioException dioException = DioException(
        requestOptions: RequestOptions(path: '/shows'),
        type: DioExceptionType.unknown,
        error: Exception('Unknown failure'),
      );

      final AppException exception = ApiExceptionMapper.map(dioException);

      expect(exception.type, AppExceptionType.unknown);
    });

    test('maps relevant HTTP status codes', () {
      final Map<int, AppExceptionType> cases = <int, AppExceptionType>{
        401: AppExceptionType.unauthorized,
        403: AppExceptionType.forbidden,
        404: AppExceptionType.notFound,
        409: AppExceptionType.conflict,
        422: AppExceptionType.validation,
        500: AppExceptionType.server,
        502: AppExceptionType.server,
        503: AppExceptionType.server,
      };

      for (final MapEntry<int, AppExceptionType> entry in cases.entries) {
        final RequestOptions requestOptions = RequestOptions(path: '/resource');

        final DioException dioException = DioException.badResponse(
          statusCode: entry.key,
          requestOptions: requestOptions,
          response: Response<dynamic>(
            requestOptions: requestOptions,
            statusCode: entry.key,
            data: <String, dynamic>{
              'error': <String, dynamic>{
                'code': 'http_error',
                'message': 'Request failed.',
              },
            },
          ),
        );

        final AppException exception = ApiExceptionMapper.map(dioException);

        expect(
          exception.type,
          entry.value,
          reason: 'Unexpected mapping for ${entry.key}.',
        );
      }
    });

    test('uses badResponse when the HTTP status code is missing', () {
      final RequestOptions requestOptions = RequestOptions(path: '/resource');

      final DioException dioException = DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: requestOptions,
          data: 'invalid response',
        ),
      );

      final AppException exception = ApiExceptionMapper.map(dioException);

      expect(exception.type, AppExceptionType.badResponse);

      expect(exception.statusCode, isNull);

      expect(exception.message, 'The server returned an unexpected response.');
    });
  });
}
