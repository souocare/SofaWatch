import 'package:sofawatch/features/library/domain/models/imported_library_media.dart';
import 'package:sofawatch/features/library/domain/models/library_entry.dart';
import 'package:sofawatch/features/library/domain/models/library_status.dart';

abstract interface class LibraryRepository {
  Future<ImportedLibraryMedia> importShowByTmdbId(int tmdbId);

  Future<ImportedLibraryMedia> importMovieByTmdbId(int tmdbId);

  Future<LibraryEntry?> getShowEntry(String showId);

  Future<LibraryEntry?> getMovieEntry(String movieId);

  Future<LibraryEntry> addShow(String showId);

  Future<LibraryEntry> addMovie(String movieId);

  Future<void> removeShow(String showId);

  Future<void> removeMovie(String movieId);

  Future<LibraryEntry> updateShowStatus(String showId, LibraryStatus status);

  Future<LibraryEntry> updateMovieStatus(String movieId, LibraryStatus status);
}
