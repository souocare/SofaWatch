import 'package:dio/dio.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/statistics/data/models/weekly_statistics_dto.dart';
import 'package:sofawatch/features/statistics/domain/models/weekly_statistics.dart';
import 'package:sofawatch/features/statistics/domain/repositories/statistics_repository.dart';
import 'package:sofawatch/features/statistics/data/models/statistics_summary_dto.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_summary.dart';
import 'package:sofawatch/features/statistics/data/models/statistics_activity_dto.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity.dart';

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

  @override
  Future<StatisticsSummary> getSummary() async {
    try {
      final Response<Map<String, dynamic>> response = await _apiClient
          .get<Map<String, dynamic>>('/statistics/summary');

      final Map<String, dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException(
          'The statistics summary response body is missing.',
        );
      }

      return StatisticsSummaryDto.fromJson(data).toDomain();
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }

  @override
  Future<StatisticsActivity> getActivity({required int days}) async {
    try {
      final Response<Map<String, dynamic>> response = await _apiClient
          .get<Map<String, dynamic>>(
            '/statistics/activity',
            queryParameters: <String, dynamic>{'days': days},
          );

      final Map<String, dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException(
          'The statistics activity response body is missing.',
        );
      }

      return StatisticsActivityDto.fromJson(data).toDomain();
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }
}
