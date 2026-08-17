import 'package:dio/dio.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/statistics/data/models/weekly_statistics_dto.dart';
import 'package:sofawatch/features/statistics/domain/models/weekly_statistics.dart';
import 'package:sofawatch/features/statistics/domain/repositories/statistics_repository.dart';

final class ApiStatisticsRepository implements StatisticsRepository {
  const ApiStatisticsRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<WeeklyStatistics> getWeeklyStatistics() async {
    try {
      final Response<Map<String, dynamic>> response = await _apiClient
          .get<Map<String, dynamic>>('/statistics/weekly');

      final Map<String, dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException(
          'The weekly statistics response body is missing.',
        );
      }

      return WeeklyStatisticsDto.fromJson(data).toDomain();
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }
}
