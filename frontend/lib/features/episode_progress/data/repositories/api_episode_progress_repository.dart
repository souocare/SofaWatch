import 'package:dio/dio.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/episode_progress/domain/repositories/episode_progress_repository.dart';

final class ApiEpisodeProgressRepository implements EpisodeProgressRepository {
  const ApiEpisodeProgressRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<void> markEpisodeWatched({
    required String episodeId,
    DateTime? watchedAt,
  }) async {
    try {
      await _apiClient.post<dynamic>(
        '/episodes/$episodeId/watched',
        data: <String, dynamic>{
          'watched_at': watchedAt?.toUtc().toIso8601String(),
        },
      );
    } on AppException {
      rethrow;
    } on DioException catch (error) {
      throw AppException.unknown(originalError: error);
    } on Object catch (error) {
      throw AppException.unknown(originalError: error);
    }
  }

  @override
  Future<void> markEpisodeUnwatched({required String episodeId}) async {
    try {
      await _apiClient.delete<dynamic>('/episodes/$episodeId/watched');
    } on AppException {
      rethrow;
    } on DioException catch (error) {
      throw AppException.unknown(originalError: error);
    } on Object catch (error) {
      throw AppException.unknown(originalError: error);
    }
  }
}
