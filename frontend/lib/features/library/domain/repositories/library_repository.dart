import 'package:sofawatch/features/library/domain/models/imported_library_media.dart';
import 'package:sofawatch/features/library/domain/models/library_entry.dart';

abstract interface class LibraryRepository {
  Future<ImportedLibraryMedia> importShowByTmdbId(int tmdbId);

  Future<ImportedLibraryMedia> importMovieByTmdbId(int tmdbId);

  Future<LibraryEntry> addShow(String showId);

  Future<LibraryEntry> addMovie(String movieId);
}
