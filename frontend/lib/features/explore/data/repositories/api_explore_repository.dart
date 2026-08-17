import 'package:dio/dio.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/explore/data/models/explore_genre_options_dto.dart';
import 'package:sofawatch/features/explore/data/models/explore_media_collection_dto.dart';
import 'package:sofawatch/features/explore/data/models/explore_trending_dto.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_genre_options.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_media_collection.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_trending.dart';
import 'package:sofawatch/features/explore/domain/entities/explore_trending_window.dart';
import 'package:sofawatch/features/explore/domain/repositories/explore_repository.dart';

final class ApiExploreRepository implements ExploreRepository {
  const ApiExploreRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<ExploreTrending> getTrending({
    required ExploreTrendingWindow window,
    String? language,
  }) async {
    try {
      final Response<Map<String, dynamic>> response = await _apiClient
          .get<Map<String, dynamic>>(
            '/explore/trending',
            queryParameters: <String, dynamic>{
              'window': window.name,
              'language': ?language,
            },
          );

      final Map<String, dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException(
          'The Explore trending response body is missing.',
        );
      }

      return ExploreTrendingDto.fromJson(data).toDomain();
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }

  @override
  Future<ExploreGenreOptions> getGenres({String? language}) async {
    try {
      final Response<Map<String, dynamic>> response = await _apiClient
          .get<Map<String, dynamic>>(
            '/explore/genres',
            queryParameters: <String, dynamic>{'language': ?language},
          );

      final Map<String, dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException(
          'The Explore genres response body is missing.',
        );
      }

      return ExploreGenreOptionsDto.fromJson(data).toDomain();
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    } catch (error) {
      throw AppException.unknown(originalError: error);
    }
  }

  @override
  Future<ExploreMediaCollection> getPopularShows({
    int? genreId,
    String? language,
  }) async {
    try {
      final Response<dynamic> response = await _apiClient.get(
        '/explore/popular/shows',
        queryParameters: <String, dynamic>{
          'genre_id': ?genreId,
          'language': ?language,
        },
      );

      final dynamic data = response.data;

      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid popular Shows response.');
      }

      return ExploreMediaCollectionDto.fromJson(data).toDomain();
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } catch (error) {
      throw AppException.unknown(originalError: error);
    }
  }

  @override
  Future<ExploreMediaCollection> getPopularMovies({
    int? genreId,
    String? language,
  }) async {
    try {
      final Response<dynamic> response = await _apiClient.get(
        '/explore/popular/movies',
        queryParameters: <String, dynamic>{
          'genre_id': ?genreId,
          'language': ?language,
        },
      );

      final dynamic data = response.data;

      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid popular Movies response.');
      }

      return ExploreMediaCollectionDto.fromJson(data).toDomain();
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } catch (error) {
      throw AppException.unknown(originalError: error);
    }
  }
}
