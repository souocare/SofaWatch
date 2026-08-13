import 'package:dio/dio.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/shows/data/models/library_show_dto.dart';
import 'package:sofawatch/features/shows/domain/models/library_show.dart';
import 'package:sofawatch/features/shows/domain/repositories/shows_repository.dart';
import 'package:sofawatch/features/shows/data/models/watch_next_show_dto.dart';
import 'package:sofawatch/features/shows/domain/models/watch_next_show.dart';

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
}
