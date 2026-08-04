import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_exception.dart';

void main() {
  group('AppException', () {
    test('identifies connection errors as retryable network errors', () {
      const AppException exception = AppException.connection();

      expect(exception.isNetworkError, isTrue);

      expect(exception.isTimeout, isFalse);

      expect(exception.canRetry, isTrue);
    });

    test('identifies timeout errors', () {
      const AppException exception = AppException.receiveTimeout();

      expect(exception.isNetworkError, isTrue);

      expect(exception.isTimeout, isTrue);

      expect(exception.canRetry, isTrue);
    });

    test('does not mark validation errors as retryable', () {
      const AppException exception = AppException(
        type: AppExceptionType.validation,
        code: 'validation_error',
        message: 'The submitted data is invalid.',
        statusCode: 422,
      );

      expect(exception.isNetworkError, isFalse);

      expect(exception.canRetry, isFalse);
    });

    test('compares errors by their semantic properties', () {
      const AppException first = AppException(
        type: AppExceptionType.notFound,
        code: 'show_not_found',
        message: 'The show was not found.',
        statusCode: 404,
        originalError: 'first technical error',
      );

      const AppException second = AppException(
        type: AppExceptionType.notFound,
        code: 'show_not_found',
        message: 'The show was not found.',
        statusCode: 404,
        originalError: 'second technical error',
      );

      expect(first, second);
    });
  });
}
