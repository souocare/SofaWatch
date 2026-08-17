import 'package:dio/dio.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/movies/data/models/library_movie_dto.dart';
import 'package:sofawatch/features/movies/domain/models/library_movie.dart';
import 'package:sofawatch/features/movies/domain/repositories/movies_repository.dart';

final class ApiMoviesRepository implements MoviesRepository {
  const ApiMoviesRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<LibraryMovie>> getLibraryMovies() async {
    try {
      final Response<List<dynamic>> response = await _apiClient
          .get<List<dynamic>>('/library/movies');

      final List<dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException(
          'The library movies response body is missing.',
        );
      }

      return data
          .map((dynamic item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException(
                'Invalid library movie response item.',
              );
            }

            return LibraryMovieDto.fromJson(item).toDomain();
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
