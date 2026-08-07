import 'package:sofawatch/features/movie_details/domain/models/movie_details.dart';

abstract interface class MovieDetailsRepository {
  Future<MovieDetails> getByTmdbId(int tmdbId, {String? language});
}
