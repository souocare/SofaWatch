import 'package:equatable/equatable.dart';

enum AppExceptionType {
  connection,
  connectionTimeout,
  sendTimeout,
  receiveTimeout,
  badCertificate,
  cancelled,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  validation,
  server,
  badResponse,
  invalidData,
  unknown,
}

class AppException extends Equatable implements Exception {
  const AppException({
    required this.type,
    required this.message,
    this.code,
    this.statusCode,
    this.details,
    this.originalError,
  });

  const AppException.connection({
    this.message = 'Could not connect to the server.',
    this.originalError,
  }) : type = AppExceptionType.connection,
       code = null,
       statusCode = null,
       details = null;

  const AppException.connectionTimeout({
    this.message = 'The connection to the server timed out.',
    this.originalError,
  }) : type = AppExceptionType.connectionTimeout,
       code = null,
       statusCode = null,
       details = null;

  const AppException.sendTimeout({
    this.message = 'The request took too long to send.',
    this.originalError,
  }) : type = AppExceptionType.sendTimeout,
       code = null,
       statusCode = null,
       details = null;

  const AppException.receiveTimeout({
    this.message = 'The server took too long to respond.',
    this.originalError,
  }) : type = AppExceptionType.receiveTimeout,
       code = null,
       statusCode = null,
       details = null;

  const AppException.badCertificate({
    this.message = 'The server certificate could not be verified.',
    this.originalError,
  }) : type = AppExceptionType.badCertificate,
       code = null,
       statusCode = null,
       details = null;

  const AppException.cancelled({
    this.message = 'The request was cancelled.',
    this.originalError,
  }) : type = AppExceptionType.cancelled,
       code = null,
       statusCode = null,
       details = null;

  const AppException.invalidData({
    this.message = 'The server returned invalid data.',
    this.originalError,
  }) : type = AppExceptionType.invalidData,
       code = null,
       statusCode = null,
       details = null;

  const AppException.unknown({
    this.message = 'An unexpected error occurred.',
    this.originalError,
  }) : type = AppExceptionType.unknown,
       code = null,
       statusCode = null,
       details = null;

  final AppExceptionType type;

  /// Stable machine-readable error code returned by the backend.
  final String? code;

  /// Human-readable fallback description.
  final String message;

  final int? statusCode;

  /// Optional structured information returned by the backend.
  final Object? details;

  /// Original technical error, kept for logging and debugging.
  ///
  /// This should not be displayed directly in the UI.
  final Object? originalError;

  bool get isNetworkError {
    return switch (type) {
      AppExceptionType.connection ||
      AppExceptionType.connectionTimeout ||
      AppExceptionType.sendTimeout ||
      AppExceptionType.receiveTimeout => true,
      _ => false,
    };
  }

  bool get isTimeout {
    return switch (type) {
      AppExceptionType.connectionTimeout ||
      AppExceptionType.sendTimeout ||
      AppExceptionType.receiveTimeout => true,
      _ => false,
    };
  }

  bool get canRetry {
    return switch (type) {
      AppExceptionType.connection ||
      AppExceptionType.connectionTimeout ||
      AppExceptionType.sendTimeout ||
      AppExceptionType.receiveTimeout ||
      AppExceptionType.server ||
      AppExceptionType.unknown => true,
      _ => false,
    };
  }

  @override
  List<Object?> get props => <Object?>[
    type,
    code,
    message,
    statusCode,
    details,
  ];

  @override
  String toString() {
    return 'AppException('
        'type: $type, '
        'code: $code, '
        'statusCode: $statusCode, '
        'message: $message'
        ')';
  }
}
