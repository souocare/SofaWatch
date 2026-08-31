enum HistoryMediaType {
  all,
  episodes,
  movies;

  String? get apiValue {
    return switch (this) {
      HistoryMediaType.all => null,
      HistoryMediaType.episodes => 'episode',
      HistoryMediaType.movies => 'movie',
    };
  }
}
