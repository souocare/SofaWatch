import 'package:equatable/equatable.dart';
import 'package:sofawatch/features/search/domain/models/search_media_type_filter.dart';

sealed class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

final class SearchQueryChanged extends SearchEvent {
  const SearchQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => <Object?>[query];
}

final class SearchMediaTypeChanged extends SearchEvent {
  const SearchMediaTypeChanged(this.mediaType);

  final SearchMediaTypeFilter mediaType;

  @override
  List<Object?> get props => <Object?>[mediaType];
}

final class SearchSubmitted extends SearchEvent {
  const SearchSubmitted();
}

final class SearchNextPageRequested extends SearchEvent {
  const SearchNextPageRequested();
}

final class SearchRetryRequested extends SearchEvent {
  const SearchRetryRequested();
}

final class SearchCleared extends SearchEvent {
  const SearchCleared();
}
