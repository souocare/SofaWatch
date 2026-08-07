import 'package:sofawatch/features/show_details/domain/models/show_details.dart';

abstract interface class ShowDetailsRepository {
  Future<ShowDetails> getByTmdbId(int tmdbId, {String? language});
}
