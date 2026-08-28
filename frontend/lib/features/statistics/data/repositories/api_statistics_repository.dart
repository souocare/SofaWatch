import 'package:dio/dio.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/statistics/data/models/statistics_activity_dto.dart';
import 'package:sofawatch/features/statistics/data/models/statistics_backlog_dto.dart';
import 'package:sofawatch/features/statistics/data/models/statistics_content_insights_dto.dart';
import 'package:sofawatch/features/statistics/data/models/statistics_habits_dto.dart';
import 'package:sofawatch/features/statistics/data/models/statistics_library_dto.dart';
import 'package:sofawatch/features/statistics/data/models/statistics_summary_dto.dart';
import 'package:sofawatch/features/statistics/data/models/weekly_statistics_dto.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_activity_period.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_backlog.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_content_insights.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_habits.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_library.dart';
import 'package:sofawatch/features/statistics/domain/models/statistics_summary.dart';
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
  Future<StatisticsActivity> getActivity({
    required StatisticsActivityPeriod period,
  }) async {
    try {
      final Response<Map<String, dynamic>> response = await _apiClient
          .get<Map<String, dynamic>>(
            '/statistics/activity',
            queryParameters: <String, dynamic>{'range': period.apiValue},
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

  @override
  Future<StatisticsHabits> getHabits() async {
    try {
      final Response<Map<String, dynamic>> response = await _apiClient
          .get<Map<String, dynamic>>('/statistics/habits');

      final Map<String, dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException(
          'The statistics habits response body is missing.',
        );
      }

      return StatisticsHabitsDto.fromJson(data).toDomain();
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }

  @override
  Future<StatisticsContentInsights> getContentInsights() async {
    try {
      final Response<Map<String, dynamic>> response = await _apiClient
          .get<Map<String, dynamic>>('/statistics/content-insights');

      final Map<String, dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException(
          'The statistics Content Insights response body is missing.',
        );
      }

      return StatisticsContentInsightsDto.fromJson(data).toDomain();
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }

  @override
  Future<StatisticsLibrary> getLibraryStatistics() async {
    try {
      final Response<Map<String, dynamic>> response = await _apiClient
          .get<Map<String, dynamic>>('/statistics/library');

      final Map<String, dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException(
          'The statistics Library response body is missing.',
        );
      }

      return StatisticsLibraryDto.fromJson(data).toDomain();
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }

  @override
  Future<StatisticsBacklog> getBacklogStatistics() async {
    try {
      final Response<Map<String, dynamic>> response = await _apiClient
          .get<Map<String, dynamic>>('/statistics/backlog');

      final Map<String, dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException(
          'The statistics Backlog response body is missing.',
        );
      }

      return StatisticsBacklogDto.fromJson(data).toDomain();
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }
}
