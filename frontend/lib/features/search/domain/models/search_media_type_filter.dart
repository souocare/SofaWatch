enum SearchMediaTypeFilter {
  all,
  show,
  movie;

  String get apiValue {
    return switch (this) {
      SearchMediaTypeFilter.all => 'all',
      SearchMediaTypeFilter.show => 'show',
      SearchMediaTypeFilter.movie => 'movie',
    };
  }
}
