import 'package:dio/dio.dart';
import 'package:sofawatch/core/api/api_client.dart';
import 'package:sofawatch/core/errors/app_exception.dart';
import 'package:sofawatch/features/search/data/models/search_response_dto.dart';
import 'package:sofawatch/features/search/domain/models/search_query.dart';
import 'package:sofawatch/features/search/domain/models/search_result_page.dart';
import 'package:sofawatch/features/search/domain/repositories/search_repository.dart';

final class ApiSearchRepository implements SearchRepository {
  const ApiSearchRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<SearchResultPage> search(SearchQuery query) async {
    try {
      final Response<Map<String, dynamic>> response = await _apiClient
          .get<Map<String, dynamic>>(
            '/search',
            queryParameters: query.toQueryParameters(),
          );

      final Map<String, dynamic>? data = response.data;

      if (data == null) {
        throw const FormatException('The search response body is missing.');
      }

      return SearchResponseDto.fromJson(data).toDomain();
    } on AppException {
      rethrow;
    } on FormatException catch (error) {
      throw AppException.invalidData(originalError: error);
    } on TypeError catch (error) {
      throw AppException.invalidData(originalError: error);
    }
  }
}
