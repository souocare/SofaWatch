import 'package:dio/dio.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/movie_details/data/models/movie_details_dto.dart';
import 'package:sofawatch/features/movie_details/domain/models/movie_details.dart';
import 'package:sofawatch/features/movie_details/domain/repositories/movie_details_repository.dart';

final class ApiMovieDetailsRepository implements MovieDetailsRepository {
  const ApiMovieDetailsRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<MovieDetails> getById(String movieId) {
    return _getDetails('/movies/$movieId');
  }

  @override
  Future<MovieDetails> getByTmdbId(int tmdbId, {String? language}) {
    return _getDetails(
      '/movies/tmdb/$tmdbId',
      queryParameters: language == null
          ? null
          : <String, dynamic>{'language': language},
    );
  }

  Future<MovieDetails> _getDetails(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final Response<Map<String, dynamic>> response = await _apiClient
          .get<Map<String, dynamic>>(path, queryParameters: queryParameters);

      final Map<String, dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException(
          'The movie details response body is missing.',
        );
      }

      return MovieDetailsDto.fromJson(data).toDomain();
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }
}
