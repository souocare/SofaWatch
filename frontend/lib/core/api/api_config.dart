abstract final class ApiConfig {
  static const String apiPrefix = '/api/v1';

  static const Duration connectTimeout = Duration(seconds: 10);

  static const Duration sendTimeout = Duration(seconds: 15);

  static const Duration receiveTimeout = Duration(seconds: 30);

  static const Map<String, String> defaultHeaders = <String, String>{
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };
}
