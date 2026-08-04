import 'package:flutter_test/flutter_test.dart';
import 'package:sofawatch/core/errors/app_error_message_mapper.dart';
import 'package:sofawatch/core/errors/app_exception.dart';

void main() {
  group('AppErrorMessageMapper', () {
    test('maps connection errors', () {
      const AppException exception = AppException.connection();

      expect(
        AppErrorMessageMapper.map(exception),
        'Could not connect to the server. '
        'Check the address and your network connection.',
      );
    });

    test('maps timeout errors', () {
      const AppException exception = AppException.receiveTimeout();

      expect(
        AppErrorMessageMapper.map(exception),
        'The server took too long to respond.',
      );
    });

    test('uses a specific message for a known error code', () {
      const AppException exception = AppException(
        type: AppExceptionType.notFound,
        code: 'episode_not_found',
        message: 'Episode not found.',
        statusCode: 404,
      );

      expect(
        AppErrorMessageMapper.map(exception),
        'The requested episode could not be found.',
      );
    });

    test('falls back to the error type for an unknown code', () {
      const AppException exception = AppException(
        type: AppExceptionType.notFound,
        code: 'unknown_not_found_error',
        message: 'Resource not found.',
        statusCode: 404,
      );

      expect(
        AppErrorMessageMapper.map(exception),
        'The requested content could not be found.',
      );
    });

    test('maps an unhealthy server', () {
      const AppException exception = AppException(
        type: AppExceptionType.server,
        code: 'server_unhealthy',
        message: 'The server is not healthy.',
      );

      expect(
        AppErrorMessageMapper.map(exception),
        'The SofaWatch server is reachable but is not currently healthy.',
      );
    });

    test('maps invalid server data', () {
      const AppException exception = AppException.invalidData();

      expect(
        AppErrorMessageMapper.map(exception),
        'The server returned data that SofaWatch could not understand.',
      );
    });

    test('returns a message for every exception type', () {
      for (final AppExceptionType type in AppExceptionType.values) {
        final AppException exception = AppException(
          type: type,
          message: 'Technical message.',
        );

        expect(AppErrorMessageMapper.map(exception), isNotEmpty);
      }
    });
  });
}
