import 'package:sofawatch/features/movie_details/domain/models/movie_details.dart';

abstract interface class MovieDetailsRepository {
  Future<MovieDetails> getById(String movieId);

  Future<MovieDetails> getByTmdbId(int tmdbId, {String? language});
}
