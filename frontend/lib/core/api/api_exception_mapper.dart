import 'package:dio/dio.dart';
import 'package:sofawatch/core/api/models/api_error_response.dart';
import 'package:sofawatch/core/errors/app_exception.dart';

abstract final class ApiExceptionMapper {
  static AppException map(DioException exception) {
    return switch (exception.type) {
      DioExceptionType.connectionTimeout => AppException.connectionTimeout(
        originalError: exception,
      ),
      DioExceptionType.sendTimeout => AppException.sendTimeout(
        originalError: exception,
      ),
      DioExceptionType.receiveTimeout => AppException.receiveTimeout(
        originalError: exception,
      ),
      DioExceptionType.transformTimeout => AppException.receiveTimeout(
        originalError: exception,
      ),
      DioExceptionType.badCertificate => AppException.badCertificate(
        originalError: exception,
      ),
      DioExceptionType.cancel => AppException.cancelled(
        originalError: exception,
      ),
      DioExceptionType.connectionError => AppException.connection(
        originalError: exception,
      ),
      DioExceptionType.badResponse => _mapBadResponse(exception),
      DioExceptionType.unknown => _mapUnknown(exception),
    };
  }

  static AppException _mapBadResponse(DioException exception) {
    final int? statusCode = exception.response?.statusCode;

    final ApiErrorResponse? apiError = _tryParseApiError(
      exception.response?.data,
    );

    return AppException(
      type: _typeForStatusCode(statusCode),
      code: apiError?.error.code,
      message:
          apiError?.error.message ?? _fallbackMessageForStatusCode(statusCode),
      statusCode: statusCode,
      details: apiError?.error.details,
      originalError: exception,
    );
  }

  static AppException _mapUnknown(DioException exception) {
    final Object? originalError = exception.error;

    if (originalError is FormatException) {
      return AppException.invalidData(originalError: exception);
    }

    return AppException.unknown(originalError: exception);
  }

  static ApiErrorResponse? _tryParseApiError(Object? data) {
    if (data is! Map<String, dynamic>) {
      return null;
    }

    try {
      return ApiErrorResponse.fromJson(data);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  static AppExceptionType _typeForStatusCode(int? statusCode) {
    if (statusCode == null) {
      return AppExceptionType.badResponse;
    }

    return switch (statusCode) {
      401 => AppExceptionType.unauthorized,
      403 => AppExceptionType.forbidden,
      404 => AppExceptionType.notFound,
      409 => AppExceptionType.conflict,
      422 => AppExceptionType.validation,
      _ when statusCode >= 500 => AppExceptionType.server,
      _ => AppExceptionType.badResponse,
    };
  }

  static String _fallbackMessageForStatusCode(int? statusCode) {
    if (statusCode == null) {
      return 'The server returned an unexpected response.';
    }

    return switch (statusCode) {
      401 => 'Authentication is required.',
      403 => 'You do not have permission to perform this action.',
      404 => 'The requested resource was not found.',
      409 => 'The request conflicts with the current server state.',
      422 => 'The submitted data is invalid.',
      _ when statusCode >= 500 => 'The server encountered an error.',
      _ => 'The server returned an unexpected response.',
    };
  }
}
