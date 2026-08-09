import 'package:sofawatch/features/explore/domain/entities/explore_trending.dart';

abstract interface class ExploreRepository {
  Future<ExploreTrending> getTrending({String? language});
}
