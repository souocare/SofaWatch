import 'package:dio/dio.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/show_details/data/models/show_details_dto.dart';
import 'package:sofawatch/features/show_details/domain/models/show_details.dart';
import 'package:sofawatch/features/show_details/domain/repositories/show_details_repository.dart';

final class ApiShowDetailsRepository implements ShowDetailsRepository {
  const ApiShowDetailsRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<ShowDetails> getByTmdbId(int tmdbId, {String? language}) async {
    try {
      final Response<Map<String, dynamic>> response = await _apiClient
          .get<Map<String, dynamic>>(
            '/shows/tmdb/$tmdbId',
            queryParameters: language == null
                ? null
                : <String, dynamic>{'language': language},
          );

      final Map<String, dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException(
          'The show details response body is missing.',
        );
      }

      return ShowDetailsDto.fromJson(data).toDomain();
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }
}
