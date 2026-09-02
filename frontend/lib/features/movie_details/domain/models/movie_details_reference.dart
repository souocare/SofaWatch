sealed class MovieDetailsReference {
  const MovieDetailsReference();
}

final class LocalMovieDetailsReference extends MovieDetailsReference {
  const LocalMovieDetailsReference(this.movieId);

  final String movieId;
}

final class TmdbMovieDetailsReference extends MovieDetailsReference {
  const TmdbMovieDetailsReference(this.tmdbId);

  final int tmdbId;
}
