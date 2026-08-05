import 'package:equatable/equatable.dart';
import 'package:sofawatch/features/search/domain/models/search_media_type_filter.dart';

class SearchQuery extends Equatable {
  const SearchQuery({
    required this.term,
    this.page = 1,
    this.language,
    this.mediaType = SearchMediaTypeFilter.all,
  });

  final String term;
  final int page;
  final String? language;
  final SearchMediaTypeFilter mediaType;

  String get normalizedTerm {
    return term.trim();
  }

  bool get isEmpty {
    return normalizedTerm.isEmpty;
  }

  bool get isNotEmpty {
    return !isEmpty;
  }

  SearchQuery copyWith({
    String? term,
    int? page,
    String? language,
    bool clearLanguage = false,
    SearchMediaTypeFilter? mediaType,
  }) {
    return SearchQuery(
      term: term ?? this.term,
      page: page ?? this.page,
      language: clearLanguage ? null : language ?? this.language,
      mediaType: mediaType ?? this.mediaType,
    );
  }

  SearchQuery firstPage() {
    return copyWith(page: 1);
  }

  SearchQuery nextPage() {
    return copyWith(page: page + 1);
  }

  Map<String, dynamic> toQueryParameters() {
    return <String, dynamic>{
      'query': normalizedTerm,
      'page': page,
      'media_type': mediaType.apiValue,
      if (language?.trim().isNotEmpty == true) 'language': language!.trim(),
    };
  }

  @override
  List<Object?> get props => <Object?>[term, page, language, mediaType];
}
