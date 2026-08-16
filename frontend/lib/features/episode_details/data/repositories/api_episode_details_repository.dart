import 'package:dio/dio.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/episode_details/data/models/episode_details_dto.dart';
import 'package:sofawatch/features/episode_details/domain/models/episode_details.dart';
import 'package:sofawatch/features/episode_details/domain/repositories/episode_details_repository.dart';

final class ApiEpisodeDetailsRepository implements EpisodeDetailsRepository {
  const ApiEpisodeDetailsRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<EpisodeDetails> getById(String episodeId) async {
    try {
      final Response<Map<String, dynamic>> response = await _apiClient
          .get<Map<String, dynamic>>('/episodes/$episodeId/details');

      final Map<String, dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException(
          'The Episode Details response body is missing.',
        );
      }

      return EpisodeDetailsDto.fromJson(data).toDomain();
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }
}
