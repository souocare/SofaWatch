import 'package:sofawatch/features/movies/domain/models/library_movie.dart';

abstract interface class MoviesRepository {
  Future<List<LibraryMovie>> getLibraryMovies();
}
