import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/movies/domain/repositories/movie_viewing_repository.dart';

final class ApiMovieViewingRepository implements MovieViewingRepository {
  const ApiMovieViewingRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<void> recordWatch(String movieId) async {
    try {
      await _apiClient.post<dynamic>('/library/movies/$movieId/watch-events');
    } on AppException {
      rethrow;
    } on Object catch (error) {
      throw AppException.unknown(originalError: error);
    }
  }

  @override
  Future<void> deleteWatchEvent({
    required String movieId,
    required String eventId,
  }) async {
    try {
      await _apiClient.delete<dynamic>(
        '/library/movies/$movieId/watch-events/$eventId',
      );
    } on AppException {
      rethrow;
    } on Object catch (error) {
      throw AppException.unknown(originalError: error);
    }
  }
}
