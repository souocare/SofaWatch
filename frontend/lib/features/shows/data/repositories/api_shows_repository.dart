import 'package:dio/dio.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/shows/data/models/library_show_dto.dart';
import 'package:sofawatch/features/shows/domain/models/library_show.dart';
import 'package:sofawatch/features/shows/domain/repositories/shows_repository.dart';
import 'package:sofawatch/features/shows/data/models/watch_next_show_dto.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_show.dart';
import 'package:sofawatch/features/shows/data/models/stale_watching_show_dto.dart';
import 'package:sofawatch/features/shows/domain/models/stale_watching_show.dart';
import 'package:sofawatch/features/shows/data/models/watch_history_page_dto.dart';
import 'package:sofawatch/features/shows/domain/models/watch_history_page.dart';
import 'package:sofawatch/features/shows/data/models/upcoming_item_dto.dart';
import 'package:sofawatch/features/shows/domain/models/upcoming_item.dart';

final class ApiShowsRepository implements ShowsRepository {
  const ApiShowsRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<LibraryShow>> getLibraryShows() async {
    try {
      final Response<List<dynamic>> response = await _apiClient
          .get<List<dynamic>>('/library/shows');

      final List<dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException(
          'The library shows response body is missing.',
        );
      }

      return data
          .map((dynamic item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException(
                'Invalid library show response item.',
              );
            }

            return LibraryShowDto.fromJson(item).toDomain();
          })
          .toList(growable: false);
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }

  @override
  Future<List<WatchNextShow>> getWatchNext() async {
    try {
      final Response<List<dynamic>> response = await _apiClient
          .get<List<dynamic>>('/library/shows/watch-next');

      final List<dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException('The Watch Next response body is missing.');
      }

      return data
          .map((dynamic item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('Invalid Watch Next response item.');
            }

            return WatchNextShowDto.fromJson(item).toDomain();
          })
          .toList(growable: false);
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }

  @override
  Future<List<UpcomingItem>> getUpcoming({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = <String, dynamic>{
        if (fromDate != null) 'from_date': _formatDate(fromDate),
        if (toDate != null) 'to_date': _formatDate(toDate),
      };

      final Response<List<dynamic>> response = await _apiClient
          .get<List<dynamic>>(
            '/library/shows/upcoming',
            queryParameters: queryParameters,
          );

      final List<dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException('The Upcoming response body is missing.');
      }

      return data
          .map((dynamic item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('Invalid Upcoming response item.');
            }

            return UpcomingItemDto.fromJson(item).toDomain();
          })
          .toList(growable: false);
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }

  @override
  Future<List<StaleWatchingShow>> getStaleWatching() async {
    try {
      final Response<List<dynamic>> response = await _apiClient
          .get<List<dynamic>>('/library/shows/stale-watching');

      final List<dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException(
          'The stale Watching response body is missing.',
        );
      }

      return data
          .map((dynamic item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException(
                'Invalid stale Watching response item.',
              );
            }

            return StaleWatchingShowDto.fromJson(item).toDomain();
          })
          .toList(growable: false);
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }

  @override
  Future<WatchHistoryPage> getWatchHistory({
    int limit = 30,
    String? cursor,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = <String, dynamic>{
        'limit': limit,
        'cursor': ?cursor,
      };

      final Response<Map<String, dynamic>> response = await _apiClient
          .get<Map<String, dynamic>>(
            '/library/shows/watch-history',
            queryParameters: queryParameters,
          );

      final Map<String, dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException(
          'The Watch History response body is missing.',
        );
      }

      return WatchHistoryPageDto.fromJson(data).toDomain();
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }

  @override
  Future<void> markEpisodeWatched({required String episodeId}) async {
    await _apiClient.post<dynamic>(
      '/episodes/$episodeId/watched',
      data: <String, dynamic>{'watched_at': null},
    );
  }

  @override
  Future<void> startShow({required String showId}) async {
    await _apiClient.post<dynamic>('/library/shows/$showId/start');
  }

  @override
  Future<void> markEpisodeUnwatched({required String episodeId}) async {
    await _apiClient.delete<dynamic>('/episodes/$episodeId/watched');
  }
}

String _formatDate(DateTime value) {
  final DateTime date = value.toLocal();

  final String year = date.year.toString().padLeft(4, '0');
  final String month = date.month.toString().padLeft(2, '0');
  final String day = date.day.toString().padLeft(2, '0');

  return '$year-$month-$day';
}
