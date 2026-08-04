import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiLoggingInterceptor extends Interceptor {
  const ApiLoggingInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log('${options.method} ${options.uri}');

    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _log(
      '${response.statusCode} '
      '${response.requestOptions.method} '
      '${response.requestOptions.uri}',
    );

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      developer.log(
        '${err.type.name} '
        '${err.requestOptions.method} '
        '${err.requestOptions.uri}',
        name: 'SofaWatch.API',
        error: err.error ?? err.message,
        stackTrace: err.stackTrace,
        level: 1000,
      );
    }

    handler.next(err);
  }

  void _log(String message) {
    if (!kDebugMode) {
      return;
    }

    developer.log(message, name: 'SofaWatch.API');
  }
}
