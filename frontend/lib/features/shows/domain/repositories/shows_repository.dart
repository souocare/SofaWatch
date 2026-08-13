import 'package:sofawatch/features/shows/domain/models/library_show.dart';

abstract interface class ShowsRepository {
  Future<List<LibraryShow>> getLibraryShows();
}
