import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

void configureWebHttpClientAdapter(Dio dio) {
  dio.httpClientAdapter = BrowserHttpClientAdapter(withCredentials: true);
}
