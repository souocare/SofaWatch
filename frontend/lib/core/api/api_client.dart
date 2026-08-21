import 'package:dio/dio.dart';
import 'package:sofawatch/core/api/api_config.dart';
import 'package:sofawatch/core/api/api_exception_mapper.dart';
import 'package:sofawatch/core/api/api_logging_interceptor.dart';

class ApiClient {
  ApiClient({Uri? baseUrl, Dio? dio}) : _dio = dio ?? Dio() {
    if (baseUrl != null) {
      configureBaseUrl(baseUrl);
    }

    _dio.options.connectTimeout = ApiConfig.connectTimeout;
    _dio.options.sendTimeout = ApiConfig.sendTimeout;
    _dio.options.receiveTimeout = ApiConfig.receiveTimeout;

    _dio.options.headers.addAll(ApiConfig.defaultHeaders);

    _dio.interceptors.add(const ApiLoggingInterceptor());
  }

  final Dio _dio;

  Dio get dio {
    return _dio;
  }

  String get baseUrl {
    return _dio.options.baseUrl;
  }

  Uri? get serverUri {
    if (!isConfigured) {
      return null;
    }

    final Uri apiUri = Uri.parse(baseUrl);

    final String apiPrefix = ApiConfig.apiPrefix;

    String path = apiUri.path;

    if (path.endsWith(apiPrefix)) {
      path = path.substring(0, path.length - apiPrefix.length);
    }

    return apiUri.replace(
      path: path.isEmpty ? '/' : path,
      query: null,
      fragment: null,
    );
  }

  String? resolveServerUrl(String? value) {
    final String? normalizedValue = value?.trim();

    if (normalizedValue == null || normalizedValue.isEmpty) {
      return null;
    }

    final Uri uri = Uri.parse(normalizedValue);

    if (uri.hasScheme) {
      return uri.toString();
    }

    _ensureConfigured();

    final String normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl
        : '$baseUrl/';

    return Uri.parse(normalizedBaseUrl).resolve(normalizedValue).toString();
  }

  bool get isConfigured {
    return _dio.options.baseUrl.isNotEmpty;
  }

  void configureBaseUrl(Uri baseUrl) {
    _dio.options.baseUrl = _buildApiBaseUrl(baseUrl);
  }

  void clearBaseUrl() {
    _dio.options.baseUrl = '';
  }

  void setHeader(String name, String value) {
    _dio.options.headers[name] = value;
  }

  void removeHeader(String name) {
    _dio.options.headers.remove(name);
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _executeRequest<T>(
      () => _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _executeRequest<T>(
      () => _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _executeRequest<T>(
      () => _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _executeRequest<T>(
      () => _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _executeRequest<T>(
      () => _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<Response<T>> _executeRequest<T>(
    Future<Response<T>> Function() request,
  ) async {
    _ensureConfigured();

    try {
      return await request();
    } on DioException catch (exception) {
      throw ApiExceptionMapper.map(exception);
    }
  }

  void _ensureConfigured() {
    if (!isConfigured) {
      throw StateError('ApiClient does not have a configured server URL.');
    }
  }

  static String _buildApiBaseUrl(Uri serverUrl) {
    final String normalizedUrl = serverUrl.toString().replaceFirst(
      RegExp(r'/+$'),
      '',
    );

    return '$normalizedUrl${ApiConfig.apiPrefix}';
  }
}
