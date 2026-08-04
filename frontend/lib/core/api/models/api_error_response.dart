import 'package:equatable/equatable.dart';

class ApiErrorDetail extends Equatable {
  const ApiErrorDetail({required this.message, this.field, this.context});

  factory ApiErrorDetail.fromJson(Map<String, dynamic> json) {
    return ApiErrorDetail(
      field: json['field'] as String?,
      message: json['message'] as String,
      context: _parseContext(json['context']),
    );
  }

  final String? field;
  final String message;
  final Map<String, dynamic>? context;

  static Map<String, dynamic>? _parseContext(Object? value) {
    if (value is! Map<String, dynamic>) {
      return null;
    }

    return value;
  }

  @override
  List<Object?> get props => <Object?>[field, message, context];
}

class ApiErrorBody extends Equatable {
  const ApiErrorBody({required this.code, required this.message, this.details});

  factory ApiErrorBody.fromJson(Map<String, dynamic> json) {
    return ApiErrorBody(
      code: json['code'] as String,
      message: json['message'] as String,
      details: _parseDetails(json['details']),
    );
  }

  final String code;
  final String message;
  final List<ApiErrorDetail>? details;

  static List<ApiErrorDetail>? _parseDetails(Object? value) {
    if (value is! List<dynamic>) {
      return null;
    }

    return value
        .whereType<Map<String, dynamic>>()
        .map(ApiErrorDetail.fromJson)
        .toList(growable: false);
  }

  @override
  List<Object?> get props => <Object?>[code, message, details];
}

class ApiErrorResponse extends Equatable {
  const ApiErrorResponse({required this.error});

  factory ApiErrorResponse.fromJson(Map<String, dynamic> json) {
    final Object? errorValue = json['error'];

    if (errorValue is! Map<String, dynamic>) {
      throw const FormatException(
        'The API error response does not contain a valid error object.',
      );
    }

    return ApiErrorResponse(error: ApiErrorBody.fromJson(errorValue));
  }

  final ApiErrorBody error;

  @override
  List<Object?> get props => <Object?>[error];
}
