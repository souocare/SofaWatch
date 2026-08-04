import 'package:dio/dio.dart';
import 'package:sofawatch/core/api/api_config.dart';
import 'package:sofawatch/core/api/api_exception_mapper.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/server_setup/domain/services/server_connection_tester.dart';

class ApiServerConnectionTester implements ServerConnectionTester {
  ApiServerConnectionTester({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: ApiConfig.connectTimeout,
              sendTimeout: ApiConfig.sendTimeout,
              receiveTimeout: ApiConfig.receiveTimeout,
              headers: ApiConfig.defaultHeaders,
            ),
          );

  final Dio _dio;

  @override
  Future<void> testConnection(Uri serverUrl) async {
    final Uri healthUri = _buildHealthUri(serverUrl);

    try {
      final Response<dynamic> response = await _dio.getUri<dynamic>(healthUri);

      _validateHealthResponse(response);
    } on DioException catch (exception) {
      throw ApiExceptionMapper.map(exception);
    }
  }

  static void _validateHealthResponse(Response<dynamic> response) {
    final Object? data = response.data;

    if (data is! Map<String, dynamic>) {
      throw const AppException.invalidData(
        message: 'The server returned an invalid health response.',
      );
    }

    final Object? status = data['status'];

    if (status is! String) {
      throw const AppException.invalidData(
        message: 'The server health response does not contain a valid status.',
      );
    }

    if (status != 'healthy') {
      throw AppException(
        type: AppExceptionType.server,
        code: 'server_unhealthy',
        message: 'The SofaWatch server is not healthy.',
        statusCode: response.statusCode,
        details: <String, dynamic>{'healthStatus': status},
      );
    }
  }

  static Uri _buildHealthUri(Uri serverUrl) {
    final String normalizedServerUrl = serverUrl.toString().replaceFirst(
      RegExp(r'/+$'),
      '',
    );

    return Uri.parse('$normalizedServerUrl${ApiConfig.apiPrefix}/health');
  }
}
