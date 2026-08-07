import 'package:equatable/equatable.dart';
import 'package:sofawatch/features/search/domain/models/search_media_type_filter.dart';
import 'package:sofawatch/features/search/domain/models/search_query.dart';

final class SearchCacheKey extends Equatable {
  const SearchCacheKey({
    required this.term,
    required this.page,
    required this.mediaType,
    required this.language,
  });

  factory SearchCacheKey.fromQuery(SearchQuery query) {
    return SearchCacheKey(
      term: query.normalizedTerm.toLowerCase(),
      page: query.page,
      mediaType: query.mediaType,
      language: _normalizeLanguage(query.language),
    );
  }

  final String term;
  final int page;
  final SearchMediaTypeFilter mediaType;
  final String? language;

  static String? _normalizeLanguage(String? language) {
    final String? normalizedLanguage = language?.trim().toLowerCase();

    if (normalizedLanguage == null || normalizedLanguage.isEmpty) {
      return null;
    }

    return normalizedLanguage;
  }

  @override
  List<Object?> get props => <Object?>[term, page, mediaType, language];
}
