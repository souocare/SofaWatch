import 'package:sofawatch/features/search/data/models/search_result_dto.dart';
import 'package:sofawatch/features/search/domain/entities/search_result.dart';
import 'package:sofawatch/features/search/domain/models/search_result_page.dart';

class SearchResponseDto {
  const SearchResponseDto({
    required this.page,
    required this.results,
    required this.totalPages,
    required this.totalResults,
  });

  factory SearchResponseDto.fromJson(Map<String, dynamic> json) {
    final Object? rawResults = json['results'];

    if (rawResults is! List<dynamic>) {
      throw const FormatException('Invalid search response results.');
    }

    return SearchResponseDto(
      page: _readPositiveInt(json, 'page'),
      results: rawResults
          .map((Object? item) {
            if (item is! Map<String, dynamic>) {
              throw const FormatException('Invalid search response result.');
            }

            return SearchResultDto.fromJson(item);
          })
          .toList(growable: false),
      totalPages: _readNonNegativeInt(json, 'total_pages'),
      totalResults: _readNonNegativeInt(json, 'total_results'),
    );
  }

  final int page;
  final List<SearchResultDto> results;

  final int totalPages;
  final int totalResults;

  SearchResultPage toDomain() {
    return SearchResultPage(
      page: page,
      results: List<SearchResult>.unmodifiable(
        results.map((SearchResultDto result) {
          return result.toDomain();
        }),
      ),
      totalPages: totalPages,
      totalResults: totalResults,
    );
  }

  static int _readPositiveInt(Map<String, dynamic> json, String key) {
    final Object? value = json[key];

    if (value is int && value > 0) {
      return value;
    }

    throw FormatException('Invalid positive integer for "$key".');
  }

  static int _readNonNegativeInt(Map<String, dynamic> json, String key) {
    final Object? value = json[key];

    if (value is int && value >= 0) {
      return value;
    }

    throw FormatException('Invalid non-negative integer for "$key".');
  }
}
